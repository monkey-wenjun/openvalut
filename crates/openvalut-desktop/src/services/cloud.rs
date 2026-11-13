//! OpenValut Cloud access, ported from `openvalut-cli/src/cloud.rs` so the
//! desktop client and the CLI speak byte-identical protocol: login with email
//! and Secret Key, then row-level entry sync (source of truth) with the legacy
//! encrypted blob as fallback.
//!
//! The row key is Argon2id (64 MiB / 3 / 4) derived from the master password
//! and the vault id; payloads are AES-256-GCM encrypted.
use std::time::{SystemTime, UNIX_EPOCH};

use aes_gcm::aead::Aead;
use aes_gcm::{Aes256Gcm, KeyInit, Nonce};
use argon2::{Algorithm, Argon2, Params, Version};
use data_encoding::{BASE64, BASE64URL_NOPAD};
use openvalut_core::{secure_random_bytes, sign_request};
use rand::RngCore;
use rsa::rand_core::UnwrapErr;
use rsa::traits::PublicKeyParts;
use rsa::{PrivateKey, PublicKey};
use serde::Deserialize;
use serde_json::Value;

/// Upserted `(uuid, updated_at)` pairs plus the uuids the server rejected as
/// stale by its optimistic lock.
pub type SyncEntriesResult = (Vec<(String, i64)>, Vec<String>);
use rsa::sha2::Sha256;
use std::fmt;

const ARGON_MEMORY_KIB: u32 = 64 * 1024;
const ARGON_ITERATIONS: u32 = 3;
const ARGON_PARALLELISM: u32 = 4;

/// HTTP-level failure with the server status preserved so callers can map
/// 401/409 to the same user-facing strings as the Flutter app.
#[derive(Debug)]
pub struct CloudError {
    pub status: Option<u16>,
    pub message: String,
}

impl CloudError {
    fn net(message: String) -> Self {
        CloudError {
            status: None,
            message,
        }
    }
}

impl fmt::Display for CloudError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.message)
    }
}

impl From<CloudError> for String {
    fn from(e: CloudError) -> String {
        e.message
    }
}

/// Flutter `normalizeServerUrl`: trim, add `https://` when no scheme, drop one
/// trailing slash. Empty input falls back to `default`.
pub fn normalize_server(raw: &str, default: &str) -> String {
    let trimmed = raw.trim();
    if trimmed.is_empty() {
        return default.trim_end_matches('/').to_string();
    }
    let with_scheme = if trimmed.starts_with("http://") || trimmed.starts_with("https://") {
        trimmed.to_string()
    } else {
        format!("https://{trimmed}")
    };
    let base = with_scheme.trim_end();
    let base = base.strip_suffix('/').unwrap_or(base);
    base.to_string()
}

#[derive(Debug, Clone)]
pub struct CloudVault {
    pub id: String,
    pub name: String,
    pub nonce: Vec<u8>,
    pub ciphertext: Vec<u8>,
    pub updated_at: Option<i64>,
}

/// A row-level entry on the server. The payload (nonce+ciphertext) stays
/// encrypted; the group is stored as "base64(nonce).base64(ciphertext)".
#[derive(Debug, Clone)]
pub struct CloudRow {
    pub uuid: String,
    pub group: String,
    pub nonce: Vec<u8>,
    pub ciphertext: Vec<u8>,
    pub updated_at: i64,
}

/// A row to upsert via `entries/sync`.
#[derive(Debug, Clone)]
pub struct RowUpsert {
    pub uuid: String,
    pub group: String,
    pub nonce: Vec<u8>,
    pub ciphertext: Vec<u8>,
    pub base_updated_at: i64,
}

#[derive(Debug, Deserialize)]
struct VaultJson {
    id: String,
    name: String,
    nonce: String,
    ciphertext: String,
    #[serde(rename = "updatedAt")]
    updated_at: Option<i64>,
}

impl From<VaultJson> for CloudVault {
    fn from(v: VaultJson) -> Self {
        CloudVault {
            id: v.id,
            name: v.name,
            nonce: BASE64.decode(v.nonce.as_bytes()).unwrap_or_default(),
            ciphertext: BASE64.decode(v.ciphertext.as_bytes()).unwrap_or_default(),
            updated_at: v.updated_at,
        }
    }
}

#[derive(Clone)]
pub struct CloudClient {
    agent: ureq::Agent,
    base: String,
    token: String,
    user_id: String,
}

fn new_agent() -> ureq::Agent {
    ureq::Agent::config_builder()
        .http_status_as_error(false)
        .build()
        .new_agent()
}

