//! System keychain access for the CLI.
//!
//! Stores the vault master password and the system sudo password in the OS
//! secret store (Linux Secret Service / macOS Keychain / Windows Credential
//! Manager via the `keyring` crate) so a single `unlock` lets later commands
//! run without re-prompting. Credentials never touch disk in plaintext.
//!
//! On Linux the unlocked secrets are additionally kept in the kernel *user*
//! keyring (`@u`). Unlike the Secret Service it needs no desktop DBus session,
//! so a fresh terminal and a bare SSH login see the same unlock, and it lives
//! in kernel memory only — cleared at reboot.

#[cfg(debug_assertions)]
use std::path::Path;
#[cfg(debug_assertions)]
use std::path::PathBuf;
use std::sync::OnceLock;

#[cfg(target_os = "linux")]
use std::ffi::CString;

/// Secret-id for the vault master password.
pub const MASTER_PASSWORD: &str = "master-password";
/// Secret-id for the system sudo password.
pub const SUDO_PASSWORD: &str = "sudo-password";
/// Secret-id for the OpenValut Cloud account Secret Key (the account UUID).
pub const CLOUD_SECRET_KEY: &str = "cloud-secret-key";

const SERVICE: &str = "openvalut-cli";

/// Minimal secret-store abstraction so the rest of the CLI is testable
/// without a live Secret Service.
pub trait KeyStore {
    fn get(&self, id: &str) -> Result<Option<String>, String>;
    fn set(&self, id: &str, value: &str) -> Result<(), String>;
    /// Returns whether a stored value was actually removed.
    fn delete(&self, id: &str) -> Result<bool, String>;
}

/// Backed by the system keychain (Secret Service on Linux).
pub struct SystemKeyStore;

impl KeyStore for SystemKeyStore {
    fn get(&self, id: &str) -> Result<Option<String>, String> {
        #[cfg(debug_assertions)]
        if let Some(dir) = test_keychain_dir() {
            return file_backed_get(&dir, id);
        }
        let entry = keyring::Entry::new(SERVICE, id).map_err(|e| e.to_string())?;
        match entry.get_password() {
            Ok(value) => Ok(Some(value)),
            Err(keyring::Error::NoEntry) => Ok(None),
            Err(e) => Err(format!("无法读取钥匙串 {id}: {e}")),
        }
    }

    fn set(&self, id: &str, value: &str) -> Result<(), String> {
        #[cfg(debug_assertions)]
        if let Some(dir) = test_keychain_dir() {
            return file_backed_set(&dir, id, value);
        }
        let entry = keyring::Entry::new(SERVICE, id).map_err(|e| e.to_string())?;
        entry
            .set_password(value)
            .map_err(|e| format!("无法写入钥匙串 {id}: {e}"))
    }

    fn delete(&self, id: &str) -> Result<bool, String> {
        #[cfg(debug_assertions)]
        if let Some(dir) = test_keychain_dir() {
            return file_backed_delete(&dir, id);
        }
        let entry = keyring::Entry::new(SERVICE, id).map_err(|e| e.to_string())?;
        match entry.delete_credential() {
            Ok(()) => Ok(true),
            Err(keyring::Error::NoEntry) => Ok(false),
            Err(e) => Err(format!("无法删除钥匙串 {id}: {e}")),
        }
    }
}

/// The integration tests must not touch the real OS keychain (a stale Secret
/// Key there would both fail assertions and be deleted by `auth logout`).
/// `OPENVALUT_TEST_KEYCHAIN_DIR` redirects the store to plaintext files under
/// that directory. Debug builds only, so a release binary can never fall back
/// to insecure file storage.
#[cfg(debug_assertions)]
fn test_keychain_dir() -> Option<PathBuf> {
    std::env::var_os("OPENVALUT_TEST_KEYCHAIN_DIR").map(PathBuf::from)
}

#[cfg(debug_assertions)]
fn file_backed_get(dir: &Path, id: &str) -> Result<Option<String>, String> {
    match std::fs::read_to_string(dir.join(format!("{id}.secret"))) {
        Ok(value) => Ok(Some(value)),
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(None),
        Err(e) => Err(format!("无法读取测试钥匙串 {id}: {e}")),
    }
}

#[cfg(debug_assertions)]
fn file_backed_set(dir: &Path, id: &str, value: &str) -> Result<(), String> {
    std::fs::create_dir_all(dir).map_err(|e| format!("无法创建测试钥匙串目录: {e}"))?;
    std::fs::write(dir.join(format!("{id}.secret")), value)
        .map_err(|e| format!("无法写入测试钥匙串 {id}: {e}"))
}

