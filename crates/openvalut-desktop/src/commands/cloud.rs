//! OpenValut Cloud unlock: logs in with the account saved by `openvalut-cli
//! auth login` (email + Secret Key from the OS keychain), downloads the vault
//! rows, and opens the vault in memory. Saves sync changed rows back.

use std::collections::HashMap;
use std::fs;
use std::path::Path;
use std::sync::Mutex;

use openvalut_core::{Vault, VaultKey};
use serde::{Deserialize, Serialize};
use tauri::{AppHandle, Emitter, State};

use crate::services::cloud::{self, CloudClient, CloudError, ScanPoll};
use crate::services::row_store::{self, DecodedRow};
use crate::state::{AppState, CloudBlobMeta, ScanSession, VaultHandle, VaultSource};

/// Same keychain service/secret the CLI uses, so one `auth login` covers both.
const KEYCHAIN_SERVICE: &str = "openvalut-cli";
const KEYCHAIN_CLOUD_SECRET_KEY: &str = "cloud-secret-key";

#[derive(Debug, Deserialize)]
struct CloudAccountFile {
    server: String,
    email: String,
}

#[derive(Serialize, Clone)]
pub struct CloudAccountStatus {
    pub configured: bool,
    pub email: Option<String>,
    pub server: Option<String>,
}

#[derive(Serialize, Clone)]
pub struct CloudVaultInfo {
    pub id: String,
    pub name: String,
}

/// Candidate locations for `cloud-account.json`: the Flutter/desktop config
/// dir (`dirs::config_dir`), and the CLI's XDG-style `~/.config/openvalut`
/// (on Windows these are different directories; on Linux they coincide).
fn account_file_candidates(config_dir: &Path) -> Vec<std::path::PathBuf> {
    let mut out = vec![config_dir.join("data").join("cloud-account.json")];
    if let Some(home) = std::env::var_os("HOME").or_else(|| std::env::var_os("USERPROFILE")) {
        out.push(
            std::path::PathBuf::from(home)
                .join(".config")
                .join("openvalut")
                .join("data")
                .join("cloud-account.json"),
        );
    }
    out
}

fn read_account_file(config_dir: &Path) -> Option<CloudAccountFile> {
    for path in account_file_candidates(config_dir) {
        if let Ok(text) = fs::read_to_string(&path) {
            if let Ok(account) = serde_json::from_str::<CloudAccountFile>(&text) {
                return Some(account);
            }
        }
    }
    None
}

/// How long the UI will wait on the OS keychain before calling it unusable.
const SECRET_READ_TIMEOUT: std::time::Duration = std::time::Duration::from_secs(4);

/// Run `work` on a helper thread and give up after `timeout`. `None` means it is
/// still running.
fn bounded<T: Send + 'static>(
    work: impl FnOnce() -> T + Send + 'static,
    timeout: std::time::Duration,
) -> Option<T> {
    let (tx, rx) = std::sync::mpsc::channel();
    std::thread::spawn(move || {
        let _ = tx.send(work());
    });
    rx.recv_timeout(timeout).ok()
}

/// Outcome of one keychain read, kept separate from `Result` so a stall can be
/// reported differently from an empty or broken store.
enum SecretRead {
    Found(String),
    Missing,
    Failed(String),
    Stalled,
}

/// The OS keychain is a synchronous cross-process call with no deadline of its
/// own, and the command that reads it runs on Tauri's main thread. A Secret
/// Service that is not running — or that is waiting for a prompt nobody can see —
/// would freeze the window on the lock screen's first paint, which is
/// indistinguishable from "clicking does nothing". Bound the wait and turn a
/// stall into an ordinary error message.
fn read_cloud_secret(timeout: std::time::Duration) -> SecretRead {
    match bounded(
        move || {
            let entry = keyring::Entry::new(KEYCHAIN_SERVICE, KEYCHAIN_CLOUD_SECRET_KEY)
                .map_err(|e| format!("无法打开系统钥匙串: {e}"))?;
            match entry.get_password() {
                Ok(value) => Ok(value),
                Err(keyring::Error::NoEntry) => Err(NO_ENTRY.to_string()),
                Err(e) => Err(format!("无法从系统钥匙串读取云账号 Secret Key: {e}")),
            }
        },
        timeout,
    ) {
        None => SecretRead::Stalled,
        Some(Err(msg)) if msg == NO_ENTRY => SecretRead::Missing,
        Some(Err(msg)) => SecretRead::Failed(msg),
        Some(Ok(value)) => SecretRead::Found(value),
    }
}