impl CloudClient {
    /// Logs in with the account email and its Secret Key (the account UUID).
    pub fn login(base_url: &str, username: &str, secret_key: &str) -> Result<Self, String> {
        Self::try_login(base_url, username, secret_key).map_err(|e| e.message)
    }

    /// Like `login`, but keeps the HTTP status so callers can render the
    /// original app's 401 wording.
    pub fn try_login(base_url: &str, username: &str, secret_key: &str) -> Result<Self, CloudError> {
        let base = base_url.trim_end_matches('/');
        // The Secret Key is a 32-char lowercase hex UUID (no dashes). Accept
        // display formats with dashes/uppercase so it can be pasted as shown.
        let user_id = secret_key.trim().to_lowercase().replace('-', "");
        let body = serde_json::json!({
            "username": username.trim().to_lowercase(),
            "userId": user_id.clone(),
            "publicKey": "",
        });
        let agent = new_agent();
        let data = call_json_err(
            &agent,
            "POST",
            &format!("{base}/api/login"),
            "/api/login",
            None,
            Some(&user_id),
            Some(&body),
        )?;
        let token = data
            .get("token")
            .and_then(Value::as_str)
            .ok_or_else(|| CloudError {
                status: None,
                message: "login failed: no token in response".to_string(),
            })?
            .to_string();
        Ok(CloudClient {
            agent,
            base: base.to_string(),
            token,
            user_id,
        })
    }

    /// Registers a new account (POST /api/register). The server generates the
    /// account UUID, which doubles as the Secret Key. An empty `publicKey`
    /// matches the app default and the server stores it without validation.
    pub fn register(base_url: &str, username: &str) -> Result<(Self, String), CloudError> {
        let base = base_url.trim_end_matches('/');
        let body = serde_json::json!({
            "username": username.trim().to_lowercase(),
            "publicKey": "",
        });
        let agent = new_agent();
        let data = call_json_err(
            &agent,
            "POST",
            &format!("{base}/api/register"),
            "/api/register",
            None,
            None,
            Some(&body),
        )?;
        let token = data
            .get("token")
            .and_then(Value::as_str)
            .ok_or_else(|| CloudError {
                status: None,
                message: "注册失败：服务器未返回登录令牌".to_string(),
            })?
            .to_string();
        let user_id = data
            .get("user")
            .and_then(|u| u.get("id"))
            .and_then(Value::as_str)
            .ok_or_else(|| CloudError {
                status: None,
                message: "注册失败：未返回 Secret Key".to_string(),
            })?
            .to_string();
        Ok((
            CloudClient {
                agent,
                base: base.to_string(),
                token,
                user_id: user_id.clone(),
            },
            user_id,
        ))
    }

    /// Wraps a token obtained out-of-band (scan login) into a client.
    pub fn from_session(base: &str, token: String, user_id: String) -> Self {
        CloudClient {
            agent: new_agent(),
            base: base.trim_end_matches('/').to_string(),
            token,
            user_id,
        }
    }

    /// The account id (Secret Key) this client signs requests with.
    pub fn user_id(&self) -> &str {
        &self.user_id
    }

    /// Resolves the account id for a bare token (GET /api/me). Older servers
    /// did not include `userId` in the scan-confirm payload.
    pub fn fetch_user_id(base: &str, token: &str) -> Result<String, String> {
        let base = base.trim_end_matches('/');
        let resp = call_json(
            &new_agent(),
            "GET",
            &format!("{base}/api/me"),
            "/api/me",
            Some(token),
            None,
            None,
        )?;
        resp.get("user")
            .and_then(|u| u.get("id"))
            .and_then(Value::as_str)
            .map(str::to_string)
            .ok_or_else(|| "invalid /api/me response: missing user.id".to_string())
    }

    /// Creates the vault blob on the server (POST /api/vaults). `plain_name`
    /// is stored under the account meta key, matching `_encryptMeta`.
    pub fn create_vault(
        &self,
        id: &str,
        plain_name: &str,
        meta_key: &[u8; 32],
        nonce: &[u8],
        ciphertext: &[u8],
    ) -> Result<CloudVault, CloudError> {
        let body = serde_json::json!({
            "id": id,
            "name": encrypt_meta(meta_key, plain_name),
            "nonce": BASE64.encode(nonce),
            "ciphertext": BASE64.encode(ciphertext),
        });
        let resp = call_json_err(
            &self.agent,
            "POST",
            &format!("{}/api/vaults", self.base),
            "/api/vaults",
            Some(&self.token),
            Some(&self.user_id),
            Some(&body),
        )?;
        let vault = resp.get("vault").cloned().unwrap_or(resp.clone());
        serde_json::from_value::<VaultJson>(vault)
            .map(CloudVault::from)
            .map_err(|e| CloudError {
                status: None,
                message: format!("无效的云密码库响应: {e}"),
            })
    }

