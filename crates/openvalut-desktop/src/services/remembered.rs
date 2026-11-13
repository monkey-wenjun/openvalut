//! Remembered unlock credentials, the Rust counterpart of the Flutter app's
//! `RememberedUnlockStore` (openvalut/lib/bloc/kdbx_bloc.dart).
//!
//! After a master-password unlock the password itself is kept in the OS keychain
//! so the next start can reopen the vault behind a Windows Hello / polkit check
//! alone. The password is stored rather than the KDF-transformed key on purpose:
//! a vault opened with a transformed key alone is read-only, and Argon2 only has
//! to run once more per unlock.
//!
//! The keychain cannot be enumerated, so a plain JSON index next to the recents
//! file lists what was remembered (names only — secrets stay in the keychain).
//!
//! Entries are also bound to the boot session that wrote them: a PIN is only
//! offered until the machine is shut down, then the master password is required
//! again (see [`crate::services::boot`]).

use std::fs;
use std::path::Path;

use chrono::Utc;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

use crate::services::boot;

/// Same service namespace the CLI uses, so the OS credential list stays tidy.
const SERVICE: &str = "openvalut-cli";
const KEY_PREFIX: &str = "remembered-unlock:";
const INDEX_FILE: &str = "remembered-index.json";
const DAY_MS: i64 = 86_400_000;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Kind {
    Local,
    Cloud,
}

impl Kind {
    fn as_str(self) -> &'static str {
        match self {
            Kind::Local => "local",
            Kind::Cloud => "cloud",
        }
    }
}

/// One row of the on-disk index: what is remembered, without any secret.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct IndexEntry {
    pub tag: String,
    pub kind: Kind,
    pub id: String,
    pub name: String,
    /// The `remember_unlock_days` in effect when this row was written.
    pub days: u32,
    /// Unix milliseconds of the master-password unlock that created it.
    pub saved_at: i64,
    /// The boot session the row was written in. Rows written before this field
    /// existed carry `None` and are never usable again, because a PIN that
    /// survived a reboot is exactly the bug this field prevents.
    #[serde(default)]
    pub boot_id: Option<String>,
}

/// What a caller knows right after unlocking with the master password.
pub struct RememberInput {
    pub kind: Kind,
    pub id: String,
    pub name: String,
    pub master_password: String,
    /// Keyfile beside the password, if the vault was opened with one.
    pub keyfile_path: Option<String>,
    /// Cloud vaults may only be reopened by the account they were saved for.
    pub account_email: Option<String>,
    pub account_user_id: Option<String>,
}

/// The decoded secret behind an index row.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RememberedSecret {
    pub kind: Kind,
    pub id: String,
    pub name: String,
    pub master_password: String,
    pub keyfile_path: Option<String>,
    pub account_email: Option<String>,
    pub account_user_id: Option<String>,
}

/// A remembered vault as offered on the unlock screen.
#[derive(Debug, Clone, Serialize)]
pub struct RememberedSummary {
    pub kind: Kind,
    pub id: String,
    pub name: String,
    /// Whole days left before the entry expires (never negative).
    pub remaining_days: u32,
}

/// The secret half of an entry, kept in the keychain. The index row carries the
/// rest, so the expiry timestamp lives in exactly one place.
#[derive(Default, Serialize, Deserialize)]
struct Payload {
    #[serde(default)]
    id: String,
    #[serde(default, rename = "masterPassword")]
    master_password: Option<String>,
    #[serde(default, rename = "keyfilePath")]
    keyfile_path: Option<String>,
    #[serde(default)]
    email: Option<String>,
    #[serde(default)]
    user_id: Option<String>,
}

/// Minimal secret-store abstraction so the logic is testable without a live
/// keychain (mirrors `openvalut-cli::keychain::KeyStore`).
pub trait SecretStore {
    fn get(&self, key: &str) -> Result<Option<String>, String>;
    fn set(&self, key: &str, value: &str) -> Result<(), String>;
    /// Missing credentials are a success: forgetting is never allowed to fail.
    fn delete(&self, key: &str) -> Result<(), String>;
}

pub struct KeyringStore;

impl SecretStore for KeyringStore {
    fn get(&self, key: &str) -> Result<Option<String>, String> {
        #[cfg(debug_assertions)]
        if let Some(dir) = test_dir() {
            return file_get(&dir, key);
        }
        let entry = keyring::Entry::new(SERVICE, key).map_err(|e| e.to_string())?;
        match entry.get_password() {
            Ok(value) => Ok(Some(value)),
            Err(keyring::Error::NoEntry) => Ok(None),
            Err(e) => Err(format!("无法读取钥匙串 {key}: {e}")),
        }
    }

    fn set(&self, key: &str, value: &str) -> Result<(), String> {
        #[cfg(debug_assertions)]
        if let Some(dir) = test_dir() {
            return file_set(&dir, key, value);
        }
        let entry = keyring::Entry::new(SERVICE, key).map_err(|e| e.to_string())?;
        entry
            .set_password(value)
            .map_err(|e| format!("无法写入钥匙串 {key}: {e}"))
    }