const NO_ENTRY: &str = "\u{0}no-entry";

fn resolve_account(config_dir: &Path) -> Result<(String, String, String), String> {
    let account = read_account_file(config_dir).ok_or_else(|| {
        "尚未登录云账号：请先运行 `openvalut-cli auth login` 或在手机端登录".to_string()
    })?;
    let secret_key = match read_cloud_secret(SECRET_READ_TIMEOUT) {
        SecretRead::Found(key) => key,
        SecretRead::Missing => return Err(format!(
            "账号 {} 已保存，但系统钥匙串里没有它的 Secret Key，请重新登录一次",
            account.email
        )),
        SecretRead::Failed(msg) => return Err(msg),
        SecretRead::Stalled => return Err(format!(
            "系统钥匙串 {} 秒没有响应，云密码库暂时打不开；本地库不受影响，可以稍后重试",
            SECRET_READ_TIMEOUT.as_secs()
        )),
    };
    Ok((account.server, account.email, secret_key))
}

const DEFAULT_SERVER: &str = "https://openvalut.example.com";

/// Server status codes mapped to the Flutter login screen's wording.
fn map_auth_error(e: CloudError) -> String {
    match e.status {
        Some(401) => "邮箱或 Secret Key 不正确，请检查后重试。".to_string(),
        Some(409) => "该邮箱已注册，请直接登录。".to_string(),
        None => format!("无法连接 OpenValut Cloud 服务：{}", e.message),
        Some(_) => e.message,
    }
}

/// Persists a verified account: Secret Key to the OS keychain, server+email to
/// `cloud-account.json` — the same storage `openvalut-cli auth login` writes.
fn persist_account(
    state: &AppState,
    server: &str,
    email: &str,
    secret_key: &str,
) -> Result<(), String> {
    let entry = keyring::Entry::new(KEYCHAIN_SERVICE, KEYCHAIN_CLOUD_SECRET_KEY)
        .map_err(|e| format!("无法打开系统钥匙串: {e}"))?;
    entry
        .set_password(secret_key)
        .map_err(|e| format!("无法写入系统钥匙串: {e}"))?;
    // A store that accepts the write but cannot hand the secret back later is
    // worse than one that errors out: the login would look remembered and then
    // fail on the next start. Confirm the round-trip instead.
    confirm_round_trip(entry.get_password(), secret_key)?;

    let data_dir = state.config_dir.join("data");
    fs::create_dir_all(&data_dir).map_err(|e| e.to_string())?;
    let json = serde_json::json!({ "server": server, "email": email });
    let path = data_dir.join("cloud-account.json");
    fs::write(&path, serde_json::to_string_pretty(&json).unwrap())
        .map_err(|e| format!("无法写入 {}: {e}", path.display()))?;
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let _ = fs::set_permissions(&path, fs::Permissions::from_mode(0o600));
    }
    Ok(())
}

/// Refuse a login the keychain cannot actually hand back later. `NoEntry` right
/// after a successful `set_password` is the signature of a store that swallows
/// writes — which is what the Windows build did before `windows-native` was
/// enabled — so it has to fail here rather than let `cloud-account.json` be
/// written and the next start fall back to the login form.
fn confirm_round_trip(read_back: Result<String, keyring::Error>, secret_key: &str) -> Result<(), String> {
    match read_back.as_deref() {
        Ok(stored) if stored == secret_key => Ok(()),
        Ok(_) => Err("系统钥匙串读回的 Secret Key 与本次登录不一致，不会被记住".to_string()),
        Err(e) => Err(format!("系统钥匙串未能保存 Secret Key: {e}")),
    }
}