    /// Lists the account's vaults; when `meta_key` is given (the master
    /// password was supplied), `v1:` names written by the app are decrypted.
    pub fn list_vaults_with_key(
        &self,
        meta_key: Option<&[u8; 32]>,
    ) -> Result<Vec<CloudVault>, String> {
        let resp = call_json(
            &self.agent,
            "GET",
            &format!("{}/api/vaults", self.base),
            "/api/vaults",
            Some(&self.token),
            Some(&self.user_id),
            None,
        )?;
        let vaults = resp
            .get("vaults")
            .and_then(Value::as_array)
            .ok_or_else(|| "invalid response: missing vaults".to_string())?;
        Ok(vaults
            .iter()
            .filter_map(|v| serde_json::from_value::<VaultJson>(v.clone()).ok())
            .map(|v| {
                let mut vault = CloudVault::from(v);
                if let Some(key) = meta_key {
                    vault.name = decrypt_meta(key, &vault.name);
                }
                vault
            })
            .collect())
    }

    pub fn list_vaults(&self) -> Result<Vec<CloudVault>, String> {
        self.list_vaults_with_key(None)
    }

    pub fn get_vault(&self, id: &str) -> Result<CloudVault, String> {
        let path = format!("/api/vaults/{}", encode_path(id));
        let resp = call_json(
            &self.agent,
            "GET",
            &format!("{}{}", self.base, path),
            &path,
            Some(&self.token),
            Some(&self.user_id),
            None,
        )?;
        let vault = resp
            .get("vault")
            .ok_or_else(|| "invalid response: missing vault".to_string())?;
        serde_json::from_value::<VaultJson>(vault.clone())
            .map(CloudVault::from)
            .map_err(|e| format!("invalid vault: {e}"))
    }

    pub fn update_vault(
        &self,
        id: &str,
        name: &str,
        nonce: &[u8],
        ciphertext: &[u8],
        base_updated_at: i64,
    ) -> Result<(), String> {
        let body = serde_json::json!({
            "name": name,
            "nonce": BASE64.encode(nonce),
            "ciphertext": BASE64.encode(ciphertext),
            "base_updated_at": base_updated_at,
        });
        let path = format!("/api/vaults/{}", encode_path(id));
        call_json(
            &self.agent,
            "PUT",
            &format!("{}{}", self.base, path),
            &path,
            Some(&self.token),
            Some(&self.user_id),
            Some(&body),
        )?;
        Ok(())
    }

    /// Lists the row-level entries of a vault (uuid + version + encrypted payload).
    pub fn list_rows(&self, vault_id: &str) -> Result<Vec<CloudRow>, String> {
        let path = format!("/api/vaults/{}/entries", encode_path(vault_id));
        let resp = call_json(
            &self.agent,
            "GET",
            &format!("{}{}", self.base, path),
            &path,
            Some(&self.token),
            Some(&self.user_id),
            None,
        )?;
        let entries = resp
            .get("entries")
            .and_then(Value::as_array)
            .ok_or_else(|| "invalid response: missing entries".to_string())?;
        entries
            .iter()
            .map(|e| {
                Ok(CloudRow {
                    uuid: e
                        .get("uuid")
                        .and_then(Value::as_str)
                        .unwrap_or("")
                        .to_string(),
                    group: e
                        .get("group")
                        .and_then(Value::as_str)
                        .unwrap_or("")
                        .to_string(),
                    nonce: BASE64
                        .decode(
                            e.get("nonce")
                                .and_then(Value::as_str)
                                .unwrap_or("")
                                .as_bytes(),
                        )
                        .unwrap_or_default(),
                    ciphertext: BASE64
                        .decode(
                            e.get("ciphertext")
                                .and_then(Value::as_str)
                                .unwrap_or("")
                                .as_bytes(),
                        )
                        .unwrap_or_default(),
                    // The server returns camelCase `updatedAt`; tolerate the
                    // snake_case spelling as well so an old server never turns
                    // every edit of an existing row into an optimistic-lock
                    // conflict (base_updated_at = 0).
                    updated_at: e
                        .get("updatedAt")
                        .and_then(Value::as_i64)
                        .or_else(|| e.get("updated_at").and_then(Value::as_i64))
                        .unwrap_or(0),
                })
            })
            .collect()
    }