    fn delete(&self, key: &str) -> Result<(), String> {
        #[cfg(debug_assertions)]
        if let Some(dir) = test_dir() {
            let _ = fs::remove_file(dir.join(format!("{key}.secret")));
            return Ok(());
        }
        let entry = keyring::Entry::new(SERVICE, key).map_err(|e| e.to_string())?;
        match entry.delete_credential() {
            Ok(()) | Err(keyring::Error::NoEntry) => Ok(()),
            Err(e) => Err(format!("无法删除钥匙串 {key}: {e}")),
        }
    }
}

/// Tests redirect the store to plaintext files so they never touch the
/// developer's real keychain. Debug builds only.
#[cfg(debug_assertions)]
fn test_dir() -> Option<std::path::PathBuf> {
    std::env::var_os("OPENVALUT_TEST_KEYCHAIN_DIR").map(std::path::PathBuf::from)
}

#[cfg(debug_assertions)]
fn file_get(dir: &Path, key: &str) -> Result<Option<String>, String> {
    match fs::read_to_string(dir.join(format!("{key}.secret"))) {
        Ok(value) => Ok(Some(value)),
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(None),
        Err(e) => Err(format!("无法读取测试钥匙串 {key}: {e}")),
    }
}

#[cfg(debug_assertions)]
fn file_set(dir: &Path, key: &str, value: &str) -> Result<(), String> {
    fs::create_dir_all(dir).map_err(|e| format!("无法创建测试钥匙串目录: {e}"))?;
    fs::write(dir.join(format!("{key}.secret")), value)
        .map_err(|e| format!("无法写入测试钥匙串 {key}: {e}"))
}

pub fn default_store() -> &'static dyn SecretStore {
    &KeyringStore
}

/// Keychain account key for one vault. The vault id is hashed because local ids
/// are full paths: Windows Credential Manager treats `\` as a separator and
/// limits the target name length. The readable id lives in the payload.
fn tag_for(kind: Kind, id: &str) -> String {
    let digest = Sha256::digest(format!("{}:{id}", kind.as_str()).as_bytes());
    hex::encode(&digest[..16])
}

fn key_for_tag(tag: &str) -> String {
    format!("{KEY_PREFIX}{tag}")
}

fn key_for(kind: Kind, id: &str) -> String {
    key_for_tag(&tag_for(kind, id))
}

fn index_path(config_dir: &Path) -> std::path::PathBuf {
    config_dir.join(INDEX_FILE)
}

fn read_index(config_dir: &Path) -> Vec<IndexEntry> {
    let Ok(text) = fs::read_to_string(index_path(config_dir)) else {
        return Vec::new();
    };
    serde_json::from_str(&text).unwrap_or_default()
}

/// Replaces the index with one rename.
///
/// The remember worker writes this from its own thread while the main thread may
/// be reading it to build the unlock screen, and `read_index` treats an
/// unparsable file as empty. So a half-written index would not merely hide the
/// PIN option for a moment: the next read-modify-write would see no rows and
/// rewrite the file without them, orphaning those master passwords in the
/// credential store with nothing left that knows their tag.
fn write_index(config_dir: &Path, entries: &[IndexEntry]) {
    let Ok(text) = serde_json::to_string_pretty(entries) else {
        return;
    };
    let target = index_path(config_dir);
    let temp = target.with_extension("json.tmp");
    if let Err(e) = fs::write(&temp, text).and_then(|()| fs::rename(&temp, &target)) {
        eprintln!("写入记住的凭据索引失败: {e}");
    }
}

fn find_entry(config_dir: &Path, kind: Kind, id: &str) -> Option<IndexEntry> {
    let tag = tag_for(kind, id);
    read_index(config_dir)
        .into_iter()
        .find(|row| row.tag == tag)
}

/// The remembered secret is only good for as long as the shorter of the two
/// windows: the period in effect when it was written, and the current setting.
/// Lowering the setting to 7 days must not leave a 30-day entry usable.
///
/// It is also bound to one boot session: a PIN may skip the master password
/// until the machine is shut down, never across a reboot.
fn usable(entry: &IndexEntry, setting_days: u32, now: i64, current_boot: Option<&str>) -> bool {
    if setting_days == 0 {
        return false;
    }
    if let Some(current) = current_boot {
        if entry.boot_id.as_deref() != Some(current) {
            return false;
        }
    }
    let days = entry.days.min(setting_days).max(1) as i64;
    now - entry.saved_at <= days * DAY_MS
}

fn to_secret(entry: &IndexEntry, payload: &Payload) -> Option<RememberedSecret> {
    Some(RememberedSecret {
        kind: entry.kind,
        id: entry.id.clone(),
        name: entry.name.clone(),
        master_password: payload.master_password.clone()?,
        keyfile_path: payload.keyfile_path.clone(),
        account_email: payload.email.clone(),
        account_user_id: payload.user_id.clone(),
    })
}

