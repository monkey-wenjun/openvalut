//! Terminal QR-code login for the CLI.
//!
//! The CLI plays the same role the Flutter app plays on its “扫码授权登录”
//! screen: it creates a scan-login session on the OpenValut Cloud server,
//! renders the returned `openvalut://scan-login/<id>` URL as a QR code in the
//! terminal, then polls until a phone that is already signed in to the same
//! account scans it and confirms.
//!
//! Two things come back over that channel:
//!   * the account id (which doubles as the account Secret Key), so
//!     `auth login --scan` never needs the Secret Key to be typed on the PC; and
//!   * the vault master password (when the phone had the vault unlocked), so
//!     `unlock --scan` unlocks the PC without any typing.
//!
//! Security properties:
//!   * The CLI generates a one-off 2048-bit RSA keypair per session. Only the
//!     public half is advertised (stored server-side); the private half never
//!     leaves this process' memory.
//!   * The phone encrypts the master password with that public key
//!     (RSA-OAEP/SHA-256) and the server only relays ciphertext, so neither the
//!     server nor someone who merely photographs the QR learns the password.
//!   * The poll secret (`x-scan-secret`) never leaves the CLI, so only the
//!     device that created the QR can collect the login token / account id.

use std::time::{Duration, Instant};

use data_encoding::{BASE64, BASE64URL_NOPAD};
use rsa::traits::PublicKeyParts;
use rsa::{Oaep, RsaPrivateKey, RsaPublicKey};
use serde_json::Value;
use sha2::Sha256;

/// Default cloud endpoint, matching `auth login` / the desktop app.
pub const DEFAULT_SERVER: &str = "https://openvalut.example.com/";

/// How long we keep polling for the phone (the server expires the session after
/// 2 minutes, so waiting the same is enough).
const SESSION_TIMEOUT: Duration = Duration::from_secs(120);
const POLL_INTERVAL: Duration = Duration::from_secs(2);

/// Everything the phone can hand back after a successful scan.
pub struct ScanResult {
    /// Account email/username.
    pub username: String,
    /// Account id (= the account Secret Key). `None` only from an older server
    /// that does not yet return it.
    pub user_id: Option<String>,
    /// The vault master password, present only when the phone had it unlocked.
    pub master_password: Option<String>,
}

enum PollState {
    Pending,
    Confirmed(Value),
    Expired,
}

/// An in-flight QR-code login session.
pub struct ScanLogin {
    base: String,
    session_id: String,
    qr_content: String,
    session_secret: String,
    private_key: RsaPrivateKey,
    agent: ureq::Agent,
}

