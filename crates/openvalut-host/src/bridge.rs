//! Client for the desktop OpenValut app's loopback bridge.
//!
//! The running desktop app listens on `127.0.0.1:<port>` and requires a bearer
//! token; both are published in `host-bridge.json` (0600) inside the app's
//! config directory. The host uses this to obtain unlocked vault bytes and the
//! transformed key (so it need not know the master password), and to perform
//! entry mutations in the app (which holds the original credentials).

use std::path::PathBuf;

use base64::Engine;
use serde_json::{json, Value};

/// Thrown when the desktop app cannot be reached or rejects a request.
#[derive(Debug)]
pub struct BridgeError(pub String);

impl std::fmt::Display for BridgeError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl std::error::Error for BridgeError {}

impl From<String> for BridgeError {
    fn from(m: String) -> Self {
        BridgeError(m)
    }
}

/// One unlocked vault served by the app.
#[derive(Debug, Clone)]
pub struct AppVaultData {
    pub id: String,
    pub name: String,
    pub kdbx_bytes: Vec<u8>,
    pub transformed_key: [u8; 32],
    pub kdf_fingerprint: String,
}

#[derive(Debug, Clone)]
pub struct AppSessionStatus {
    pub generation: String,
    pub unlocked: bool,
}

/// Reads `{port, token}` from host-bridge.json.
fn bridge_info(config_dir: Option<PathBuf>) -> Option<(u16, String)> {
    if let Some(config_dir) = config_dir {
        return read_bridge_info(&config_dir);
    }
    default_config_dirs()
        .into_iter()
        .find_map(|config_dir| read_bridge_info(&config_dir))
}

fn read_bridge_info(config_dir: &std::path::Path) -> Option<(u16, String)> {
    let text = std::fs::read_to_string(config_dir.join("host-bridge.json")).ok()?;
    let data: Value = serde_json::from_str(&text).ok()?;
    let port = data.get("port")?.as_u64()? as u16;
    let token = data.get("token")?.as_str()?.to_string();
    if port == 0 || token.is_empty() {
        return None;
    }
    Some((port, token))
}

fn default_config_dirs() -> Vec<PathBuf> {
    let home = std::env::var_os("HOME")
        .map(PathBuf::from)
        .unwrap_or_default();
    if cfg!(target_os = "macos") {
        vec![
            home.join(
                "Library/Containers/app.openvalut/Data/Library/Application Support/openvalut",
            ),
            home.join("Library/Application Support/openvalut"),
        ]
    } else if cfg!(target_os = "windows") {
        // The desktop app publishes host-bridge.json under %APPDATA%\openvalut
        // on Windows (see HostBridge._bridgeDir in the Flutter app).
        let appdata = std::env::var_os("APPDATA")
            .map(PathBuf::from)
            .unwrap_or_default();
        vec![appdata.join("openvalut")]
    } else {
        let xdg = std::env::var_os("XDG_CONFIG_HOME")
            .map(PathBuf::from)
            .unwrap_or_else(|| home.join(".config"));
        vec![xdg.join("openvalut")]
    }
}

fn get_json(port: u16, token: &str, path: &str) -> Result<Value, BridgeError> {
    let url = format!("http://127.0.0.1:{port}{path}");
    let body = ureq::get(&url)
        .header("Authorization", &format!("Bearer {token}"))
        .call()
        .map_err(|e| BridgeError(format!("桌面端桥接连接失败: {e}")))?;
    let status_code = body.status().as_u16();
    let text = body
        .into_body()
        .read_to_string()
        .map_err(|e| BridgeError(format!("读取响应失败: {e}")))?;
    if !(200..300).contains(&status_code) {
        return Err(BridgeError(format!("桌面端桥接返回 HTTP {status_code}")));
    }
    serde_json::from_str(&text).map_err(|e| BridgeError(format!("响应不是合法 JSON: {e}")))
}