    /// Upserts and deletes rows in one batch request. Returns the upserted
    /// (uuid, updated_at) pairs and any uuids the server rejected as stale
    /// (optimistic-lock conflicts).
    pub fn sync_entries(
        &self,
        vault_id: &str,
        upserts: &[RowUpsert],
        deletes: &[String],
    ) -> Result<SyncEntriesResult, String> {
        let upserts_json: Vec<Value> = upserts
            .iter()
            .map(|u| {
                serde_json::json!({
                    "uuid": u.uuid,
                    "group": u.group,
                    "nonce": BASE64.encode(&u.nonce),
                    "ciphertext": BASE64.encode(&u.ciphertext),
                    "baseUpdatedAt": u.base_updated_at,
                })
            })
            .collect();
        let body = serde_json::json!({
            "upserts": upserts_json,
            "deletes": deletes,
        });
        let path = format!("/api/vaults/{}/entries/sync", encode_path(vault_id));
        let resp = call_json(
            &self.agent,
            "POST",
            &format!("{}{}", self.base, path),
            &path,
            Some(&self.token),
            Some(&self.user_id),
            Some(&body),
        )?;
        let upserted = resp
            .get("upserted")
            .and_then(Value::as_array)
            .map(|a| {
                a.iter()
                    .filter_map(|v| {
                        Some((
                            v.get("uuid")?.as_str()?.to_string(),
                            v.get("updatedAt")?.as_i64()?,
                        ))
                    })
                    .collect::<Vec<_>>()
            })
            .unwrap_or_default();
        let conflicts = resp
            .get("conflicts")
            .and_then(Value::as_array)
            .map(|a| {
                a.iter()
                    .filter_map(|v| v.as_str().map(String::from))
                    .collect()
            })
            .unwrap_or_default();
        Ok((upserted, conflicts))
    }
}

/// Performs a JSON request and returns the parsed body. Non-2xx responses
/// surface the server's `error` field when present, with the status preserved.
fn call_json_err(
    agent: &ureq::Agent,
    method: &str,
    url: &str,
    path: &str,
    token: Option<&str>,
    user_id: Option<&str>,
    body: Option<&Value>,
) -> Result<Value, CloudError> {
    let body_bytes: Vec<u8> = body
        .map(|v| serde_json::to_vec(v).expect("JSON serialization failed"))
        .unwrap_or_default();

    let auth_header = token.map(|t| format!("Bearer {t}"));
    let sig_headers = user_id.map(|uid| {
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|d| d.as_secs())
            .unwrap_or(0)
            .to_string();
        let mut nonce = [0u8; 16];
        secure_random_bytes(&mut nonce);
        let nonce = hex::encode(nonce);
        let signature = sign_request(uid, method, path, &timestamp, &nonce, &body_bytes)
            .expect("sign request failed");
        (timestamp, nonce, signature)
    });

    let response = match method {
        "GET" => {
            let mut b = agent.get(url);
            if let Some(ref h) = auth_header {
                b = b.header("Authorization", h);
            }
            if let Some((ref ts, ref nonce, ref sig)) = sig_headers {
                b = b
                    .header("X-Timestamp", ts)
                    .header("X-Nonce", nonce)
                    .header("X-Signature", sig);
            }
            b.call()
        }
        "POST" => {
            let mut b = agent.post(url);
            if let Some(ref h) = auth_header {
                b = b.header("Authorization", h);
            }
            if let Some((ref ts, ref nonce, ref sig)) = sig_headers {
                b = b
                    .header("X-Timestamp", ts)
                    .header("X-Nonce", nonce)
                    .header("X-Signature", sig);
            }
            b.header("Content-Type", "application/json")
                .send(&body_bytes)
        }
        "PUT" => {
            let mut b = agent.put(url);
            if let Some(ref h) = auth_header {
                b = b.header("Authorization", h);
            }
            if let Some((ref ts, ref nonce, ref sig)) = sig_headers {
                b = b
                    .header("X-Timestamp", ts)
                    .header("X-Nonce", nonce)
                    .header("X-Signature", sig);
            }
            b.header("Content-Type", "application/json")
                .send(&body_bytes)
        }
        _ => {
            return Err(CloudError::net(format!(
                "unsupported HTTP method: {method}"
            )))
        }
    }
    .map_err(|e| match e {
        ureq::Error::StatusCode(code) => CloudError {
            status: Some(code),
            message: format!("HTTP {code}"),
        },
        other => CloudError::net(format!("network error: {other}")),
    })?;

    let status = response.status();
    let text = response
        .into_body()
        .read_to_string()
        .map_err(|e| CloudError::net(format!("unable to read response: {e}")))?;
    let value: Value = if text.is_empty() {
        Value::Null
    } else {
        serde_json::from_str(&text)
            .map_err(|e| CloudError::net(format!("invalid JSON response: {e}")))?
    };
    let status_code = status.as_u16();
    if !(200..300).contains(&status_code) {
        let message = value
            .get("error")
            .and_then(Value::as_str)
            .map(String::from)
            .unwrap_or_else(|| format!("HTTP {status_code}"));
        return Err(CloudError {
            status: Some(status_code),
            message,
        });
    }
    Ok(value)
}

