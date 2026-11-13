//! Helpers for writing the encrypted TOTP secret used by the experimental
//! `pam_openvalut` PAM module.
use aes_gcm::aead::{Aead, KeyInit};
use aes_gcm::{Aes256Gcm, Nonce};
use std::fs;
use std::path::PathBuf;

const TOTP_DIR: &str = ".openvalut/totp";
const MACHINE_ID_PATH: &str = "/etc/machine-id";

pub fn machine_id() -> Option<String> {
    fs::read_to_string(MACHINE_ID_PATH)
        .ok()
        .map(|s| s.trim().to_string())
}

pub fn totp_path() -> Option<PathBuf> {
    let mid = machine_id()?;
    let home = dirs::home_dir()?;
    Some(home.join(TOTP_DIR).join(format!("{}.enc", mid)))
}

fn derive_key(machine_id: &str) -> [u8; 32] {
    use sha2::{Digest, Sha256};
    let salt = b"openvalut-pam-totp-v1";
    let mut hasher = Sha256::new();
    hasher.update(machine_id.as_bytes());
    hasher.update(salt);
    let mut out = [0u8; 32];
    out.copy_from_slice(&hasher.finalize());
    out
}

/// Encrypts the TOTP secret with a key derived from the machine-id and writes
/// it to `~/.openvalut/totp/<machine-id>.enc`.
pub fn write_encrypted_totp(secret: &str) -> Result<PathBuf, String> {
    let mid = machine_id().ok_or("无法读取 /etc/machine-id")?;
    let path = totp_path().ok_or("无法确定主目录")?;
    fs::create_dir_all(path.parent().unwrap()).map_err(|e| format!("无法创建目录：{e}"))?;

    let key = derive_key(&mid);
    let cipher = Aes256Gcm::new_from_slice(&key).map_err(|e| format!("密钥初始化失败：{e}"))?;
    let nonce_bytes: [u8; 12] = rand::random();
    let nonce = Nonce::from_slice(&nonce_bytes);
    let ciphertext = cipher
        .encrypt(nonce, secret.as_bytes())
        .map_err(|e| format!("加密失败：{e}"))?;

    let mut out = nonce_bytes.to_vec();
    out.extend_from_slice(&ciphertext);
    fs::write(&path, &out).map_err(|e| format!("写入文件失败：{e}"))?;
    fs::set_permissions(&path, std::os::unix::fs::PermissionsExt::from_mode(0o600))
        .map_err(|e| format!("设置权限失败：{e}"))?;
    Ok(path)
}

/// Reads back the encrypted TOTP secret written by [write_encrypted_totp] for
/// the current machine. Returns `None` when absent or undecryptable, so the
/// caller can fall back to the vault.
pub fn read_encrypted_totp() -> Option<String> {
    let path = totp_path()?;
    let data = fs::read(path).ok()?;
    if data.len() <= 12 {
        return None;
    }
    let mid = machine_id()?;
    let key = derive_key(&mid);
    let cipher = Aes256Gcm::new_from_slice(&key).ok()?;
    let (nonce, ciphertext) = data.split_at(12);
    let secret = cipher
        .decrypt(Nonce::from_slice(nonce), ciphertext)
        .ok()?;
    String::from_utf8(secret).ok()
}