fn post_json(port: u16, token: &str, path: &str, payload: &Value) -> Result<Value, BridgeError> {
    let url = format!("http://127.0.0.1:{port}{path}");
    let body = ureq::post(&url)
        .header("Authorization", &format!("Bearer {token}"))
        .header("Content-Type", "application/json")
        .send_json(payload)
        .map_err(|e| BridgeError(format!("桌面端桥接返回: {e}")))?;
    let status_code = body.status().as_u16();
    let text = body
        .into_body()
        .read_to_string()
        .map_err(|e| BridgeError(format!("读取响应失败: {e}")))?;
    if !(200..300).contains(&status_code) {
        return Err(BridgeError(format!("桌面端桥接返回 HTTP {status_code}")));
    }
    let value: Value = if text.is_empty() {
        json!({})
    } else {
        serde_json::from_str(&text).map_err(|e| BridgeError(format!("响应不是合法 JSON: {e}")))?
    };
    if value.get("ok").and_then(Value::as_bool) != Some(true) {
        let message = value
            .get("error")
            .and_then(Value::as_str)
            .unwrap_or("unknown error")
            .to_string();
        return Err(BridgeError(message));
    }
    Ok(value)
}

fn decode_b64(s: &str) -> Result<Vec<u8>, BridgeError> {
    base64::engine::general_purpose::STANDARD
        .decode(s)
        .map_err(|e| BridgeError(format!("base64 解码失败: {e}")))
}

pub fn fetch_session_status(config_dir: Option<PathBuf>) -> Result<AppSessionStatus, BridgeError> {
    let (port, token) =
        bridge_info(config_dir).ok_or_else(|| BridgeError("桌面端桥接未配置".into()))?;
    let data = get_json(port, &token, "/status")?;
    let generation = data
        .get("generation")
        .and_then(Value::as_str)
        .map(str::to_owned)
        .ok_or_else(|| BridgeError("桌面端桥接响应缺少 generation".into()))?;
    let unlocked = data
        .get("unlocked")
        .and_then(Value::as_bool)
        .ok_or_else(|| BridgeError("桌面端桥接响应缺少 unlocked".into()))?;
    Ok(AppSessionStatus {
        generation,
        unlocked,
    })
}

/// Fetches every unlocked vault from the desktop app.
pub fn fetch_vaults(config_dir: Option<PathBuf>) -> Result<Vec<AppVaultData>, BridgeError> {
    let (port, token) =
        bridge_info(config_dir).ok_or_else(|| BridgeError("桌面端桥接未配置".into()))?;
    let data = get_json(port, &token, "/vaults")?;
    let vaults = data
        .get("vaults")
        .and_then(Value::as_array)
        .ok_or_else(|| BridgeError("桌面端桥接响应缺少 vaults".into()))?;
    let mut out = Vec::with_capacity(vaults.len());
    for v in vaults {
        let id = v
            .get("id")
            .and_then(Value::as_str)
            .unwrap_or_default()
            .to_string();
        let name = v
            .get("name")
            .and_then(Value::as_str)
            .unwrap_or_default()
            .to_string();
        let kdbx_b64 = v
            .get("kdbxBase64")
            .and_then(Value::as_str)
            .unwrap_or_default();
        let tk_b64 = v
            .get("transformedKeyBase64")
            .and_then(Value::as_str)
            .unwrap_or_default();
        let fp = v
            .get("kdfFingerprint")
            .and_then(Value::as_str)
            .unwrap_or_default()
            .to_string();
        let kdbx_bytes = decode_b64(kdbx_b64)?;
        let tk_vec = decode_b64(tk_b64)?;
        let mut transformed_key = [0u8; 32];
        if tk_vec.len() != 32 {
            return Err(BridgeError("transformedKeyBase64 长度不是 32 字节".into()));
        }
        transformed_key.copy_from_slice(&tk_vec);
        out.push(AppVaultData {
            id,
            name,
            kdbx_bytes,
            transformed_key,
            kdf_fingerprint: fp,
        });
    }
    Ok(out)
}

/// Creates a new entry in an opened vault, returning its UUID.
pub fn create_entry(
    config_dir: Option<PathBuf>,
    id: &str,
    title: Option<&str>,
    username: Option<&str>,
    url: Option<&str>,
    custom_fields: Option<&Value>,
) -> Result<String, BridgeError> {
    let (port, token) =
        bridge_info(config_dir).ok_or_else(|| BridgeError("桌面端桥接未配置".into()))?;
    let mut body = json!({ "id": id });
    if let Some(t) = title {
        body["title"] = json!(t);
    }
    if let Some(u) = username {
        body["username"] = json!(u);
    }
    if let Some(u) = url {
        body["url"] = json!(u);
    }
    if let Some(cf) = custom_fields {
        body["customFields"] = cf.clone();
    }
    let data = post_json(port, &token, "/createEntry", &body)?;
    data.get("entryUuid")
        .and_then(Value::as_str)
        .map(|s| s.to_string())
        .ok_or_else(|| BridgeError("创建条目响应缺少 entryUuid".into()))
}