/// `call_json_err` with the message-only error the older command layer uses.
fn call_json(
    agent: &ureq::Agent,
    method: &str,
    url: &str,
    path: &str,
    token: Option<&str>,
    user_id: Option<&str>,
    body: Option<&Value>,
) -> Result<Value, String> {
    call_json_err(agent, method, url, path, token, user_id, body).map_err(|e| e.message)
}

fn encode_path(segment: &str) -> String {
    let mut out = String::new();
    for b in segment.bytes() {
        match b {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'_' | b'.' => out.push(b as char),
            _ => out.push_str(&format!("%{b:02X}")),
        }
    }
    out
}

/// Derives the 32-byte vault key: Argon2id v1.3, 64 MiB, 3 iterations,
/// 4 lanes, salt = the vault id (utf8), matching `openvalutCrypto.deriveKey`.
pub fn derive_key(password: &str, vault_id: &str) -> Result<[u8; 32], String> {
    let params = Params::new(
        ARGON_MEMORY_KIB,
        ARGON_ITERATIONS,
        ARGON_PARALLELISM,
        Some(32),
    )
    .map_err(|e| format!("invalid argon2 params: {e}"))?;
    let argon = Argon2::new(Algorithm::Argon2id, Version::V0x13, params);
    let mut key = [0u8; 32];
    argon
        .hash_password_into(password.as_bytes(), vault_id.as_bytes(), &mut key)
        .map_err(|e| format!("key derivation failed: {e}"))?;
    Ok(key)
}

/// AES-256-GCM encrypt, returning (nonce, ciphertext), as the app does.
pub fn encrypt_blob(key: &[u8; 32], plaintext: &[u8]) -> Result<(Vec<u8>, Vec<u8>), String> {
    let cipher = Aes256Gcm::new_from_slice(key).expect("32-byte key");
    let mut nonce = [0u8; 12];
    rand::thread_rng().fill_bytes(&mut nonce);
    let ct = cipher
        .encrypt(Nonce::from_slice(&nonce), plaintext)
        .map_err(|_| "encryption failed".to_string())?;
    Ok((nonce.to_vec(), ct))
}

/// AES-256-GCM decrypt; authentication failure means a wrong master password.
pub fn decrypt_blob(key: &[u8; 32], nonce: &[u8], ciphertext: &[u8]) -> Result<Vec<u8>, String> {
    let cipher = Aes256Gcm::new_from_slice(key).expect("32-byte key");
    cipher
        .decrypt(Nonce::from_slice(nonce), ciphertext)
        .map_err(|_| "云端数据解密失败：主密码可能不正确".to_string())
}

/// Encrypts a row payload (or group path) with the vault key.
pub fn encrypt_row(key: &[u8; 32], plaintext: &[u8]) -> Result<(Vec<u8>, Vec<u8>), String> {
    encrypt_blob(key, plaintext)
}

/// Decrypts a row payload with the vault key.
pub fn decrypt_row(key: &[u8; 32], nonce: &[u8], ciphertext: &[u8]) -> Result<Vec<u8>, String> {
    decrypt_blob(key, nonce, ciphertext)
}

/// Encrypts a group path into the row `group` field: "base64(nonce).base64(ct)".
pub fn encrypt_group(key: &[u8; 32], group: &str) -> Result<String, String> {
    let (nonce, ct) = encrypt_row(key, group.as_bytes())?;
    Ok(format!("{}.{}", BASE64.encode(&nonce), BASE64.encode(&ct)))
}

/// Decrypts a row `group` field back to the group path. An empty field (root)
/// or an unencrypted fallback is returned verbatim.
pub fn decrypt_group(key: &[u8; 32], stored: &str) -> Result<String, String> {
    if stored.is_empty() {
        return Ok(String::new());
    }
    match stored.split_once('.') {
        Some((n, c)) => {
            let nonce = BASE64.decode(n.as_bytes()).map_err(|e| e.to_string())?;
            let ct = BASE64.decode(c.as_bytes()).map_err(|e| e.to_string())?;
            let plain = decrypt_row(key, &nonce, &ct)?;
            Ok(String::from_utf8_lossy(&plain).into_owned())
        }
        None => Ok(stored.to_string()),
    }
}