#[cfg(debug_assertions)]
fn file_backed_delete(dir: &Path, id: &str) -> Result<bool, String> {
    match std::fs::remove_file(dir.join(format!("{id}.secret"))) {
        Ok(()) => Ok(true),
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(false),
        Err(e) => Err(format!("无法删除测试钥匙串 {id}: {e}")),
    }
}

/// Returns the process-wide key store (lazily initialised once).
///
/// On Linux the unlocked secrets are written to the kernel *user* keyring
/// first: every process of the same UID shares it, so `unlock` in one terminal
/// covers a new terminal and an SSH login too, and it is dropped at reboot
/// without ever touching disk. The OS keychain stays as a durable fallback
/// (it survives reboots but, on Linux, needs the unlocked desktop session).
pub fn default_key_store() -> &'static dyn KeyStore {
    static STORE: OnceLock<Box<dyn KeyStore + Send + Sync>> = OnceLock::new();
    STORE
        .get_or_init(|| {
            // Tests redirect the store to plaintext files and must not touch
            // the developer's real per-UID keyring.
            #[cfg(debug_assertions)]
            if test_keychain_dir().is_some() {
                return Box::new(SystemKeyStore);
            }
            #[cfg(target_os = "linux")]
            {
                Box::new(LayeredStore::<SessionKeyStore, SystemKeyStore> {
                    session: SessionKeyStore,
                    system: SystemKeyStore,
                })
            }
            #[cfg(not(target_os = "linux"))]
            {
                Box::new(SystemKeyStore)
            }
        })
        .as_ref()
}

/// Kernel user-keyring (`@u`) backed store.
///
/// Shared by every process of the same UID — a new terminal, a different TTY
/// and an SSH login all resolve the same key — and stored in kernel memory
/// only, so it disappears when the machine reboots (and nothing hits disk).
#[cfg(target_os = "linux")]
pub struct SessionKeyStore;

#[cfg(target_os = "linux")]
impl KeyStore for SessionKeyStore {
    fn get(&self, id: &str) -> Result<Option<String>, String> {
        let Some(serial) = keyutils::search(&keyutils::description(id))? else {
            return Ok(None);
        };
        let bytes = keyutils::read(serial)?;
        Ok(Some(String::from_utf8_lossy(&bytes).into_owned()))
    }

    fn set(&self, id: &str, value: &str) -> Result<(), String> {
        keyutils::add(&keyutils::description(id), value.as_bytes())
    }

    fn delete(&self, id: &str) -> Result<bool, String> {
        let Some(serial) = keyutils::search(&keyutils::description(id))? else {
            return Ok(false);
        };
        keyutils::unlink(serial)?;
        Ok(true)
    }
}

/// The default Linux store: the in-memory session keyring first, with the OS
/// keychain kept in sync as a durable fallback. Generic over the two inner
/// stores so the layering itself is unit-testable with in-memory fakes.
#[cfg(target_os = "linux")]
struct LayeredStore<S: KeyStore, K: KeyStore> {
    session: S,
    system: K,
}

#[cfg(target_os = "linux")]
impl<S: KeyStore, K: KeyStore> KeyStore for LayeredStore<S, K> {
    fn get(&self, id: &str) -> Result<Option<String>, String> {
        match self.session.get(id) {
            Ok(Some(value)) if !value.is_empty() => return Ok(Some(value)),
            Ok(_) => {}
            // A blocked/unavailable keyring must not hide a keychain entry.
            Err(_) => {}
        }
        let value = self.system.get(id)?;
        // Self-healing migration: a credential that only exists in the OS
        // keychain (saved by an older build, or by `auth login` on a machine
        // where the keyring was unavailable) is mirrored into the session
        // keyring the first time it is read from a desktop session. Later
        // calls — including from a bare SSH login — then find it in memory.
        if let Some(value) = &value {
            if !value.is_empty() {
                let _ = self.session.set(id, value);
            }
        }
        Ok(value)
    }

    fn set(&self, id: &str, value: &str) -> Result<(), String> {
        let session = self.session.set(id, value);
        // Best effort: over a bare SSH login there is no unlocked Secret
        // Service, but the in-memory keyring already made the value available.
        let system = self.system.set(id, value);
        match (session, system) {
            (Ok(()), _) => Ok(()),
            (Err(_), Ok(())) => Ok(()),
            (Err(e), Err(_)) => Err(e),
        }
    }

    fn delete(&self, id: &str) -> Result<bool, String> {
        let session = self.session.delete(id);
        let system = self.system.delete(id);
        match (session, system) {
            (Ok(session), Ok(system)) => Ok(session || system),
            // A locked/unavailable keychain must not mask a cleared keyring.
            (Ok(session), Err(_)) => Ok(session),
            (Err(e), _) => Err(e),
        }
    }
}