#[allow(clippy::too_many_arguments)]
pub fn update_entry(
    config_dir: Option<PathBuf>,
    id: &str,
    entry_uuid: &str,
    title: Option<&str>,
    username: Option<&str>,
    password: Option<&str>,
    url: Option<&str>,
    notes: Option<&str>,
) -> Result<(), BridgeError> {
    let (port, token) =
        bridge_info(config_dir).ok_or_else(|| BridgeError("桌面端桥接未配置".into()))?;
    let mut body = json!({ "id": id, "entryUuid": entry_uuid });
    if let Some(v) = title {
        body["title"] = json!(v);
    }
    if let Some(v) = username {
        body["username"] = json!(v);
    }
    if let Some(v) = password {
        body["password"] = json!(v);
    }
    if let Some(v) = url {
        body["url"] = json!(v);
    }
    if let Some(v) = notes {
        body["notes"] = json!(v);
    }
    post_json(port, &token, "/updateEntry", &body)?;
    Ok(())
}

/// Updates only the custom fields of an existing entry, appending/overwriting
/// the given keys. Used by passkey registration so the credential can be
/// stored on the existing site entry instead of creating a duplicate.
pub fn update_entry_custom(
    config_dir: Option<PathBuf>,
    id: &str,
    entry_uuid: &str,
    custom_fields: &Value,
) -> Result<(), BridgeError> {
    let (port, token) =
        bridge_info(config_dir).ok_or_else(|| BridgeError("桌面端桥接未配置".into()))?;
    let body = json!({
        "id": id,
        "entryUuid": entry_uuid,
        "customFields": custom_fields,
    });
    post_json(port, &token, "/updateEntry", &body)?;
    Ok(())
}

pub fn delete_entry(
    config_dir: Option<PathBuf>,
    id: &str,
    entry_uuid: &str,
) -> Result<(), BridgeError> {
    let (port, token) =
        bridge_info(config_dir).ok_or_else(|| BridgeError("桌面端桥接未配置".into()))?;
    post_json(
        port,
        &token,
        "/deleteEntry",
        &json!({ "id": id, "entryUuid": entry_uuid }),
    )?;
    Ok(())
}

pub fn save_vault(
    config_dir: Option<PathBuf>,
    id: &str,
    bytes: &[u8],
    transformed_key: &[u8; 32],
    kdf_fingerprint: &str,
) -> Result<(), BridgeError> {
    let (port, token) =
        bridge_info(config_dir).ok_or_else(|| BridgeError("桌面端桥接未配置".into()))?;
    let body = json!({
        "id": id,
        "kdbxBase64": base64::engine::general_purpose::STANDARD.encode(bytes),
        "transformedKeyBase64": base64::engine::general_purpose::STANDARD.encode(transformed_key),
        "kdfFingerprint": kdf_fingerprint,
    });
    post_json(port, &token, "/saveVault", &body)?;
    Ok(())
}

pub fn show_window(config_dir: Option<PathBuf>) -> Result<(), BridgeError> {
    let (port, token) =
        bridge_info(config_dir).ok_or_else(|| BridgeError("桌面端桥接未配置".into()))?;
    post_json(port, &token, "/showWindow", &json!({}))?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bridge_info_reads_an_explicit_config_directory() {
        let dir = tempfile::tempdir().unwrap();
        std::fs::write(
            dir.path().join("host-bridge.json"),
            r#"{"port":59684,"token":"test-token"}"#,
        )
        .unwrap();

        assert_eq!(
            bridge_info(Some(dir.path().to_path_buf())),
            Some((59684, "test-token".to_string()))
        );
    }

    #[test]
    fn bridge_info_rejects_invalid_values() {
        let dir = tempfile::tempdir().unwrap();
        std::fs::write(
            dir.path().join("host-bridge.json"),
            r#"{"port":0,"token":""}"#,
        )
        .unwrap();

        assert_eq!(bridge_info(Some(dir.path().to_path_buf())), None);
    }
}