/// Derives the account meta key (encrypts vault names / group labels shown in
/// the cloud list): Argon2id(master, salt = userId), per the Flutter session.
pub fn derive_meta_key(master: &str, user_id: &str) -> Result<[u8; 32], String> {
    derive_key(master, user_id)
}

/// Encrypts a display name into the vault `name` field:
/// "v1:base64(nonce).base64(ct)" — matching `_encryptMeta` in the app.
pub fn encrypt_meta(key: &[u8; 32], plain: &str) -> String {
    let (nonce, ct) =
        encrypt_blob(key, plain.as_bytes()).expect("AES-GCM of a short string cannot fail");
    format!("v1:{}.{}", BASE64.encode(&nonce), BASE64.encode(&ct))
}

/// Decrypts a vault `name`. Values without the `v1:` marker (or that fail to
/// decrypt) pass through verbatim, like the Dart fallback.
pub fn decrypt_meta(key: &[u8; 32], stored: &str) -> String {
    let Some(rest) = stored.strip_prefix("v1:") else {
        return stored.to_string();
    };
    let outcome = (|| -> Result<String, String> {
        let (n, c) = rest
            .split_once('.')
            .ok_or_else(|| "missing nonce part".to_string())?;
        let nonce = BASE64.decode(n.as_bytes()).map_err(|e| e.to_string())?;
        let ct = BASE64.decode(c.as_bytes()).map_err(|e| e.to_string())?;
        let plain = decrypt_blob(key, &nonce, &ct)?;
        Ok(String::from_utf8_lossy(&plain).into_owned())
    })();
    outcome.unwrap_or_else(|_| stored.to_string())
}

/// A fresh vault id: UUIDv4 without dashes (32 lowercase hex chars), the
/// format the server's `is_hex_id` accepts.
pub fn new_vault_id() -> String {
    uuid::Uuid::new_v4().simple().to_string().to_lowercase()
}

/// One in-flight QR scan-login session, ported from `openvalut-cli`'s
/// `scan_login.rs`. The one-off RSA private key and the poll secret stay in
/// memory only; the server deletes the session after the first `confirmed`
/// poll, so `poll_once` consumes the token immediately.
pub struct ScanLogin {
    base: String,
    session_id: String,
    qr_content: String,
    session_secret: String,
    private_key: PrivateKey,
    agent: ureq::Agent,
}

/// Result of a single poll of the scan session.
pub enum ScanPoll {
    Pending,
    Expired,
    Confirmed {
        token: String,
        username: String,
        user_id: Option<String>,
        master_password: Option<String>,
    },
}

impl ScanLogin {
    pub fn start(server: &str) -> Result<Self, String> {
        let base = server.trim_end_matches('/').to_string();
        let agent = new_agent();
        let private_key = PrivateKey::new(&mut UnwrapErr(getrandom::SysRng), 2048)
            .map_err(|e| format!("无法生成扫码密钥对：{e}"))?;
        let public_key = private_key.to_public_key();
        let body = serde_json::json!({ "publicKey": encode_public_key(&public_key) });

        let created = post_json(&agent, &format!("{base}/api/login/scan"), &body)?;
        let session_id = created
            .get("sessionId")
            .and_then(Value::as_str)
            .ok_or_else(|| "服务器未返回扫码会话 id".to_string())?
            .to_string();
        let qr_content = created
            .get("qrContent")
            .and_then(Value::as_str)
            .map(str::to_string)
            .unwrap_or_else(|| format!("openvalut://scan-login/{session_id}"));
        let session_secret = created
            .get("sessionSecret")
            .and_then(Value::as_str)
            .ok_or_else(|| "服务器未返回扫码会话密钥".to_string())?
            .to_string();

        Ok(Self {
            base,
            session_id,
            qr_content,
            session_secret,
            private_key,
            agent,
        })
    }

    pub fn session_id(&self) -> &str {
        &self.session_id
    }

    /// The `openvalut://scan-login/<id>` string encoded in the QR code.
    pub fn qr_content(&self) -> &str {
        &self.qr_content
    }

    /// Renders the QR code as an SVG string for the webview.
    pub fn qr_svg(&self) -> Result<String, String> {
        let code = qrcode::QrCode::new(self.qr_content.as_bytes())
            .map_err(|e| format!("无法生成二维码：{e}"))?;
        Ok(code
            .render::<qrcode::render::svg::Color>()
            .min_dimensions(200, 200)
            .quiet_zone(true)
            .build())
    }