/// Shared body of `cloud_open`: picks the vault, decrypts rows (or the legacy
/// blob), installs the handle, and announces the unlock.
pub(crate) fn open_cloud_vault(
    app: &AppHandle,
    state: &AppState,
    client: CloudClient,
    password: &str,
    vault_id: Option<String>,
) -> Result<crate::commands::vault::VaultMeta, String> {
    let meta_key = cloud::derive_meta_key(password, client.user_id())?;
    let vaults = client.list_vaults_with_key(Some(&meta_key))?;
    let target = match vault_id {
        Some(id) => vaults
            .into_iter()
            .find(|v| v.id == id || v.name == id)
            .ok_or_else(|| format!("未找到云密码库：{id}"))?,
        None => vaults
            .into_iter()
            .next()
            .ok_or_else(|| "账号下还没有云密码库".to_string())?,
    };
    let vault_id = target.id;
    let vault_name = target.name;
    let key = cloud::derive_key(password, &vault_id)?;
    let rows = client.list_rows(&vault_id)?;

    let (vault, synced, blob) = if rows.is_empty() {
        let full = client.get_vault(&vault_id)?;
        let plain = cloud::decrypt_blob(&key, &full.nonce, &full.ciphertext)?;
        let vault = Vault::open(&plain, &VaultKey::with_password(password))
            .map_err(|e| format!("解锁失败: {e}"))?;
        let blob = CloudBlobMeta {
            name: full.name,
            base_updated_at: full.updated_at.unwrap_or(0),
        };
        (vault, HashMap::new(), Some(blob))
    } else {
        match row_store::database_from_rows(&vault_name, &rows, &key) {
            Ok((db, synced)) => (Vault::from_database(db), synced, None),
            Err(row_err) => {
                // Mirror the CLI / app: rows may be encrypted under a
                // remembered auto-unlock key instead of the typed master.
                // When the legacy blob opens with the typed master, rebuild
                // from it and rewrite the rows under the current key on save.
                let full = client.get_vault(&vault_id)?;
                let plain =
                    cloud::decrypt_blob(&key, &full.nonce, &full.ciphertext).map_err(|e| {
                        format!("行数据无法用当前主密码解密，且旧 blob 也打不开（{row_err}；{e}）")
                    })?;
                let vault = Vault::open(&plain, &VaultKey::with_password(password))
                    .map_err(|e| format!("解锁失败: {e}"))?;
                let synced: HashMap<String, DecodedRow> = rows
                    .iter()
                    .map(|r| {
                        (
                            r.uuid.clone(),
                            DecodedRow {
                                group_path: String::new(),
                                fields: HashMap::new(),
                                protected: Vec::new(),
                                icon: None,
                                updated_at: r.updated_at,
                            },
                        )
                    })
                    .collect();
                (vault, synced, None)
            }
        }
    };

    let user_id = client.user_id().to_string();
    let meta = {
        let mut guard = state.vault.write().unwrap();
        *guard = Some(VaultHandle {
            vault: std::sync::Mutex::new(vault),
            key: VaultKey::with_password(password),
            source: VaultSource::Cloud {
                client,
                vault_id: vault_id.clone(),
                key,
                synced: Mutex::new(synced),
                blob,
            },
            dirty: std::sync::atomic::AtomicBool::new(false),
        });
        drop(guard);
        state.touch();
        crate::commands::vault::vault_status_inner(state)?
    };
    // A cloud vault is remembered by its master password: the row key is
    // derived from that password plus the vault id, and the legacy-blob path
    // needs the password to unlock at all.
    crate::commands::remembered::remember_unlock(
        state,
        crate::services::remembered::RememberInput {
            kind: crate::services::remembered::Kind::Cloud,
            id: vault_id,
            name: vault_name,
            master_password: password.to_string(),
            keyfile_path: None,
            account_email: read_account_file(&state.config_dir).map(|a| a.email),
            account_user_id: Some(user_id),
        },
    );
    let _ = app.emit("vault:unlocked", &meta);
    Ok(meta)
}