fn drop_entry(store: &dyn SecretStore, config_dir: &Path, entry: &IndexEntry) {
    let key = key_for_tag(&entry.tag);
    if let Err(e) = store.delete(&key) {
        eprintln!("清除过期的记住解锁条目失败: {e}");
    }
    let mut entries = read_index(config_dir);
    entries.retain(|row| row.tag != entry.tag);
    write_index(config_dir, &entries);
}

/// Remembers the credentials of a just-unlocked vault. A store that refuses the
/// write is only logged: a broken keychain must not spoil a good unlock.
pub fn remember(
    store: &dyn SecretStore,
    config_dir: &Path,
    input: &RememberInput,
    days: u32,
) -> Result<(), String> {
    remember_in_boot(store, config_dir, input, days, boot::current_boot_id())
}

/// [`remember`] with the boot session supplied, so tests can simulate a restart.
fn remember_in_boot(
    store: &dyn SecretStore,
    config_dir: &Path,
    input: &RememberInput,
    days: u32,
    boot_id: Option<&str>,
) -> Result<(), String> {
    if days == 0 || input.master_password.is_empty() {
        return Ok(());
    }
    let payload = Payload {
        id: input.id.clone(),
        master_password: Some(input.master_password.clone()),
        keyfile_path: input.keyfile_path.clone(),
        email: input
            .account_email
            .clone()
            .filter(|_| input.kind == Kind::Cloud),
        user_id: input
            .account_user_id
            .clone()
            .filter(|_| input.kind == Kind::Cloud),
    };
    let key = key_for(input.kind, &input.id);
    store.set(
        &key,
        &serde_json::to_string(&payload).map_err(|e| e.to_string())?,
    )?;
    // Confirm the write landed. This is not the guard against the mock keyring:
    // that store keeps the value in process memory, so a same-process read-back
    // passes. `checkui.ps1`'s `CredWriteW` marker is. What fails here is a store
    // that answers Ok and drops the value outright, and such an entry must not
    // reach the index - the lock screen would offer a PIN unlock that can never
    // work.
    if store.get(&key)?.is_none() {
        return Err(format!("钥匙串写入后读回为空: {key}"));
    }
    let tag = tag_for(input.kind, &input.id);
    let mut entries = read_index(config_dir);
    entries.retain(|row| row.tag != tag);
    entries.push(IndexEntry {
        tag,
        kind: input.kind,
        id: input.id.clone(),
        name: input.name.clone(),
        days,
        saved_at: Utc::now().timestamp_millis(),
        boot_id: boot_id.map(str::to_owned),
    });
    write_index(config_dir, &entries);
    Ok(())
}

/// Slides the expiry of an existing entry forward after a successful save.
/// A save keeps the master password, so only the timestamp is rewritten, and an
/// entry whose secret has gone is never resurrected.
pub fn touch(
    store: &dyn SecretStore,
    config_dir: &Path,
    kind: Kind,
    id: &str,
) -> Result<(), String> {
    touch_in_boot(store, config_dir, kind, id, boot::current_boot_id())
}

fn touch_in_boot(
    store: &dyn SecretStore,
    config_dir: &Path,
    kind: Kind,
    id: &str,
    boot_id: Option<&str>,
) -> Result<(), String> {
    let Some(entry) = find_entry(config_dir, kind, id) else {
        return Ok(());
    };
    if store.get(&key_for_tag(&entry.tag))?.is_none() {
        return Ok(());
    }
    // A row from an earlier boot is dead; only a fresh `remember` (which needs
    // the typed master password) may bring it back.
    if let Some(current) = boot_id {
        if entry.boot_id.as_deref() != Some(current) {
            return Ok(());
        }
    }
    let now = Utc::now().timestamp_millis();
    let mut entries = read_index(config_dir);
    for row in &mut entries {
        if row.tag == entry.tag {
            row.saved_at = now;
            row.boot_id = boot_id.map(str::to_owned);
        }
    }
    write_index(config_dir, &entries);
    Ok(())
}

/// The usable secret for one vault, pruning anything expired or unreadable.
pub fn secret_for(
    store: &dyn SecretStore,
    config_dir: &Path,
    kind: Kind,
    id: &str,
    setting_days: u32,
) -> Result<Option<RememberedSecret>, String> {
    secret_for_in_boot(
        store,
        config_dir,
        kind,
        id,
        setting_days,
        boot::current_boot_id(),
    )
}

fn secret_for_in_boot(
    store: &dyn SecretStore,
    config_dir: &Path,
    kind: Kind,
    id: &str,
    setting_days: u32,
    boot_id: Option<&str>,
) -> Result<Option<RememberedSecret>, String> {
    let Some(entry) = find_entry(config_dir, kind, id) else {
        return Ok(None);
    };
    let now = Utc::now().timestamp_millis();
    if !usable(&entry, setting_days, now, boot_id) {
        drop_entry(store, config_dir, &entry);
        return Ok(None);
    }
    let payload = match store.get(&key_for(kind, id))? {
        Some(text) => serde_json::from_str::<Payload>(&text).ok(),
        None => None,
    };
    let secret = payload
        .as_ref()
        // The tag is a hash, so a payload for another path can collide with it
        // in principle; never unlock the wrong vault over one.
        .filter(|payload| payload.id == entry.id)
        .and_then(|payload| to_secret(&entry, payload));
    if secret.is_none() {
        drop_entry(store, config_dir, &entry);
    }
    Ok(secret)
}

