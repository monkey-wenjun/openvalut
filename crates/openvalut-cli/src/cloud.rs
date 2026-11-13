//! OpenValut Cloud access: login with email + Secret Key, then download and
//! upload the encrypted vault blob. The blob key is Argon2id (64 MiB / 3 / 4)
//! derived from the master password and the vault id, matching the app and
//! the Go server; the blob is AES-256-GCM encrypted.
use std::time::{SystemTime, UNIX_EPOCH};

use aes_gcm::aead::Aead;
use aes_gcm::{Aes256Gcm, KeyInit, Nonce};
use argon2::{Algorithm, Argon2, Params, Version};
use data_encoding::BASE64;
use openvalut_core::{secure_random_bytes, sign_request};
use rand::RngCore;
use serde::Deserialize;
use serde_json::Value;

const ARGON_MEMORY_KIB: u32 = 64 * 1024;
const ARGON_ITERATIONS: u32 = 3;
const ARGON_PARALLELISM: u32 = 4;

/// Upserted `(uuid, updated_at)` pairs plus the uuids the server rejected as
/// stale by its optimistic lock.
pub type SyncEntriesResult = (Vec<(String, i64)>, Vec<String>);

#[derive(Debug, Clone)]
pub struct CloudVault {
    pub id: String,
    pub name: String,
    pub nonce: Vec<u8>,
    pub ciphertext: Vec<u8>,
    #[allow(dead_code)]
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
        let data = call_json(
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
            .ok_or_else(|| "login failed: no token in response".to_string())?
            .to_string();
        Ok(CloudClient {
            agent,
            base: base.to_string(),
            token,
            user_id,
        })
    }

    pub fn list_vaults(&self) -> Result<Vec<CloudVault>, String> {
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
            .map(CloudVault::from)
            .collect())
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

    /// Deletes the given row uuids in one batch request. Returns the number of
    /// conflicts (rows the server did not know about).
    pub fn delete_rows(&self, vault_id: &str, deletes: &[String]) -> Result<usize, String> {
        let body = serde_json::json!({ "upserts": [], "deletes": deletes });
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
        let conflicts = resp
            .get("conflicts")
            .and_then(Value::as_array)
            .map(|a| a.len())
            .unwrap_or(0);
        Ok(conflicts)
    }

    pub fn create_vault(
        &self,
        id: &str,
        name: &str,
        nonce: &[u8],
        ciphertext: &[u8],
    ) -> Result<CloudVault, String> {
        let body = serde_json::json!({
            "id": id,
            "name": name,
            "nonce": BASE64.encode(nonce),
            "ciphertext": BASE64.encode(ciphertext),
        });
        let resp = call_json(
            &self.agent,
            "POST",
            &format!("{}/api/vaults", self.base),
            "/api/vaults",
            Some(&self.token),
            Some(&self.user_id),
            Some(&body),
        )?;
        let vault = resp
            .get("vault")
            .ok_or_else(|| "invalid response: missing vault".to_string())?;
        serde_json::from_value::<VaultJson>(vault.clone())
            .map(CloudVault::from)
            .map_err(|e| format!("invalid vault: {e}"))
    }
}

/// Performs a JSON request and returns the parsed body. Non-2xx responses
/// surface the server's `error` field when present.
fn call_json(
    agent: &ureq::Agent,
    method: &str,
    url: &str,
    path: &str,
    token: Option<&str>,
    user_id: Option<&str>,
    body: Option<&Value>,
) -> Result<Value, String> {
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
        _ => return Err(format!("unsupported HTTP method: {method}")),
    }
    .map_err(|e| match e {
        ureq::Error::StatusCode(code) => format!("HTTP {code}"),
        other => format!("network error: {other}"),
    })?;

    let status = response.status();
    let text = response
        .into_body()
        .read_to_string()
        .map_err(|e| format!("unable to read response: {e}"))?;
    let value: Value = if text.is_empty() {
        Value::Null
    } else {
        serde_json::from_str(&text).map_err(|e| format!("invalid JSON response: {e}"))?
    };
    let status_code = status.as_u16();
    if !(200..300).contains(&status_code) {
        let message = value
            .get("error")
            .and_then(Value::as_str)
            .map(String::from)
            .unwrap_or_else(|| format!("HTTP {status_code}"));
        return Err(message);
    }
    Ok(value)
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

/// Generates a new 32-char lowercase hex vault id (UUID v4 without dashes),
/// matching the app's `openvalutCloudSession.newVaultId`.
pub fn new_vault_id() -> String {
    let mut b = [0u8; 16];
    rand::thread_rng().fill_bytes(&mut b);
    b[6] = (b[6] & 0x0f) | 0x40; // version 4
    b[8] = (b[8] & 0x3f) | 0x80; // RFC 4122 variant
    b.iter().map(|x| format!("{x:02x}")).collect()
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

/// Encrypts a row payload (or group path) with the vault key. Same AES-256-GCM
/// primitive as the blob, matching the app's `openvalutCrypto.encrypt`.
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

        // A different password must fail authentication.
        let wrong = derive_key("wrongpass", "0123456789abcdef0123456789abcdef").expect("key");
        assert!(decrypt_blob(&wrong, &nonce, &ct).is_err());
    }

    #[test]
    fn vault_id_is_32_hex() {
        let id = new_vault_id();
        assert_eq!(id.len(), 32);
        assert!(id.bytes().all(|b| b.is_ascii_hexdigit()));
        // Version 4 nibble in the UUID.
        assert_eq!(id.as_bytes()[12], b'4');
    }
}