/// Thin wrapper over the `add_key(2)` / `keyctl(2)` syscalls. The constants are
/// the stable values from `linux/keyctl.h`; the syscall numbers come from libc.
#[cfg(target_os = "linux")]
mod keyutils {
    use super::CString;
    use std::io::Error;

    const KEY_SPEC_USER_KEYRING: i32 = -4;
    const KEYCTL_SETPERM: u32 = 5;
    const KEYCTL_UNLINK: u32 = 9;
    const KEYCTL_SEARCH: u32 = 10;
    const KEYCTL_READ: u32 = 11;
    /// `KEY_USR_ALL` from `linux/keyctl.h`: view|read|write|search|link|setattr.
    /// `add_key` creates the key *without* user read, so a later process (a new
    /// terminal or SSH login) has to be granted read explicitly.
    const KEY_USR_ALL: u32 = 0x003f_0000;

    /// No matching key exists in the searched keyring.
    const ENOKEY: i32 = 126;
    /// The matching key expired / was revoked — treat as "not found".
    const EKEYEXPIRED: i32 = 127;
    const EKEYREVOKED: i32 = 128;

    /// Key description used inside the user keyring. The `openvalut:` prefix is
    /// a shared contract with the desktop app (`utils/session_store_io.dart`),
    /// which reads and writes the very same `openvalut:master-password` key.
    pub fn description(id: &str) -> String {
        format!("openvalut:{id}")
    }

    fn cstring(text: &str) -> Result<CString, String> {
        CString::new(text).map_err(|_| "key 描述/内容包含 NUL 字节".to_string())
    }

    fn is_missing(err: &Error) -> bool {
        matches!(
            err.raw_os_error(),
            Some(ENOKEY) | Some(EKEYEXPIRED) | Some(EKEYREVOKED)
        )
    }

    /// Adds (or updates) a `user` key holding `payload` in the user keyring.
    pub fn add(desc: &str, payload: &[u8]) -> Result<(), String> {
        let key_type = cstring("user")?;
        let desc = cstring(desc)?;
        let rc = unsafe {
            libc::syscall(
                libc::SYS_add_key,
                key_type.as_ptr(),
                desc.as_ptr(),
                payload.as_ptr() as *const libc::c_void,
                payload.len() as libc::c_long,
                KEY_SPEC_USER_KEYRING as libc::c_long,
            )
        };
        if rc < 0 {
            return Err(format!("无法写入内核 keyring：{}", Error::last_os_error()));
        }
        let serial = rc;
        let rc = unsafe {
            libc::syscall(
                libc::SYS_keyctl,
                KEYCTL_SETPERM as libc::c_long,
                serial,
                KEY_USR_ALL as libc::c_long,
            )
        };
        if rc < 0 {
            return Err(format!(
                "无法设置内核 keyring 权限：{}",
                Error::last_os_error()
            ));
        }
        Ok(())
    }

    /// Looks up the serial of the `user` key with `desc`, if present.
    pub fn search(desc: &str) -> Result<Option<i64>, String> {
        let key_type = cstring("user")?;
        let desc = cstring(desc)?;
        let rc = unsafe {
            libc::syscall(
                libc::SYS_keyctl,
                KEYCTL_SEARCH as libc::c_long,
                KEY_SPEC_USER_KEYRING as libc::c_long,
                key_type.as_ptr(),
                desc.as_ptr(),
                0 as libc::c_long,
            )
        };
        if rc >= 0 {
            return Ok(Some(rc));
        }
        let err = Error::last_os_error();
        if is_missing(&err) {
            Ok(None)
        } else {
            Err(format!("无法读取内核 keyring：{err}"))
        }
    }

    /// Reads the payload of a key found via [`search`].
    pub fn read(serial: i64) -> Result<Vec<u8>, String> {
        // Ask for the size first so large payloads aren't truncated.
        let size = unsafe {
            libc::syscall(
                libc::SYS_keyctl,
                KEYCTL_READ as libc::c_long,
                serial,
                std::ptr::null_mut::<libc::c_void>(),
                0 as libc::c_long,
            )
        };
        if size < 0 {
            return Err(format!("无法读取内核 keyring：{}", Error::last_os_error()));
        }
        let mut buffer = vec![0u8; size as usize];
        let rc = unsafe {
            libc::syscall(
                libc::SYS_keyctl,
                KEYCTL_READ as libc::c_long,
                serial,
                buffer.as_mut_ptr() as *mut libc::c_void,
                buffer.len() as libc::c_long,
            )
        };
        if rc < 0 {
            return Err(format!("无法读取内核 keyring：{}", Error::last_os_error()));
        }
        buffer.truncate(rc as usize);
        Ok(buffer)
    }