/// Everything remembered and still usable, oldest expiry last.
pub fn list(config_dir: &Path, setting_days: u32) -> Vec<RememberedSummary> {
    list_in_boot(config_dir, setting_days, boot::current_boot_id())
}

fn list_in_boot(
    config_dir: &Path,
    setting_days: u32,
    boot_id: Option<&str>,
) -> Vec<RememberedSummary> {
    let now = Utc::now().timestamp_millis();
    read_index(config_dir)
        .iter()
        .filter(|row| usable(row, setting_days, now, boot_id))
        .map(|row| {
            let days = row.days.min(setting_days).max(1) as i64;
            let left = (row.saved_at + days * DAY_MS - now).max(0);
            RememberedSummary {
                kind: row.kind,
                id: row.id.clone(),
                name: row.name.clone(),
                remaining_days: ((left + DAY_MS - 1) / DAY_MS) as u32,
            }
        })
        .collect()
}

/// Forgets one vault (all of them when `target` is `None`).
pub fn forget(
    store: &dyn SecretStore,
    config_dir: &Path,
    target: Option<(Kind, &str)>,
) -> Result<(), String> {
    let entries = read_index(config_dir);
    let selected: Vec<IndexEntry> = match target {
        Some((kind, id)) => {
            let tag = tag_for(kind, id);
            entries.into_iter().filter(|row| row.tag == tag).collect()
        }
        None => entries,
    };
    for row in &selected {
        if let Err(e) = store.delete(&key_for_tag(&row.tag)) {
            eprintln!("删除记住的解锁凭据失败: {e}");
        }
    }
    let tags: Vec<String> = selected.iter().map(|row| row.tag.clone()).collect();
    let mut remaining = read_index(config_dir);
    remaining.retain(|row| !tags.contains(&row.tag));
    write_index(config_dir, &remaining);
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashMap;
    use std::sync::Mutex;
    use tempfile::TempDir;

    struct Memory(Mutex<HashMap<String, String>>);

    impl Memory {
        fn new() -> Self {
            Self(Mutex::new(HashMap::new()))
        }
    }

    impl SecretStore for Memory {
        fn get(&self, key: &str) -> Result<Option<String>, String> {
            Ok(self.0.lock().unwrap().get(key).cloned())
        }
        fn set(&self, key: &str, value: &str) -> Result<(), String> {
            self.0
                .lock()
                .unwrap()
                .insert(key.to_string(), value.to_string());
            Ok(())
        }
        fn delete(&self, key: &str) -> Result<(), String> {
            self.0.lock().unwrap().remove(key);
            Ok(())
        }
    }

    /// Answers Ok for every write and returns nothing on read - a store that
    /// silently drops. `Memory` cannot catch this, because its map lives as
    /// long as the process that filled it.
    #[derive(Default)]
    struct Hollow(Mutex<Vec<String>>);

    impl SecretStore for Hollow {
        fn get(&self, _key: &str) -> Result<Option<String>, String> {
            Ok(None)
        }
        fn set(&self, key: &str, _value: &str) -> Result<(), String> {
            self.0.lock().unwrap().push(key.to_string());
            Ok(())
        }
        fn delete(&self, _key: &str) -> Result<(), String> {
            Ok(())
        }
    }

    #[test]
    fn a_store_that_lies_about_saving_records_no_index_row() {
        let store = Hollow::default();
        let dir = TempDir::new().unwrap();
        let err = remember(&store, dir.path(), &local_input("/lie.kdbx"), 30)
            .expect_err("a secret that vanishes after the write is a failed write");
        assert!(err.contains("读回"), "unexpected error: {err}");
        assert!(
            read_index(dir.path()).is_empty(),
            "the index must not advertise a PIN unlock the keychain cannot serve"
        );
        assert_eq!(
            store.0.lock().unwrap().len(),
            1,
            "the write was still attempted"
        );
    }

    fn local_input(id: &str) -> RememberInput {
        RememberInput {
            kind: Kind::Local,
            id: id.to_string(),
            name: "个人库".to_string(),
            master_password: "master".to_string(),
            keyfile_path: None,
            account_email: None,
            account_user_id: None,
        }
    }

    fn cloud_input(id: &str) -> RememberInput {
        RememberInput {
            kind: Kind::Cloud,
            id: id.to_string(),
            name: "云库".to_string(),
            master_password: "master".to_string(),
            keyfile_path: None,
            account_email: Some("me@example.com".to_string()),
            account_user_id: Some("user-1".to_string()),
        }
    }

    #[test]
    fn local_entry_round_trips_and_forgets() {
        let store = Memory::new();
        let dir = TempDir::new().unwrap();
        remember(&store, dir.path(), &local_input("/vaults/home.kdbx"), 30).unwrap();
        let secret = secret_for(&store, dir.path(), Kind::Local, "/vaults/home.kdbx", 30)
            .unwrap()
            .expect("entry is usable");
        assert_eq!(secret.master_password, "master");
        assert_eq!(secret.keyfile_path, None);
        // Cloud account details are never remembered for a local vault.
        assert_eq!(secret.account_email, None);

        forget(&store, dir.path(), Some((Kind::Local, "/vaults/home.kdbx"))).unwrap();
        assert!(
            secret_for(&store, dir.path(), Kind::Local, "/vaults/home.kdbx", 30)
                .unwrap()
                .is_none()
        );
        assert!(list(dir.path(), 30).is_empty());
    }

    /// The claim the whole feature rests on: the string `secret_for` hands back
    /// is what opens the file, so a restart can skip a typed master password.
    /// Checked against a real KDBX — and checked writable, which is why the
    /// password is stored rather than a KDF-transformed key.
    #[test]
    fn remembered_password_actually_opens_the_vault() {
        use openvalut_core::kdbx::{Vault, VaultKey};

        let store = Memory::new();
        let dir = TempDir::new().unwrap();
        let password = "correct horse battery staple";
        let created = Vault::create_new("测试库").unwrap();
        let bytes = created.save(&VaultKey::with_password(password)).unwrap();
        assert!(
            Vault::open(&bytes, &VaultKey::with_password("nope")).is_err(),
            "a wrong password must not open the vault, or the round trip proves nothing"
        );

        let path = dir.path().join("home.kdbx");
        fs::write(&path, &bytes).unwrap();
        let id = path.to_string_lossy().to_string();
        let input = RememberInput {
            master_password: password.to_string(),
            ..local_input(&id)
        };
        remember(&store, dir.path(), &input, 30).unwrap();

        let secret = secret_for(&store, dir.path(), Kind::Local, &id, 30)
            .unwrap()
            .expect("entry is usable");
        let key = VaultKey::with_password(secret.master_password.as_str());
        let reopened = Vault::open(&fs::read(&path).unwrap(), &key)
            .expect("the remembered password opens the vault");
        assert_eq!(reopened.name(), Some("测试库"));

        let mut renamed = reopened;
        renamed.set_name("改过名");
        let saved = renamed
            .save(&key)
            .expect("a vault opened with the remembered secret is writable");
        assert!(Vault::open(&saved, &key).is_ok());
    }

    /// `vault_change_master_password` re-keys the file and then re-remembers it.
    /// Asserted in the order that command runs: the pre-change secret has to stop
    /// opening the file (otherwise the refresh would be pointless), the new one
    /// has to open it, and re-remembering has to replace the row rather than
    /// stack a second one that PIN unlock would then pick at random.
    #[test]
    fn changing_the_master_password_refreshes_the_remembered_secret() {
        use openvalut_core::kdbx::{Vault, VaultKey};

        let store = Memory::new();
        let dir = TempDir::new().unwrap();
        let path = dir.path().join("home.kdbx");
        let old = "old master";
        let new = "new master";
        let created = Vault::create_new("测试库").unwrap();
        fs::write(&path, created.save(&VaultKey::with_password(old)).unwrap()).unwrap();
        let id = path.to_string_lossy().to_string();
        remember(
            &store,
            dir.path(),
            &RememberInput {
                master_password: old.to_string(),
                ..local_input(&id)
            },
            30,
        )
        .unwrap();

        let vault = Vault::open(&fs::read(&path).unwrap(), &VaultKey::with_password(old)).unwrap();
        let rekeyed = vault.save(&VaultKey::with_password(new)).unwrap();
        fs::write(&path, &rekeyed).unwrap();

        let stale = secret_for(&store, dir.path(), Kind::Local, &id, 30)
            .unwrap()
            .expect("the entry is still inside its window");
        assert!(
            Vault::open(
                &fs::read(&path).unwrap(),
                &VaultKey::with_password(stale.master_password.as_str())
            )
            .is_err(),
            "the pre-change password must stop opening the re-keyed file"
        );

        remember(
            &store,
            dir.path(),
            &RememberInput {
                master_password: new.to_string(),
                ..local_input(&id)
            },
            30,
        )
        .unwrap();
        let fresh = secret_for(&store, dir.path(), Kind::Local, &id, 30)
            .unwrap()
            .expect("the new password is usable");
        assert_eq!(fresh.master_password, new);
        assert!(
            Vault::open(
                &fs::read(&path).unwrap(),
                &VaultKey::with_password(fresh.master_password.as_str())
            )
            .is_ok(),
            "the refreshed secret must open the file the command just wrote"
        );
        assert_eq!(list(dir.path(), 30).len(), 1);
    }

    #[test]
    fn local_keyfile_is_remembered_with_the_password() {
        let store = Memory::new();
        let dir = TempDir::new().unwrap();
        let mut input = local_input("/vaults/withkey.kdbx");
        input.keyfile_path = Some("/vaults/withkey.keyx".to_string());
        remember(&store, dir.path(), &input, 30).unwrap();
        let secret = secret_for(&store, dir.path(), Kind::Local, "/vaults/withkey.kdbx", 30)
            .unwrap()
            .expect("entry is usable");
        assert_eq!(secret.keyfile_path.as_deref(), Some("/vaults/withkey.keyx"));
    }

    #[test]
    fn cloud_entry_keeps_the_master_password() {
        let store = Memory::new();
        let dir = TempDir::new().unwrap();
        remember(&store, dir.path(), &cloud_input("vlt-1"), 7).unwrap();
        let secret = secret_for(&store, dir.path(), Kind::Cloud, "vlt-1", 7)
            .unwrap()
            .expect("entry is usable");
        assert_eq!(secret.master_password, "master");
        assert_eq!(secret.account_email.as_deref(), Some("me@example.com"));
        assert_eq!(secret.account_user_id.as_deref(), Some("user-1"));
    }

    #[test]
    fn same_id_under_different_kind_is_a_different_entry() {
        let store = Memory::new();
        let dir = TempDir::new().unwrap();
        remember(&store, dir.path(), &local_input("shared"), 30).unwrap();
        assert!(secret_for(&store, dir.path(), Kind::Cloud, "shared", 30)
            .unwrap()
            .is_none());
    }

    /// Changing the master password re-keys the file, which makes the secret we
    /// stored wrong. If `remember` merged into the existing payload instead of
    /// replacing it, PIN unlock would keep handing back the old password and the
    /// user would see a broken PIN feature rather than a stale entry. Restarting
    /// the window matters for the same reason: keeping the original `savedAt`
    /// would expire a freshly re-keyed entry early.
    #[test]
    fn re_remembering_replaces_the_secret_and_restarts_the_window() {
        let store = Memory::new();
        let dir = TempDir::new().unwrap();
        let id = "/vaults/home.kdbx";
        remember(&store, dir.path(), &local_input(id), 7).unwrap();
        remember(
            &store,
            dir.path(),
            &RememberInput {
                master_password: "新主密码".to_string(),
                name: "改过名".to_string(),
                ..local_input(id)
            },
            30,
        )
        .unwrap();

        let secret = secret_for(&store, dir.path(), Kind::Local, id, 30)
            .unwrap()
            .expect("the re-keyed vault is still remembered");
        assert_eq!(secret.master_password, "新主密码");
        assert_eq!(secret.name, "改过名");
        let rows = list(dir.path(), 30);
        assert_eq!(rows.len(), 1, "the old entry is replaced, not shadowed");
        assert_eq!(
            rows[0].remaining_days, 30,
            "the window restarts from the re-key, not from the original save"
        );
    }

    #[test]
    fn zero_days_stores_nothing_and_hides_everything() {
        let store = Memory::new();
        let dir = TempDir::new().unwrap();
        remember(&store, dir.path(), &local_input("/a.kdbx"), 0).unwrap();
        assert!(list(dir.path(), 0).is_empty());

        remember(&store, dir.path(), &local_input("/b.kdbx"), 30).unwrap();
        assert_eq!(list(dir.path(), 30).len(), 1);
        // Lowering the setting to 0 must make the stored entry unusable.
        assert!(secret_for(&store, dir.path(), Kind::Local, "/b.kdbx", 0)
            .unwrap()
            .is_none());
    }

    #[test]
    fn empty_password_stores_nothing() {
        let store = Memory::new();
        let dir = TempDir::new().unwrap();
        let mut input = local_input("/empty.kdbx");
        input.master_password = String::new();
        remember(&store, dir.path(), &input, 30).unwrap();
        assert!(read_index(dir.path()).is_empty());
        assert!(store
            .get(&key_for(Kind::Local, "/empty.kdbx"))
            .unwrap()
            .is_none());
    }

    #[test]
    fn shortening_the_window_expires_old_entries() {
        let store = Memory::new();
        let dir = TempDir::new().unwrap();
        remember(&store, dir.path(), &local_input("/c.kdbx"), 30).unwrap();
        let tag = tag_for(Kind::Local, "/c.kdbx");
        {
            let mut entries = read_index(dir.path());
            entries.iter_mut().for_each(|row| {
                if row.tag == tag {
                    row.saved_at -= 10 * DAY_MS;
                }
            });
            write_index(dir.path(), &entries);
        }
        assert!(secret_for(&store, dir.path(), Kind::Local, "/c.kdbx", 30)
            .unwrap()
            .is_some());
        assert!(
            secret_for(&store, dir.path(), Kind::Local, "/c.kdbx", 7)
                .unwrap()
                .is_none(),
            "a 30-day entry is not usable under a 7-day setting"
        );
        assert!(
            list(dir.path(), 7).is_empty(),
            "expired rows drop off the list"
        );
    }

    #[test]
    fn corrupt_payload_prunes_the_index() {
        let store = Memory::new();
        let dir = TempDir::new().unwrap();
        remember(&store, dir.path(), &local_input("/d.kdbx"), 30).unwrap();
        store
            .set(&key_for(Kind::Local, "/d.kdbx"), "not json")
            .unwrap();
        assert!(secret_for(&store, dir.path(), Kind::Local, "/d.kdbx", 30)
            .unwrap()
            .is_none());
        assert!(read_index(dir.path()).is_empty());
    }

    #[test]
    fn touch_slides_the_window_but_never_creates() {
        let store = Memory::new();
        let dir = TempDir::new().unwrap();
        // Saving without a remembered entry must not create one.
        touch(&store, dir.path(), Kind::Local, "/e.kdbx").unwrap();
        assert!(read_index(dir.path()).is_empty());

        remember(&store, dir.path(), &local_input("/e.kdbx"), 30).unwrap();
        let tag = tag_for(Kind::Local, "/e.kdbx");
        {
            let mut entries = read_index(dir.path());
            entries.iter_mut().for_each(|row| {
                if row.tag == tag {
                    row.saved_at -= 20 * DAY_MS;
                }
            });
            write_index(dir.path(), &entries);
        }
        touch(&store, dir.path(), Kind::Local, "/e.kdbx").unwrap();
        let row = find_entry(dir.path(), Kind::Local, "/e.kdbx").unwrap();
        assert!(
            Utc::now().timestamp_millis() - row.saved_at < 60_000,
            "a save moves the expiry forward"
        );
        // The password itself is not rewritten by a save.
        assert_eq!(
            secret_for(&store, dir.path(), Kind::Local, "/e.kdbx", 30)
                .unwrap()
                .unwrap()
                .master_password,
            "master"
        );
    }

    #[test]
    fn touch_does_not_resurrect_a_dropped_secret() {
        let store = Memory::new();
        let dir = TempDir::new().unwrap();
        remember(&store, dir.path(), &local_input("/g.kdbx"), 30).unwrap();
        let before = find_entry(dir.path(), Kind::Local, "/g.kdbx").unwrap();
        store.delete(&key_for(Kind::Local, "/g.kdbx")).unwrap();
        touch(&store, dir.path(), Kind::Local, "/g.kdbx").unwrap();
        let after = find_entry(dir.path(), Kind::Local, "/g.kdbx").unwrap();
        assert_eq!(before.saved_at, after.saved_at);
    }

    /// The bug this guards: a PIN offered straight after opening the app on a
    /// freshly booted machine, because the entry outlived the boot it was
    /// written in. Within one boot the PIN keeps working.
    #[test]
    fn an_entry_only_lasts_for_the_boot_it_was_written_in() {
        let store = Memory::new();
        let dir = TempDir::new().unwrap();
        let id = "/vaults/home.kdbx";
        remember_in_boot(&store, dir.path(), &local_input(id), 30, Some("boot-a")).unwrap();

        assert_eq!(list_in_boot(dir.path(), 30, Some("boot-a")).len(), 1);
        assert!(
            secret_for_in_boot(&store, dir.path(), Kind::Local, id, 30, Some("boot-a"))
                .unwrap()
                .is_some()
        );

        assert!(
            list_in_boot(dir.path(), 30, Some("boot-b")).is_empty(),
            "a reboot must hide the PIN option"
        );
        assert!(
            secret_for_in_boot(&store, dir.path(), Kind::Local, id, 30, Some("boot-b"))
                .unwrap()
                .is_none(),
            "a reboot must require the master password, not the remembered secret"
        );
        assert!(
            store.get(&key_for(Kind::Local, id)).unwrap().is_none(),
            "the secret is deleted with the row, not left in the keychain"
        );
    }

    /// Rows written before the boot binding existed have no `boot_id`. They
    /// cannot be proven to belong to this boot, so they must not offer a PIN.
    #[test]
    fn a_legacy_row_without_a_boot_id_is_never_usable() {
        let store = Memory::new();
        let dir = TempDir::new().unwrap();
        let id = "/vaults/legacy.kdbx";
        remember_in_boot(&store, dir.path(), &local_input(id), 30, None).unwrap();
        assert_eq!(read_index(dir.path()).len(), 1, "the row was written");

        assert!(list_in_boot(dir.path(), 30, Some("boot-a")).is_empty());
        assert!(
            secret_for_in_boot(&store, dir.path(), Kind::Local, id, 30, Some("boot-a"))
                .unwrap()
                .is_none()
        );
    }

    /// A platform that cannot report a boot id keeps the old day-window
    /// behaviour rather than locking the user out on every launch.
    #[test]
    fn without_a_boot_id_the_day_window_still_decides() {
        let store = Memory::new();
        let dir = TempDir::new().unwrap();
        let id = "/vaults/unknown.kdbx";
        remember_in_boot(&store, dir.path(), &local_input(id), 30, None).unwrap();
        assert!(
            secret_for_in_boot(&store, dir.path(), Kind::Local, id, 30, None)
                .unwrap()
                .is_some()
        );
        assert_eq!(list_in_boot(dir.path(), 30, None).len(), 1);
    }

    /// Saving inside the same boot keeps sliding the window; a save queued
    /// across a reboot must not revive the row, because that would hand back a
    /// PIN without the master password ever being typed.
    #[test]
    fn touch_refreshes_only_within_the_same_boot() {
        let store = Memory::new();
        let dir = TempDir::new().unwrap();
        let id = "/vaults/touch.kdbx";
        remember_in_boot(&store, dir.path(), &local_input(id), 30, Some("boot-a")).unwrap();

        touch_in_boot(&store, dir.path(), Kind::Local, id, Some("boot-a")).unwrap();
        assert_eq!(
            find_entry(dir.path(), Kind::Local, id)
                .unwrap()
                .boot_id
                .as_deref(),
            Some("boot-a")
        );

        let before = find_entry(dir.path(), Kind::Local, id).unwrap();
        touch_in_boot(&store, dir.path(), Kind::Local, id, Some("boot-b")).unwrap();
        let after = find_entry(dir.path(), Kind::Local, id).unwrap();
        assert_eq!(before.saved_at, after.saved_at);
        assert_eq!(
            after.boot_id.as_deref(),
            Some("boot-a"),
            "a save after a reboot must not re-stamp the row"
        );
    }

    #[test]
    fn forget_all_clears_every_vault() {
        let store = Memory::new();
        let dir = TempDir::new().unwrap();
        remember(&store, dir.path(), &local_input("/f.kdbx"), 30).unwrap();
        remember(&store, dir.path(), &cloud_input("vlt-2"), 30).unwrap();
        forget(&store, dir.path(), None).unwrap();
        assert!(list(dir.path(), 30).is_empty());
        assert!(store
            .get(&key_for(Kind::Local, "/f.kdbx"))
            .unwrap()
            .is_none());
        assert!(store.get(&key_for(Kind::Cloud, "vlt-2")).unwrap().is_none());
    }

    #[test]
    fn long_windows_paths_get_a_bounded_key() {
        let deep = format!("C:\\Users\\{}", "w".repeat(200));
        assert_eq!(key_for(Kind::Local, &deep).len(), KEY_PREFIX.len() + 32);
    }

    /// Cross-process probe against the *real* OS keychain. The mock keyring
    /// that silently replaces the Windows backend when `windows-native` is off
    /// is per-process, so only a second process can prove a secret written here
    /// outlives this one. It re-runs this test binary as a child rather than
    /// relying on an operator to run two tests in the right order, because
    /// separate tests share the harness's parallel scheduling and a combined run
    /// used to fail with a misleading panic. On Windows it has to run in an
    /// interactive logon session (over SSH Credential Manager is unreachable),
    /// and as the logged-in user, not as an administrator.
    const PROBE_KEY: &str = "remembered-unlock:probe";
    const PROBE_VALUE: &str = "{\"id\":\"probe\",\"masterPassword\":\"probe-secret\"}";
    const PROBE_CHILD_ENV: &str = "OPENVALUT_KEYCHAIN_PROBE_CHILD";
    const PROBE_TEST: &str = "services::remembered::tests::real_keychain_crosses_processes";

    #[test]
    #[ignore = "writes to the real OS keychain; run the probe on the target machine"]
    fn real_keychain_crosses_processes() {
        if std::env::var_os(PROBE_CHILD_ENV).is_some() {
            let read = KeyringStore
                .get(PROBE_KEY)
                .expect("child: keychain unreachable")
                .expect("child: the parent's secret did not cross the process boundary");
            assert_eq!(
                read.as_str(),
                PROBE_VALUE,
                "child: secret came back altered"
            );
            println!("probe: child read the parent's secret");
            return;
        }

        // Leftovers from an interrupted run would otherwise look like success.
        let _ = KeyringStore.delete(PROBE_KEY);
        KeyringStore.set(PROBE_KEY, PROBE_VALUE).unwrap();

        let exe = std::env::current_exe().unwrap();
        let output = std::process::Command::new(&exe)
            .arg(PROBE_TEST)
            .arg("--exact")
            .arg("--ignored")
            .arg("--nocapture")
            .env(PROBE_CHILD_ENV, "1")
            .output()
            .expect("cannot re-run this test binary as a child");
        let stdout = String::from_utf8_lossy(&output.stdout);
        let stderr = String::from_utf8_lossy(&output.stderr);
        KeyringStore
            .delete(PROBE_KEY)
            .expect("probe secret must be removable");
        assert!(
            KeyringStore
                .get(PROBE_KEY)
                .expect("probe read must work")
                .is_none(),
            "probe secret must be gone after deletion"
        );
        assert!(
            output.status.success() && stdout.contains("child read the parent's secret"),
            "child probe failed: stdout={stdout} stderr={stderr}"
        );
        println!("probe: real keychain survives a process boundary");
    }
}