/// Saves the cloud account for the first time (or updates it): verifies the
/// credentials with a real login first, then persists server+email to
/// `cloud-account.json` and the Secret Key to the OS keychain — the same
/// storage `openvalut-cli auth login` writes, so the CLI sees it too.
#[tauri::command]
pub fn cloud_account_save(
    state: State<'_, AppState>,
    email: String,
    secret_key: String,
    server: Option<String>,
) -> Result<CloudAccountStatus, String> {
    let email = email.trim().to_string();
    let secret_key = secret_key.trim().to_string();
    if email.is_empty() || secret_key.is_empty() {
        return Err("邮箱和 Secret Key 不能为空".to_string());
    }
    let server = cloud::normalize_server(&server.unwrap_or_default(), DEFAULT_SERVER);

    // Validate before persisting: a typo'd key must not clobber an existing
    // account, and the user should see the failure immediately.
    CloudClient::login(&server, &email, &secret_key)?;
    persist_account(&state, &server, &email, &secret_key)?;

    Ok(CloudAccountStatus {
        configured: true,
        email: Some(email),
        server: Some(server),
    })
}

#[tauri::command]
pub fn cloud_account_status(state: State<'_, AppState>) -> Result<CloudAccountStatus, String> {
    let account = read_account_file(&state.config_dir);
    Ok(match account {
        Some(a) => CloudAccountStatus {
            configured: true,
            email: Some(a.email),
            server: Some(a.server),
        },
        None => CloudAccountStatus {
            configured: false,
            email: None,
            server: None,
        },
    })
}

/// Lists the account's vaults (names only; no master password needed).
#[tauri::command]
pub fn cloud_vaults(state: State<'_, AppState>) -> Result<Vec<CloudVaultInfo>, String> {
    let (client, _) = account_client(&state)?;
    Ok(client
        .list_vaults()?
        .into_iter()
        .map(|v| CloudVaultInfo {
            id: v.id,
            name: v.name,
        })
        .collect())
}

/// Logs in with the saved account and returns `(client, email)`.
pub(crate) fn account_client(state: &AppState) -> Result<(CloudClient, String), String> {
    let (server, email, secret_key) = resolve_account(&state.config_dir)?;
    let client = CloudClient::login(&server, &email, &secret_key)?;
    Ok((client, email))
}

/// Unlocks a cloud vault with the saved account: login, then `open_cloud_vault`.
#[tauri::command]
pub fn cloud_open(
    app: AppHandle,
    state: State<'_, AppState>,
    password: String,
    vault_id: Option<String>,
) -> Result<crate::commands::vault::VaultMeta, String> {
    let (client, _) = account_client(&state)?;
    open_cloud_vault(&app, &state, client, &password, vault_id)
}

/// One-step cloud login from the startup screen: verify email + Secret Key,
/// save the account on success, then unlock with the master password. A wrong
/// master password leaves the account saved (like the Flutter app: the login
/// and the unlock are separate failures).
#[tauri::command]
pub fn cloud_login(
    app: AppHandle,
    state: State<'_, AppState>,
    email: String,
    secret_key: String,
    server: Option<String>,
    master_password: String,
    vault_id: Option<String>,
) -> Result<crate::commands::vault::VaultMeta, String> {
    let email = email.trim().to_lowercase();
    if email.is_empty() || secret_key.trim().is_empty() {
        return Err("请输入邮箱和 Secret Key".to_string());
    }
    let server = cloud::normalize_server(&server.unwrap_or_default(), DEFAULT_SERVER);
    let client = CloudClient::try_login(&server, &email, &secret_key).map_err(map_auth_error)?;
    persist_account(&state, &server, &email, secret_key.trim())?;
    open_cloud_vault(&app, &state, client, &master_password, vault_id)
}

#[derive(Serialize)]
pub struct RegisterResult {
    pub secret_key: String,
    pub meta: crate::commands::vault::VaultMeta,
}

