//! `auth` account persistence: remember the non-sensitive OpenValut Cloud
//! connection config so later `--cloud` commands don't need to repeat
//! `--email`/`--server`.
//!
//! Only the *non-sensitive* part (server + email) is written to a 0600 JSON
//! config file. The sensitive Secret Key (account UUID) stays in the OS
//! keychain (`keychain::CLOUD_SECRET_KEY`); it is never placed in the config
//! file. Each command mints a fresh token via `login`, so a stored token never
//! goes stale.

use serde::{Deserialize, Serialize};
use std::fs;
use std::io;
use std::path::Path;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CloudAccount {
    pub server: String,
    pub email: String,
}

/// File name (inside the app data dir) holding the persisted cloud account.
pub const ACCOUNT_FILE: &str = "cloud-account.json";

/// Writes the account atomically (temp file + rename) with owner-only access.
pub fn save_account(path: &Path, account: &CloudAccount) -> Result<(), String> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)
            .map_err(|e| format!("无法创建目录 {}: {e}", parent.display()))?;
    }
    let json = serde_json::to_string_pretty(account).map_err(|e| format!("序列化账号失败: {e}"))?;
    let tmp = path.with_extension("json.tmp");
    fs::write(&tmp, json).map_err(|e| format!("无法写入 {}: {e}", tmp.display()))?;
    set_owner_only(&tmp)?;
    fs::rename(&tmp, path).map_err(|e| format!("无法替换 {}: {e}", path.display()))?;
    set_owner_only(path)?;
    Ok(())
}

/// Returns the persisted account, or `None` when it has not been saved yet.
pub fn load_account(path: &Path) -> Result<Option<CloudAccount>, String> {
    match fs::read_to_string(path) {
        Ok(text) => serde_json::from_str(&text)
            .map(Some)
            .map_err(|e| format!("无法解析 {}: {e}", path.display())),
        Err(e) if e.kind() == io::ErrorKind::NotFound => Ok(None),
        Err(e) => Err(format!("无法读取 {}: {e}", path.display())),
    }
}

/// Removes the persisted account. Returns `true` when it existed.
pub fn delete_account(path: &Path) -> Result<bool, String> {
    match fs::remove_file(path) {
        Ok(()) => Ok(true),
        Err(e) if e.kind() == io::ErrorKind::NotFound => Ok(false),
        Err(e) => Err(format!("无法删除 {}: {e}", path.display())),
    }
}

#[cfg(unix)]
fn set_owner_only(path: &Path) -> Result<(), String> {
    use std::os::unix::fs::PermissionsExt;
    let perm = fs::Permissions::from_mode(0o600);
    fs::set_permissions(path, perm).map_err(|e| format!("无法设置权限 {}: {e}", path.display()))
}

#[cfg(not(unix))]
fn set_owner_only(_path: &Path) -> Result<(), String> {
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn temp_path() -> std::path::PathBuf {
        std::env::temp_dir().join(format!(
            "openvalut-cli-auth-{}-{}.json",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_nanos()
        ))
    }

    #[test]
    fn account_round_trips_and_delete_works() {
        let path = temp_path();
        let _ = fs::remove_file(&path);
        let account = CloudAccount {
            server: "https://openvalut.example.com".to_string(),
            email: "a@b.c".to_string(),
        };

        save_account(&path, &account).expect("save");
        assert_eq!(
            load_account(&path).expect("load").map(|a| a.email),
            Some(account.email)
        );
        assert!(delete_account(&path).expect("delete"));
        assert!(load_account(&path).expect("load").is_none());
        assert!(!delete_account(&path).expect("delete missing"));
    }

    #[cfg(unix)]
    #[test]
    fn account_file_is_owner_only() {
        use std::os::unix::fs::PermissionsExt;
        let path = temp_path();
        let _ = fs::remove_file(&path);
        let account = CloudAccount {
            server: "https://openvalut.example.com".to_string(),
            email: "a@b.c".to_string(),
        };
        save_account(&path, &account).expect("save");
        let mode = fs::metadata(&path).unwrap().permissions().mode() & 0o777;
        assert_eq!(mode, 0o600);
        let _ = fs::remove_file(&path);
    }
}