    /// One poll. `confirmed` is final: the one-time token is decrypted into a
    /// `ScanPoll::Confirmed` here and cannot be retrieved a second time.
    pub fn poll_once(&self) -> Result<ScanPoll, String> {
        let url = format!("{}/api/login/scan/{}", self.base, self.session_id);
        let resp = self
            .agent
            .get(&url)
            .header("x-scan-secret", &self.session_secret)
            .call()
            .map_err(|e| format!("轮询扫码状态失败：{e}"))?;
        let http_status = resp.status();
        let text = resp
            .into_body()
            .read_to_string()
            .map_err(|e| format!("无法读取扫码状态响应：{e}"))?;
        let value: Value = if text.is_empty() {
            Value::Null
        } else {
            serde_json::from_str(&text).map_err(|e| format!("扫码状态响应不是 JSON：{e}"))?
        };
        if !(200..300).contains(&http_status.as_u16()) {
            let message = value
                .get("error")
                .and_then(Value::as_str)
                .unwrap_or("HTTP error");
            return Err(format!("服务器拒绝轮询扫码状态：{message}"));
        }
        match value
            .get("status")
            .and_then(Value::as_str)
            .unwrap_or("pending")
        {
            "confirmed" => {
                let token = value
                    .get("token")
                    .and_then(Value::as_str)
                    .unwrap_or("")
                    .to_string();
                if token.is_empty() {
                    return Err("手机已确认但服务器未返回登录令牌".to_string());
                }
                let username = value
                    .get("username")
                    .and_then(Value::as_str)
                    .unwrap_or("")
                    .to_string();
                let user_id = value
                    .get("userId")
                    .and_then(Value::as_str)
                    .map(str::to_string);
                let master_password = match value.get("vaultCiphertext").and_then(Value::as_str) {
                    Some(ciphertext) if !ciphertext.is_empty() => Some(self.decrypt(ciphertext)?),
                    _ => None,
                };
                Ok(ScanPoll::Confirmed {
                    token,
                    username,
                    user_id,
                    master_password,
                })
            }
            "expired" => Ok(ScanPoll::Expired),
            _ => Ok(ScanPoll::Pending),
        }
    }

    /// Decrypts the phone's RSA-OAEP(SHA-256) blob with the session key.
    fn decrypt(&self, ciphertext_b64: &str) -> Result<String, String> {
        let ciphertext = BASE64
            .decode(ciphertext_b64.trim().as_bytes())
            .map_err(|e| format!("扫码密文不是合法 base64：{e}"))?;
        let plaintext = self
            .private_key
            .oaep_decrypt::<Sha256>(&ciphertext)
            .map_err(|_| "无法解密手机回传的数据（密钥不匹配）".to_string())?;
        String::from_utf8(plaintext).map_err(|_| "解密结果不是 UTF-8 文本".to_string())
    }
}

/// Encodes the RSA public key exactly like the Flutter app's
/// `encodeScanPublicKey`: base64url (no padding) of `{"n":"<hex>","e":"<hex>"}`.
fn encode_public_key(key: &PublicKey) -> String {
    let json = format!(
        "{{\"n\":\"{}\",\"e\":\"{}\"}}",
        hex::encode(key.n().as_ref().to_be_bytes_trimmed_vartime()),
        hex::encode(key.e().to_be_bytes_trimmed_vartime())
    );
    BASE64URL_NOPAD.encode(json.as_bytes())
}

