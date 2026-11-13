//! Shared application state: the open vault, recents, and settings.

use std::collections::HashMap;
use std::fs;
use std::path::PathBuf;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Mutex, RwLock};

use openvalut_core::{Vault, VaultKey};
use serde::{Deserialize, Serialize};

use crate::services::cloud::{self, CloudClient};
use crate::services::row_store::{self, DecodedRow};

/// Legacy blob metadata for cloud vaults without rows yet.
pub struct CloudBlobMeta {
    pub name: String,
    pub base_updated_at: i64,
}

/// Where the open vault lives and how it is persisted.
pub enum VaultSource {
    Local {
        path: PathBuf,
    },
    Cloud {
        client: Box<CloudClient>,
        vault_id: String,
        /// Argon2id key derived from the master password + vault id.
        key: [u8; 32],
        /// Last-synced server rows, the diff baseline for the next save.
        synced: Mutex<HashMap<String, DecodedRow>>,
        /// Set for legacy blob-only vaults; then saves update the blob.
        blob: Option<CloudBlobMeta>,
    },
}

impl VaultSource {
    pub fn local_path(&self) -> Option<&std::path::Path> {
        match self {
            VaultSource::Local { path } => Some(path),
            VaultSource::Cloud { .. } => None,
        }
    }
}

/// The currently unlocked vault plus the key needed to save it.
pub struct VaultHandle {
    pub vault: Mutex<Vault>,
    pub key: VaultKey,
    pub source: VaultSource,
    pub dirty: AtomicBool,
}

impl VaultHandle {
    pub fn mark_dirty(&self) {
        self.dirty.store(true, Ordering::Release);
    }

    /// Identifier shown to the host bridge and the UI.
    pub fn id_string(&self) -> String {
        match &self.source {
            VaultSource::Local { path } => path.to_string_lossy().to_string(),
            VaultSource::Cloud { vault_id, .. } => vault_id.clone(),
        }
    }

    /// True if `id` refers to this vault (path or database name).
    pub fn matches(&self, id: &str) -> bool {
        if self.id_string() == id {
            return true;
        }
        let vault = self.vault.lock().unwrap();
        vault.name().unwrap_or_default() == id
    }

    /// Serializes and persists the vault: writes the KDBX file for local
    /// vaults, or syncs the changed rows (legacy: the blob) to the cloud.
    pub fn persist(&self) -> Result<(), String> {
        match &self.source {
            VaultSource::Local { path } => {
                let vault = self.vault.lock().unwrap();
                let bytes = vault
                    .save(&self.key)
                    .map_err(|e| format!("保存失败: {e}"))?;
                fs::write(path, bytes).map_err(|e| format!("写入密码库文件失败: {e}"))?;
                Ok(())
            }
            VaultSource::Cloud {
                client,
                vault_id,
                key,
                synced,
                blob,
            } => {
                let vault = self.vault.lock().unwrap();
                if let Some(blob) = blob {
                    let bytes = vault
                        .save(&self.key)
                        .map_err(|e| format!("保存失败: {e}"))?;
                    let (nonce, ciphertext) = cloud::encrypt_blob(key, &bytes)?;
                    client
                        .update_vault(
                            vault_id,
                            &blob.name,
                            &nonce,
                            &ciphertext,
                            blob.base_updated_at,
                        )
                        .map_err(|e| format!("写入云库失败（可能是并发冲突）：{e}"))?;
                    return Ok(());
                }
                let (upserts, deletes) =
                    row_store::diff_entries(vault.database(), key, &synced.lock().unwrap())?;
                if upserts.is_empty() && deletes.is_empty() {
                    return Ok(());
                }
                let (upserted, conflicts) = client
                    .sync_entries(vault_id, &upserts, &deletes)
                    .map_err(|e| format!("写入云库失败：{e}"))?;
                let mut snapshot = row_store::current_rows(vault.database());
                for (uuid, updated_at) in upserted {
                    if let Some(row) = snapshot.get_mut(&uuid) {
                        row.updated_at = updated_at;
                    }
                }
                *synced.lock().unwrap() = snapshot;
                if !conflicts.is_empty() {
                    return Err(format!(
                        "{} 行因并发冲突未写入，将在下次保存时重试",
                        conflicts.len()
                    ));
                }
                Ok(())
            }
        }
    }
}

#[derive(Serialize, Deserialize, Clone)]
pub struct RecentFile {
    pub path: String,
    pub name: String,
    pub last_opened_at: String,
}