/// Registers a new cloud account and creates its first vault locally, then
/// uploads the encrypted blob (mirrors the Flutter sign-up flow). The raw
/// 32-hex Secret Key is returned for the save-reminder dialog.
#[tauri::command]
pub fn cloud_register(
    app: AppHandle,
    state: State<'_, AppState>,
    email: String,
    server: Option<String>,
    name: String,
    master: String,
) -> Result<RegisterResult, String> {
    let email = email.trim().to_lowercase();
    if email.is_empty() {
        return Err("请输入邮箱".to_string());
    }
    let server = cloud::normalize_server(&server.unwrap_or_default(), DEFAULT_SERVER);
    let (client, secret_key) = CloudClient::register(&server, &email).map_err(map_auth_error)?;

    let name = name.trim().to_string();
    let name = if name.is_empty() {
        "OpenValut".to_string()
    } else {
        name
    };
    let meta_key = cloud::derive_meta_key(&master, &secret_key)?;
    let vault_id = cloud::new_vault_id();
    let key = cloud::derive_key(&master, &vault_id)?;
    let vault = Vault::create_new(&name).map_err(|e| format!("创建密码库失败: {e}"))?;
    let bytes = vault
        .save(&VaultKey::with_password(&master))
        .map_err(|e| format!("创建密码库失败: {e}"))?;
    let (nonce, ciphertext) = cloud::encrypt_blob(&key, &bytes)?;
    let created = client
        .create_vault(&vault_id, &name, &meta_key, &nonce, &ciphertext)
        .map_err(map_auth_error)?;

    persist_account(&state, &server, &email, &secret_key)?;

    let meta = {
        let mut guard = state.vault.write().unwrap();
        *guard = Some(VaultHandle {
            vault: std::sync::Mutex::new(vault),
            key: VaultKey::with_password(&master),
            source: VaultSource::Cloud {
                client,
                vault_id,
                key,
                synced: Mutex::new(HashMap::new()),
                blob: Some(CloudBlobMeta {
                    name: created.name,
                    base_updated_at: created.updated_at.unwrap_or(0),
                }),
            },
            dirty: std::sync::atomic::AtomicBool::new(false),
        });
        drop(guard);
        state.touch();
        crate::commands::vault::vault_status_inner(&state)?
    };
    let _ = app.emit("vault:unlocked", &meta);
    Ok(RegisterResult { secret_key, meta })
}

#[derive(Serialize)]
pub struct ScanStartInfo {
    pub session_id: String,
    pub qr_content: String,
    pub qr_svg: String,
}

/// Creates a QR scan-login session; replaces any session already in flight.
#[tauri::command]
pub fn scan_start(
    state: State<'_, AppState>,
    server: Option<String>,
) -> Result<ScanStartInfo, String> {
    let base = cloud::normalize_server(&server.unwrap_or_default(), DEFAULT_SERVER);
    let login = cloud::ScanLogin::start(&base)?;
    let info = ScanStartInfo {
        session_id: login.session_id().to_string(),
        qr_content: login.qr_content().to_string(),
        qr_svg: login.qr_svg()?,
    };
    *state.scan.lock().unwrap() = Some(ScanSession { login, base });
    Ok(info)
}

#[derive(Serialize)]
pub struct ScanPollInfo {
    /// "pending" | "expired" | "confirmed" | "error"
    pub status: String,
    pub unlocked: bool,
    /// Confirmed but the phone did not relay the master password (or it failed
    /// to unlock): the UI should ask for it and call `cloud_open`.
    pub needs_master: bool,
    pub message: Option<String>,
}