impl ScanLogin {
    /// Creates a session on `server` and advertises our one-off public key.
    pub fn start(server: &str) -> Result<Self, String> {
        let base = normalize_server(server)?;
        let agent = ureq::Agent::config_builder()
            .http_status_as_error(false)
            .build()
            .new_agent();

        let mut rng = rand::thread_rng();
        let private_key =
            RsaPrivateKey::new(&mut rng, 2048).map_err(|e| format!("无法生成扫码密钥对：{e}"))?;
        let public_key = RsaPublicKey::from(&private_key);
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

    /// The `openvalut://scan-login/<id>` string encoded in the QR code.
    pub fn qr_content(&self) -> &str {
        &self.qr_content
    }

    /// Renders the QR code as unicode half-blocks for the terminal.
    pub fn qr_terminal(&self) -> Result<String, String> {
        let code = qrcode::QrCode::new(self.qr_content.as_bytes())
            .map_err(|e| format!("无法生成二维码：{e}"))?;
        Ok(code
            .render::<qrcode::render::unicode::Dense1x2>()
            .quiet_zone(true)
            .build())
    }

    fn poll(&self) -> Result<PollState, String> {
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
        Ok(
            match value
                .get("status")
                .and_then(Value::as_str)
                .unwrap_or("pending")
            {
                "confirmed" => PollState::Confirmed(value),
                "expired" => PollState::Expired,
                _ => PollState::Pending,
            },
        )
    }

    /// Polls until the phone confirms, the session expires, or `timeout` lapses.
    pub fn wait(&self) -> Result<ScanResult, String> {
        let deadline = Instant::now() + SESSION_TIMEOUT;
        loop {
            match self.poll()? {
                PollState::Confirmed(value) => return self.finish(value),
                PollState::Expired => return Err("二维码已过期，请重新运行".to_string()),
                PollState::Pending => {}
            }
            if Instant::now() >= deadline {
                return Err("等待手机扫码超时，请重新运行".to_string());
            }
            std::thread::sleep(POLL_INTERVAL);
        }
    }

    fn finish(&self, value: Value) -> Result<ScanResult, String> {
        // A confirmed response always carries a fresh token; we do not reuse it
        // (later commands mint their own via email + Secret Key), but its
        // presence confirms the phone really did approve this session.
        if value
            .get("token")
            .and_then(Value::as_str)
            .unwrap_or("")
            .is_empty()
        {
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
        Ok(ScanResult {
            username,
            user_id,
            master_password,
        })
    }

    /// Decrypts the phone's RSA-OAEP(SHA-256) blob with the session private key.
    fn decrypt(&self, ciphertext_b64: &str) -> Result<String, String> {
        let ciphertext = BASE64
            .decode(ciphertext_b64.trim().as_bytes())
            .map_err(|e| format!("扫码密文不是合法 base64：{e}"))?;
        let padding = Oaep::new::<Sha256>();
        let plaintext = self
            .private_key
            .decrypt(padding, &ciphertext)
            .map_err(|_| "无法解密手机回传的数据（密钥不匹配）".to_string())?;
        String::from_utf8(plaintext).map_err(|_| "解密结果不是 UTF-8 文本".to_string())
    }
}

fn normalize_server(server: &str) -> Result<String, String> {
    let trimmed = server.trim();
    if trimmed.is_empty() {
        return Err("云服务器地址为空".to_string());
    }
    Ok(trimmed.trim_end_matches('/').to_string())
}

/// Encodes the RSA public key exactly like the Flutter app's
/// `encodeScanPublicKey`: base64url (no padding) of `{"n":"<hex>","e":"<hex>"}`.
fn encode_public_key(key: &RsaPublicKey) -> String {
    let json = format!(
        "{{\"n\":\"{}\",\"e\":\"{}\"}}",
        hex::encode(key.n().to_bytes_be()),
        hex::encode(key.e().to_bytes_be())
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
    fn public_key_encoding_matches_dart_format() {
        let mut rng = rand::thread_rng();
        let private = RsaPrivateKey::new(&mut rng, 2048).expect("keypair");
        let public = RsaPublicKey::from(&private);
        let encoded = encode_public_key(&public);
        // base64url with no padding.
        assert!(!encoded.contains('='));
        assert!(!encoded.contains('+') && !encoded.contains('/'));
        // Decodes to {"n":<hex>,"e":<hex>} where n is the modulus.
        let json = BASE64URL_NOPAD
            .decode(encoded.as_bytes())
            .expect("base64url");
        let parsed: Value = serde_json::from_slice(&json).expect("json");
        assert_eq!(
            parsed["n"].as_str().unwrap(),
            hex::encode(public.n().to_bytes_be())
        );
        assert_eq!(
            parsed["e"].as_str().unwrap(),
            hex::encode(public.e().to_bytes_be())
        );
    }

    #[test]
    fn decrypt_round_trips_a_relayed_password() {
        let mut rng = rand::thread_rng();
        let private = RsaPrivateKey::new(&mut rng, 2048).expect("keypair");
        let public = RsaPublicKey::from(&private);
        let encoded = encode_public_key(&public);

        // Mimic the phone: decode the advertised key and encrypt a password.
        let decoded: Value =
            serde_json::from_slice(&BASE64URL_NOPAD.decode(encoded.as_bytes()).unwrap()).unwrap();
        let n = rsa::BigUint::parse_bytes(decoded["n"].as_str().unwrap().as_bytes(), 16).unwrap();
        let e = rsa::BigUint::parse_bytes(decoded["e"].as_str().unwrap().as_bytes(), 16).unwrap();
        let phone_key = RsaPublicKey::new(n, e).expect("phone key");
        let padding = Oaep::new::<Sha256>();
        let ciphertext = phone_key
            .encrypt(&mut rng, padding, b"correct horse")
            .expect("encrypt");
        let encoded_ct = BASE64.encode(&ciphertext);

        let session = ScanLogin {
            base: "https://example.test".to_string(),
            session_id: "s".to_string(),
            qr_content: "openvalut://scan-login/s".to_string(),
            session_secret: "secret".to_string(),
            private_key: private,
            agent: ureq::Agent::config_builder().build().new_agent(),
        };
        assert_eq!(session.decrypt(&encoded_ct).unwrap(), "correct horse");
    }
}