#[derive(Serialize, Deserialize, Clone)]
pub struct Settings {
    pub theme: String,
    pub language: String,
    pub clipboard_clear_seconds: u64,
    /// The OS autostart entry is written by `settings_set`, never by the
    /// frontend, so the stored path always matches the running executable.
    #[serde(default)]
    pub autostart: bool,
    /// Days a remembered unlock key stays usable. 0 = always type the master
    /// password, and every remembered key is dropped.
    #[serde(default)]
    pub remember_unlock_days: u32,
    /// Close button: "hide" to tray, "minimize" to taskbar, or "exit".
    #[serde(default = "default_close_action")]
    pub close_action: String,
    /// Web content scale in percent. GTK only honours an integer surface scale,
    /// so a fractionally scaled screen (Hyprland at 1.6 with GDK_SCALE=2,
    /// Windows at 150%) renders this app 2x and lets the compositor resample it
    /// down: right pixels, wrong size, and no way to fix it from inside the app
    /// except by zooming the content back. 0 = auto, which is the value startup
    /// computes from the monitor scale and GDK_SCALE (80% here); any other
    /// number is the user's own choice and wins.
    #[serde(default = "default_ui_zoom")]
    pub ui_zoom: u32,
}

fn default_close_action() -> String {
    "hide".to_string()
}

fn default_ui_zoom() -> u32 {
    0
}

impl Default for Settings {
    fn default() -> Self {
        Self {
            theme: "dark".into(),
            language: "zh-CN".into(),
            clipboard_clear_seconds: 45,
            autostart: false,
            remember_unlock_days: 0,
            close_action: default_close_action(),
            ui_zoom: default_ui_zoom(),
        }
    }
}

pub struct AppState {
    pub vault: RwLock<Option<VaultHandle>>,
    pub recents: Mutex<Vec<RecentFile>>,
    pub settings: Mutex<Settings>,
    pub config_dir: PathBuf,
    /// One in-flight QR scan-login session (RSA key + poll secret stay in
    /// memory only; a new session replaces the previous one).
    pub scan: Mutex<Option<ScanSession>>,
    /// Bumped whenever the in-memory vault is opened, locked, or mutated.
    /// The host bridge exposes it as the session generation and uses it to
    /// invalidate its vault snapshots.
    pub(crate) content_version: std::sync::atomic::AtomicU64,
    /// Set once the tray icon is on screen. Without one, hiding the window on
    /// close would strand the app (no way back), so the close button falls back
    /// to quitting. Wayland compositors without a StatusNotifier host hit this.
    pub tray_available: std::sync::atomic::AtomicBool,
}

/// An active scan-login session bound to the server it was created on.
pub struct ScanSession {
    pub login: cloud::ScanLogin,
    pub base: String,
}

impl AppState {
    pub fn load() -> Result<Self, String> {
        let config_dir =
            config_dir().ok_or_else(|| "cannot determine config directory".to_string())?;
        Self::load_in(config_dir)
    }

    pub fn load_in(config_dir: PathBuf) -> Result<Self, String> {
        fs::create_dir_all(&config_dir).map_err(|e| e.to_string())?;

        let recents = read_json(&config_dir.join("desktop-recents.json")).unwrap_or_default();
        let settings = read_json(&config_dir.join("desktop-settings.json")).unwrap_or_default();

        Ok(Self {
            vault: RwLock::new(None),
            recents: Mutex::new(recents),
            settings: Mutex::new(settings),
            config_dir,
            scan: Mutex::new(None),
            content_version: std::sync::atomic::AtomicU64::new(0),
            tray_available: std::sync::atomic::AtomicBool::new(false),
        })
    }

    pub fn touch(&self) {
        self.content_version.fetch_add(1, Ordering::Release);
    }

    pub fn content_version(&self) -> u64 {
        self.content_version.load(Ordering::Acquire)
    }

    pub fn persist_recents(&self) {
        let recents = self.recents.lock().unwrap().clone();
        write_json(&self.config_dir.join("desktop-recents.json"), &recents);
    }

    pub fn persist_settings(&self) {
        let settings = self.settings.lock().unwrap().clone();
        write_json(&self.config_dir.join("desktop-settings.json"), &settings);
    }

    pub fn add_recent(&self, path: &str, name: &str) {
        let mut recents = self.recents.lock().unwrap();
        recents.retain(|r| r.path != path);
        recents.insert(
            0,
            RecentFile {
                path: path.to_string(),
                name: name.to_string(),
                last_opened_at: chrono::Local::now().to_rfc3339(),
            },
        );
        recents.truncate(12);
        self.persist_recents();
    }
}