fn post_json(agent: &ureq::Agent, url: &str, body: &Value) -> Result<Value, String> {
    let bytes = serde_json::to_vec(body).map_err(|e| e.to_string())?;
    let resp = agent
        .post(url)
        .header("Content-Type", "application/json")
        .send(&bytes)
        .map_err(|e| format!("连接云服务器失败：{e}"))?;
    let http_status = resp.status();
    let text = resp
        .into_body()
        .read_to_string()
        .map_err(|e| format!("无法读取响应：{e}"))?;
    let value: Value = if text.is_empty() {
        Value::Null
    } else {
        serde_json::from_str(&text).map_err(|e| format!("响应不是 JSON：{e}"))?
    };
    if !(200..300).contains(&http_status.as_u16()) {
        let message = value
            .get("error")
            .and_then(Value::as_str)
            .unwrap_or("HTTP error");
        return Err(format!("服务器返回错误：{message}"));
    }
    Ok(value)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn blob_round_trips_and_authenticates() {
        let key = derive_key("testpass", "0123456789abcdef0123456789abcdef").expect("key");
        assert_eq!(key.len(), 32);
        let (nonce, ct) = encrypt_blob(&key, b"hello kdbx").expect("encrypt");
        assert_eq!(nonce.len(), 12);
        let plain = decrypt_blob(&key, &nonce, &ct).expect("decrypt");
        assert_eq!(plain, b"hello kdbx");

        let wrong = derive_key("wrongpass", "0123456789abcdef0123456789abcdef").expect("key");
        assert!(decrypt_blob(&wrong, &nonce, &ct).is_err());
    }

    #[test]
    fn group_round_trips() {
        let key = derive_key("pw", "0123456789abcdef0123456789abcdef").unwrap();
        for path in ["", "网站", "网站/邮箱"] {
            let stored = encrypt_group(&key, path).unwrap();
            assert_eq!(decrypt_group(&key, &stored).unwrap(), path);
        }
        // Unencrypted legacy value passes through verbatim.
        assert_eq!(decrypt_group(&key, "plain").unwrap(), "plain");
    }

    #[test]
    fn meta_names_round_trip_with_v1_prefix() {
        let key = derive_key("pw", "0123456789abcdef0123456789abcdef").unwrap();
        let stored = encrypt_meta(&key, "我的云库");
        assert!(stored.starts_with("v1:"));
        assert_eq!(decrypt_meta(&key, &stored), "我的云库");
        // Non-v1 and undecryptable v1 values pass through verbatim.
        assert_eq!(decrypt_meta(&key, "plain"), "plain");
        assert_eq!(decrypt_meta(&key, "v1:notbase64"), "v1:notbase64");
        let wrong = derive_key("wrong", "0123456789abcdef0123456789abcdef").unwrap();
        assert_eq!(decrypt_meta(&wrong, &stored), stored);
    }

    #[test]
    fn normalize_server_adds_scheme_and_strips_slash() {
        assert_eq!(
            normalize_server("openvalut.example", "https://d"),
            "https://openvalut.example"
        );
        assert_eq!(normalize_server("https://a.b/", "https://d"), "https://a.b");
        assert_eq!(normalize_server("http://a.b", "https://d"), "http://a.b");
        assert_eq!(normalize_server("  ", "https://d/"), "https://d");
    }

    #[test]
    fn new_vault_id_is_32_lowercase_hex() {
        let id = new_vault_id();
        assert_eq!(id.len(), 32);
        assert!(id
            .chars()
            .all(|c| c.is_ascii_hexdigit() && !c.is_ascii_uppercase()));
    }

    #[test]
    fn public_key_encoding_matches_dart_format() {
        let private = PrivateKey::new(&mut UnwrapErr(getrandom::SysRng), 2048).expect("keypair");
        let public = private.to_public_key();
        let encoded = encode_public_key(&public);
        assert!(!encoded.contains('='));
        assert!(!encoded.contains('+') && !encoded.contains('/'));
        let json = BASE64URL_NOPAD
            .decode(encoded.as_bytes())
            .expect("base64url");
        let parsed: Value = serde_json::from_slice(&json).expect("json");
        assert_eq!(
            parsed["n"].as_str().unwrap(),
            hex::encode(public.n().as_ref().to_be_bytes_trimmed_vartime())
        );
        assert_eq!(
            parsed["e"].as_str().unwrap(),
            hex::encode(public.e().to_be_bytes_trimmed_vartime())
        );
    }

    #[test]
    fn decrypt_round_trips_a_relayed_password() {
        let private = PrivateKey::new(&mut UnwrapErr(getrandom::SysRng), 2048).expect("keypair");
        let public = private.to_public_key();
        let encoded = encode_public_key(&public);

        // Mimic the phone: decode the advertised key and encrypt a password.
        let decoded: Value =
            serde_json::from_slice(&BASE64URL_NOPAD.decode(encoded.as_bytes()).unwrap()).unwrap();
        let n = rsa::BoxedUint::from_be_slice_vartime(
            &hex::decode(decoded["n"].as_str().unwrap()).unwrap(),
        );
        let e = rsa::BoxedUint::from_be_slice_vartime(
            &hex::decode(decoded["e"].as_str().unwrap()).unwrap(),
        );
        let phone_key = PublicKey::new(n, e).expect("phone key");
        let ciphertext = phone_key
            .oaep_encrypt::<Sha256>(b"correct horse")
            .expect("encrypt");
        let encoded_ct = BASE64.encode(&ciphertext);

        let session = ScanLogin {
            base: "https://example.test".to_string(),
            session_id: "s".to_string(),
            qr_content: "openvalut://scan-login/s".to_string(),
            session_secret: "secret".to_string(),
            private_key: private,
            agent: new_agent(),
        };
        assert_eq!(session.decrypt(&encoded_ct).unwrap(), "correct horse");
    }
}