    /// Unlinks a key from the user keyring (no-op when it is already gone).
    pub fn unlink(serial: i64) -> Result<(), String> {
        let rc = unsafe {
            libc::syscall(
                libc::SYS_keyctl,
                KEYCTL_UNLINK as libc::c_long,
                serial,
                KEY_SPEC_USER_KEYRING as libc::c_long,
            )
        };
        if rc >= 0 {
            return Ok(());
        }
        let err = Error::last_os_error();
        if is_missing(&err) {
            Ok(())
        } else {
            Err(format!("无法清除内核 keyring：{err}"))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::cell::RefCell;
    use std::collections::HashMap;

    struct Memory(RefCell<HashMap<String, String>>);

    impl KeyStore for Memory {
        fn get(&self, id: &str) -> Result<Option<String>, String> {
            Ok(self.0.borrow().get(id).cloned())
        }
        fn set(&self, id: &str, value: &str) -> Result<(), String> {
            self.0
                .borrow_mut()
                .insert(id.to_string(), value.to_string());
            Ok(())
        }
        fn delete(&self, id: &str) -> Result<bool, String> {
            Ok(self.0.borrow_mut().remove(id).is_some())
        }
    }

    #[test]
    fn memory_store_round_trips_and_deletes() {
        let store = Memory(RefCell::new(HashMap::new()));
        assert_eq!(store.get("master").unwrap(), None);
        store.set("master", "hunter2").unwrap();
        assert_eq!(store.get("master").unwrap().as_deref(), Some("hunter2"));
        assert!(store.delete("master").unwrap());
        assert_eq!(store.get("master").unwrap(), None);
        // Deleting a missing entry is a no-op, not an error.
        assert_eq!(store.delete("nope"), Ok(false));
    }

    /// The kernel user keyring is what makes `unlock` survive into a new
    /// terminal / SSH login without touching disk. Round-trip it where the
    /// kernel (and its seccomp policy) allows, otherwise skip — the OS
    /// keychain remains the fallback.
    #[test]
    #[cfg(target_os = "linux")]
    fn session_keyring_round_trips() {
        let store = SessionKeyStore;
        let id = format!("unit-test-{}", std::process::id());
        if let Err(e) = store.set(&id, "hunter2") {
            eprintln!("kernel keyring unavailable, skipping: {e}");
            return;
        }
        assert_eq!(store.get(&id).unwrap().as_deref(), Some("hunter2"));
        // Re-adding the same description must update, not duplicate.
        store.set(&id, "hunter3").unwrap();
        assert_eq!(store.get(&id).unwrap().as_deref(), Some("hunter3"));
        assert!(store.delete(&id).unwrap());
        assert_eq!(store.get(&id).unwrap(), None);
        // Deleting a missing key is a no-op, not an error.
        assert_eq!(store.delete(&id), Ok(false));
    }

    /// The layered default prefers the in-memory session keyring, mirrors
    /// writes into the OS keychain, and clears both on `lock`.
    #[test]
    #[cfg(target_os = "linux")]
    fn layered_store_reads_session_then_falls_back_to_system() {
        let store = LayeredStore {
            session: Memory(RefCell::new(HashMap::new())),
            system: Memory(RefCell::new(HashMap::new())),
        };
        // Nothing anywhere.
        assert_eq!(store.get("master-password").unwrap(), None);

        // A durable keychain entry is visible while the session ring is empty.
        store
            .system
            .set("master-password", "from-keychain")
            .unwrap();
        assert_eq!(
            store.get("master-password").unwrap().as_deref(),
            Some("from-keychain")
        );
        // ... and reading it mirrors it into the session ring, so a later
        // bare-SSH process (which cannot reach the keychain) still finds it.
        assert_eq!(
            store.session.get("master-password").unwrap().as_deref(),
            Some("from-keychain")
        );

        // `unlock` writes both layers; the session ring now wins.
        store.set("master-password", "fresh").unwrap();
        assert_eq!(
            store.get("master-password").unwrap().as_deref(),
            Some("fresh")
        );
        assert_eq!(
            store.system.get("master-password").unwrap().as_deref(),
            Some("fresh")
        );

        // `lock` clears both, so a stale durable copy can't linger.
        assert!(store.delete("master-password").unwrap());
        assert_eq!(store.get("master-password").unwrap(), None);
        assert_eq!(store.system.get("master-password").unwrap(), None);
    }
}