/// Same config directory the Flutter client and `openvalut-host` use
/// (`~/.config/openvalut` on Linux), so recents and bridge files coexist.
pub fn config_dir() -> Option<PathBuf> {
    dirs::config_dir().map(|d| d.join("openvalut"))
}

fn read_json<T: Default + for<'de> Deserialize<'de>>(path: &PathBuf) -> Option<T> {
    let text = fs::read_to_string(path).ok()?;
    serde_json::from_str(&text).ok()
}

fn write_json<T: Serialize>(path: &PathBuf, value: &T) {
    if let Ok(text) = serde_json::to_string_pretty(value) {
        let _ = fs::write(path, text);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// A settings file written by an older build only had theme, language and
    /// clipboard; the new fields must arrive as defaults rather than making the
    /// whole load fail.
    #[test]
    fn legacy_settings_file_gains_defaults() {
        let dir = tempfile::tempdir().unwrap();
        fs::write(
            dir.path().join("desktop-settings.json"),
            r#"{"theme":"light","language":"zh-CN","clipboard_clear_seconds":30}"#,
        )
        .unwrap();
        let state = AppState::load_in(dir.path().to_path_buf()).unwrap();
        let settings = state.settings.lock().unwrap();
        assert_eq!(settings.theme, "light");
        assert_eq!(settings.clipboard_clear_seconds, 30);
        assert!(!settings.autostart);
        assert_eq!(settings.remember_unlock_days, 0);
        assert_eq!(settings.close_action, "hide");
        assert_eq!(settings.ui_zoom, 0);
    }

    /// The frontend replaces the whole struct to change one field, so a field
    /// the TS type forgot is not merely unread - it is written back as its
    /// default, silently clearing a user's autostart flag or remembered-unlock
    /// window. serde cannot catch that (a missing key is legal), so the two
    /// declarations of the same contract are compared here.
    #[test]
    fn settings_fields_are_declared_in_the_frontend_type() {
        let api = std::fs::read_to_string(format!("{}/ui/src/api.ts", env!("CARGO_MANIFEST_DIR")))
            .expect("ui/src/api.ts - the desktop settings contract lives there");
        let body = api
            .split("export interface Settings {")
            .nth(1)
            .and_then(|rest| rest.split('}').next())
            .expect("an `export interface Settings {` block in ui/src/api.ts");
        let value = serde_json::to_value(Settings::default()).unwrap();
        let rust_keys: Vec<&str> = value
            .as_object()
            .unwrap()
            .keys()
            .map(String::as_str)
            .collect();
        for key in &rust_keys {
            assert!(
                body.contains(&format!("{key}:")),
                "Settings.{key} is missing from the frontend interface, so the next \
                 settings save would rewrite it as a default"
            );
        }
        // The other direction: a field only the frontend declares is dropped on
        // deserialize, so that setting reverts to its default on the next start
        // and no error is ever shown.
        let mut ts_keys: Vec<&str> = body
            .lines()
            .map(|line| line.trim())
            .filter(|line| !line.starts_with("//"))
            .filter_map(|line| line.split_once([':', '?']))
            .map(|(name, _)| name.trim())
            .filter(|name| {
                name.chars()
                    .all(|c| c.is_lowercase() || c == '_' || c.is_ascii_digit())
            })
            .collect();
        ts_keys.sort_unstable();
        let mut missing: Vec<&str> = Vec::new();
        for name in ts_keys {
            if !rust_keys.contains(&name) {
                missing.push(name);
            }
        }
        assert!(
            missing.is_empty(),
            "ui/src/api.ts declares {:?} but Settings has no such field, so it would be \
             silently dropped on save",
            missing
        );
    }

    /// The frontend replaces the whole struct to change one field, so a saved
    /// setting has to survive being read back.
    #[test]
    fn saved_settings_round_trip() {
        let dir = tempfile::tempdir().unwrap();
        let first = AppState::load_in(dir.path().to_path_buf()).unwrap();
        {
            let mut settings = first.settings.lock().unwrap();
            settings.autostart = true;
            settings.remember_unlock_days = 14;
            settings.close_action = "exit".to_string();
            settings.ui_zoom = 80;
        }
        first.persist_settings();

        let second = AppState::load_in(dir.path().to_path_buf()).unwrap();
        let settings = second.settings.lock().unwrap();
        assert!(settings.autostart);
        assert_eq!(settings.remember_unlock_days, 14);
        assert_eq!(settings.close_action, "exit");
        assert_eq!(settings.ui_zoom, 80);
    }
}