/// One poll tick, driven by the UI every 2 s. A `confirmed` response is
/// consumed here: the account is persisted and, when the phone relayed the
/// master password, the vault is unlocked immediately.
#[tauri::command]
pub fn scan_poll(
    app: AppHandle,
    state: State<'_, AppState>,
    session_id: String,
) -> Result<ScanPollInfo, String> {
    let poll = {
        let guard = state.scan.lock().unwrap();
        match guard.as_ref() {
            Some(session) if session.login.session_id() == session_id => session.login.poll_once(),
            Some(_) => {
                return Ok(ScanPollInfo {
                    status: "expired".into(),
                    unlocked: false,
                    needs_master: false,
                    message: Some("扫码会话已被新的二维码取代".into()),
                })
            }
            None => {
                return Ok(ScanPollInfo {
                    status: "expired".into(),
                    unlocked: false,
                    needs_master: false,
                    message: None,
                })
            }
        }
    };
    match poll? {
        ScanPoll::Pending => Ok(ScanPollInfo {
            status: "pending".into(),
            unlocked: false,
            needs_master: false,
            message: None,
        }),
        ScanPoll::Expired => {
            *state.scan.lock().unwrap() = None;
            Ok(ScanPollInfo {
                status: "expired".into(),
                unlocked: false,
                needs_master: false,
                message: Some("二维码已过期，请重新生成".into()),
            })
        }
        ScanPoll::Confirmed {
            token,
            username,
            user_id,
            master_password,
        } => {
            let base = state
                .scan
                .lock()
                .unwrap()
                .take()
                .map(|s| s.base)
                .unwrap_or_else(|| DEFAULT_SERVER.to_string());
            let secret_key = match user_id {
                Some(id) => id,
                None => CloudClient::fetch_user_id(&base, &token)?,
            };
            persist_account(&state, &base, &username, &secret_key)?;
            let client = CloudClient::from_session(&base, token, secret_key);
            match master_password {
                Some(master) => match open_cloud_vault(&app, &state, client, &master, None) {
                    Ok(_) => Ok(ScanPollInfo {
                        status: "confirmed".into(),
                        unlocked: true,
                        needs_master: false,
                        message: None,
                    }),
                    Err(_) => Ok(ScanPollInfo {
                        status: "confirmed".into(),
                        unlocked: false,
                        needs_master: true,
                        message: Some("手机已授权，但自动解锁失败，请输入主密码".into()),
                    }),
                },
                None => Ok(ScanPollInfo {
                    status: "confirmed".into(),
                    unlocked: false,
                    needs_master: true,
                    message: Some("手机已授权，请输入主密码解锁".into()),
                }),
            }
        }
    }
}

/// Abandons the in-flight scan session.
#[tauri::command]
pub fn scan_cancel(state: State<'_, AppState>) -> Result<(), String> {
    *state.scan.lock().unwrap() = None;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::bounded;
    use super::confirm_round_trip;
    use std::time::Duration;

    /// The lock screen reads the keychain while it is still mounting, on the main
    /// thread. A store that answers costs nothing extra; a store that never
    /// answers must cost the caller the deadline, not the whole window.
    #[test]
    fn a_stalled_keychain_read_is_cut_off_at_the_deadline() {
        assert_eq!(bounded(|| "answered", Duration::from_secs(1)), Some("answered"));
        assert_eq!(
            bounded(
                || {
                    std::thread::sleep(Duration::from_secs(5));
                    "too late"
                },
                Duration::from_millis(50)
            ),
            None
        );
    }

    const SECRET: &str = "sk-live-abcdef";

    /// The precise shape of the bug this whole change exists for: `set_password`
    /// answered `Ok` because the mock backend wrote into process memory, and the
    /// next start read nothing back. Accepting that would still have written
    /// `cloud-account.json`, so the login looked remembered until it wasn't.
    #[test]
    fn a_store_that_swallows_the_write_is_reported_as_a_failure() {
        let error = confirm_round_trip(Err(keyring::Error::NoEntry), SECRET)
            .expect_err("a secret the store cannot return was never stored");
        assert!(error.contains("未能保存"), "got: {error}");
    }

    #[test]
    fn a_round_trip_only_counts_when_the_same_secret_comes_back() {
        assert!(confirm_round_trip(Ok(SECRET.to_string()), SECRET).is_ok());
        let error = confirm_round_trip(Ok("sk-someone-elses".to_string()), SECRET)
            .expect_err("a different secret is not this login");
        assert!(error.contains("不一致"), "got: {error}");
    }

    #[test]
    fn a_platform_error_is_not_reported_as_a_saved_secret() {
        let locked = keyring::Error::PlatformFailure(Box::new(std::io::Error::other("locked")));
        let error = confirm_round_trip(Err(locked), SECRET).expect_err("unreachable store");
        assert!(error.contains("未能保存"), "got: {error}");
    }
}
