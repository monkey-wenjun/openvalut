//! Remembered unlock: reopen a vault with the master password saved in the OS
//! keychain, gated on a Windows Hello / polkit check, so the password is typed
//! once per remember period instead of on every start.

use std::sync::mpsc;
use std::sync::OnceLock;
use std::time::Duration;

use tauri::{AppHandle, State};

use crate::commands::vault::{install_local_handle, VaultMeta};
use crate::services::hello;
use crate::services::remembered::{self, Kind, RememberInput, RememberedSummary};
use crate::state::AppState;

/// The OS keychain is a synchronous round-trip to another process (gnome-keyring
/// over D-Bus, Windows Credential Manager) with no timeout of its own, and these
/// writes sit inside `vault_open` / `vault_save` — commands Tauri runs on the main
/// thread. Blocking there stops the window from painting or taking clicks, which
/// looks exactly like the app ignoring the user.
///
/// Detaching each write onto its own thread is not enough, because two properties
/// this feature depends on would break: `remembered-index.json` is read, modified
/// and rewritten with no lock, so two writers lose one another's row; and a write
/// still in flight when the user switches "remember" off lands *after* the wipe,
/// leaving a master password in the credential vault that nothing will delete.
/// Both are ordering problems, so every mutation goes through one worker thread
/// that runs them in the order the user caused them.
type KeychainTask = Box<dyn FnOnce() + Send + 'static>;

/// Long enough for a healthy credential broker, short enough that a dialog the
/// user is waiting on never feels like the app has stopped answering.
const KEYCHAIN_WAIT: Duration = Duration::from_secs(3);

static KEYCHAIN: OnceLock<mpsc::Sender<KeychainTask>> = OnceLock::new();

fn worker() -> &'static mpsc::Sender<KeychainTask> {
    KEYCHAIN.get_or_init(|| {
        let (tx, rx) = mpsc::channel::<KeychainTask>();
        std::thread::spawn(move || {
            while let Ok(task) = rx.recv() {
                task();
            }
        });
        tx
    })
}

/// Queues work whose only outcome is a log line: the unlock already succeeded, and
/// a broken keychain must never look like a wrong password.
fn keychain_later(label: &'static str, work: impl FnOnce() -> Result<(), String> + Send + 'static) {
    let _ = worker().send(Box::new(move || {
        if let Err(e) = work() {
            eprintln!("{label}: {e}");
        }
    }));
}

/// Queues work and waits for its result. Used where the caller reports the
/// outcome, so the answer has to be true by the time this returns; blocking until
/// this task runs also means everything queued before it has been applied.
///
/// Reads go through the same queue as writes rather than straight to the
/// keychain: one worker owns the index, and a read that jumped the queue could
/// answer from before a write the user already saw succeed.
///
/// The wait has a deadline. gnome-keyring and the credential broker can fail to
/// answer at all, and every caller here is a dialog the user is looking at or the
/// quit path - so it gets an error they can act on rather than a window that
/// stops responding. A task that outlives its deadline still holds the worker,
/// which delays whatever queues behind it; that is the cheaper half of the trade,
/// because the alternative is freezing the UI thread instead.
fn keychain_await<T: Send + 'static>(
    budget: Duration,
    work: impl FnOnce() -> Result<T, String> + Send + 'static,
) -> Result<T, String> {
    let (tx, rx) = mpsc::channel();
    keychain_later("钥匙串操作失败", move || {
        let outcome = work();
        let _ = tx.send(outcome);
        Ok(())
    });
    match rx.recv_timeout(budget) {
        Ok(outcome) => outcome,
        Err(mpsc::RecvTimeoutError::Timeout) => Err("系统钥匙串没有响应，请稍后重试".to_string()),
        Err(mpsc::RecvTimeoutError::Disconnected) => {
            Err("记住的凭据操作被中断，请重试".to_string())
        }
    }
}

fn keychain_now(work: impl FnOnce() -> Result<(), String> + Send + 'static) -> Result<(), String> {
    keychain_await(KEYCHAIN_WAIT, work)
}

/// Blocks until everything queued has been applied.
pub(crate) fn flush() {
    let _ = keychain_now(|| Ok(()));
}

/// Forgets every remembered vault, ordered against the writes still in flight.
/// Switching the feature off is the one path that must not be able to lose to a
/// pending remember, so it cannot call `remembered::forget` inline.
pub(crate) fn forget_everything(state: &AppState) -> Result<(), String> {
    let config_dir = state.config_dir.clone();
    keychain_now(move || remembered::forget(remembered::default_store(), &config_dir, None))
}

/// Records the credentials of a vault that was just opened with the typed
/// master password. Failure is only logged: the unlock succeeded, and a broken
/// keychain must never look like a wrong password.
pub fn remember_unlock(state: &AppState, input: RememberInput) {
    let days = state.settings.lock().unwrap().remember_unlock_days;
    let config_dir = state.config_dir.clone();
    keychain_later("保存记住的解锁凭据失败", move || {
        remembered::remember(remembered::default_store(), &config_dir, &input, days)
    });
}

/// Records the credentials of a local vault that was just opened, created or
/// re-keyed with the typed master password.
pub(crate) fn remember_local(
    state: &AppState,
    path: &str,
    name: &str,
    password: &str,
    keyfile_path: Option<&str>,
) {
    remember_unlock(
        state,
        RememberInput {
            kind: Kind::Local,
            id: path.to_string(),
            name: name.to_string(),
            master_password: password.to_string(),
            keyfile_path: keyfile_path.map(str::to_string),
            account_email: None,
            account_user_id: None,
        },
    );
}

/// Slides the remembered window of the currently open vault forward, so a vault
/// in daily use does not expire in the middle of the week.
pub(crate) fn touch_saved(state: &AppState) {
    let guard = state.vault.read().unwrap();
    let Some(handle) = guard.as_ref() else { return };
    let kind = if handle.source.local_path().is_some() {
        Kind::Local
    } else {
        Kind::Cloud
    };
    let days = state.settings.lock().unwrap().remember_unlock_days;
    if days == 0 {
        return;
    }
    let id = handle.id_string();
    let config_dir = state.config_dir.clone();
    keychain_later("刷新记住的解锁凭据失败", move || {
        remembered::touch(remembered::default_store(), &config_dir, kind, &id)
    });
}

fn parse_kind(raw: &str) -> Result<Kind, String> {
    match raw {
        "local" => Ok(Kind::Local),
        "cloud" => Ok(Kind::Cloud),
        other => Err(format!("未知的密码库类型：{other}")),
    }
}

#[tauri::command]
pub fn remembered_status(state: State<'_, AppState>) -> Result<Vec<RememberedSummary>, String> {
    let days = state.settings.lock().unwrap().remember_unlock_days;
    Ok(remembered::list(&state.config_dir, days))
}

#[tauri::command]
pub fn remembered_forget(
    state: State<'_, AppState>,
    kind: Option<String>,
    id: Option<String>,
) -> Result<(), String> {
    let target = match (&kind, &id) {
        (Some(kind), Some(id)) => Some((parse_kind(kind)?, id.clone())),
        (None, None) => None,
        _ => return Err("必须同时提供密码库类型和标识".to_string()),
    };
    let config_dir = state.config_dir.clone();
    // Awaited: the dialog reloads its list as soon as this returns, so a row that
    // is still queued counts as not forgotten.
    keychain_now(move || {
        remembered::forget(
            remembered::default_store(),
            &config_dir,
            target.as_ref().map(|(kind, id)| (*kind, id.as_str())),
        )
    })
}

/// Reopens `id` without a typed password: identity check first, then the
/// stored key. Any doubt — expired entry, file rewritten elsewhere, different
/// cloud account — is answered by asking for the master password.
#[tauri::command]
pub fn remembered_unlock(
    app: AppHandle,
    state: State<'_, AppState>,
    kind: String,
    id: String,
) -> Result<VaultMeta, String> {
    let kind = parse_kind(&kind)?;
    let (setting_days, language) = {
        let settings = state.settings.lock().unwrap();
        (settings.remember_unlock_days, settings.language.clone())
    };
    if setting_days == 0 {
        return Err("未开启记住主密码，请输入主密码".to_string());
    }
    if remembered::list(&state.config_dir, setting_days)
        .into_iter()
        .all(|row| row.kind != kind || row.id != id)
    {
        return Err("没有可用的记住凭据，请输入主密码".to_string());
    }

    // Gate before reaching for the secret: Hello (or polkit) has to confirm the
    // user is present, and it fails closed.
    hello::verify(&language)?;

    // The secret is fetched through the queue with a deadline: this runs on the
    // main thread right after the Hello prompt, so an unresponsive keychain has to
    // turn into "try again" rather than a PIN screen that never finishes.
    let read_config_dir = state.config_dir.clone();
    let read_id = id.clone();
    let secret = keychain_await(KEYCHAIN_WAIT, move || {
        remembered::secret_for(
            remembered::default_store(),
            &read_config_dir,
            kind,
            &read_id,
            setting_days,
        )
    })?
    .ok_or_else(|| "记住的凭据已失效，请输入主密码".to_string())?;

    let config_dir = state.config_dir.clone();
    let touched_id = id.clone();
    match kind {
        Kind::Local => unlock_local(&app, &state, &id, secret),
        Kind::Cloud => unlock_cloud(&app, &state, &id, secret),
    }
    .inspect(|_| {
        // Opening a vault keeps its window alive (the Flutter app refreshed the
        // entry on every unlock too), so a vault in daily use never expires.
        keychain_later("刷新记住的解锁凭据失败", move || {
            remembered::touch(remembered::default_store(), &config_dir, kind, &touched_id)
        });
    })
}

fn unlock_local(
    app: &AppHandle,
    state: &AppState,
    path: &str,
    secret: remembered::RememberedSecret,
) -> Result<VaultMeta, String> {
    let bytes = std::fs::read(path).map_err(|e| format!("打开密码库文件失败: {e}"))?;
    let key =
        crate::commands::vault::open_key(&secret.master_password, secret.keyfile_path.as_deref())?;
    let vault = openvalut_core::Vault::open(&bytes, &key).map_err(|e| {
        // The file no longer answers to what we remembered (moved, re-keyed
        // elsewhere, or the keyfile is gone), so stop offering it.
        let dropped = path.to_string();
        let config_dir = state.config_dir.clone();
        keychain_later("丢弃失效的本地凭据失败", move || {
            remembered::forget(
                remembered::default_store(),
                &config_dir,
                Some((Kind::Local, dropped.as_str())),
            )
        });
        eprintln!("记住的本地凭据无法解锁 {path}: {e}");
        "记住的凭据已失效，请输入主密码".to_string()
    })?;
    let name = vault.name().unwrap_or("openvalut").to_string();
    install_local_handle(app, state, path, &name, vault, key)
}

fn unlock_cloud(
    app: &AppHandle,
    state: &AppState,
    vault_id: &str,
    secret: remembered::RememberedSecret,
) -> Result<VaultMeta, String> {
    let password = secret.master_password;
    let (client, email) = crate::commands::cloud::account_client(state)?;
    let account_mismatch = secret
        .account_user_id
        .as_deref()
        .is_some_and(|stored| stored != client.user_id())
        || secret
            .account_email
            .as_deref()
            .is_some_and(|stored| stored != email);
    if account_mismatch {
        let config_dir = state.config_dir.clone();
        let dropped = vault_id.to_string();
        // Awaited: telling the user to type the master password is only honest
        // once the row that would have offered the PIN is really gone.
        keychain_now(move || {
            remembered::forget(
                remembered::default_store(),
                &config_dir,
                Some((Kind::Cloud, dropped.as_str())),
            )
        })?;
        return Err("云账号已切换，请输入主密码".to_string());
    }
    crate::commands::cloud::open_cloud_vault(
        app,
        state,
        client,
        &password,
        Some(vault_id.to_string()),
    )
}

#[cfg(test)]
mod tests {
    use super::{keychain_await, keychain_later, keychain_now};
    use std::sync::{Arc, Mutex};
    use std::thread::sleep;
    use std::time::Duration;

    /// Moving the keychain off the calling thread is only safe while the work
    /// stays serial and keeps its order: a remember queued by the unlock that
    /// just happened must not be able to land after the wipe that follows it, or
    /// the master password outlives a feature the user switched off. Both are
    /// properties of the queue, not of `remembered::forget`, so that is what is
    /// under test here.
    #[test]
    fn queued_work_is_serial_and_ordered() {
        let log: Arc<Mutex<Vec<String>>> = Arc::new(Mutex::new(Vec::new()));

        let slow = log.clone();
        keychain_later("slow", move || {
            // Long enough that an unconcurrent worker would interleave these
            // three entries instead of running them one after another.
            sleep(Duration::from_millis(200));
            slow.lock().unwrap().push("queued-first".to_string());
            Ok(())
        });
        let next = log.clone();
        keychain_later("fast", move || {
            next.lock().unwrap().push("queued-second".to_string());
            Ok(())
        });

        let here = log.clone();
        keychain_now(move || {
            here.lock().unwrap().push("awaited".to_string());
            Ok(())
        })
        .unwrap();

        // Returns only once the queue has drained, so the two submissions above
        // are already applied - which is what lets `settings_set` report a wipe
        // that really happened.
        assert_eq!(
            *log.lock().unwrap(),
            vec!["queued-first", "queued-second", "awaited"]
        );
    }

    /// The unlock path asks the keychain for a secret on the main thread, right
    /// after the Hello prompt. A broker that never answers has to turn into an
    /// error the user can read, and the queue has to work again afterwards.
    #[test]
    fn an_unanswered_await_times_out_and_the_queue_recovers() {
        keychain_later("blocker", move || {
            sleep(Duration::from_millis(300));
            Ok(())
        });

        let err = keychain_await(Duration::from_millis(30), || Ok(())).unwrap_err();
        assert!(err.contains("没有响应"), "unexpected error: {err}");

        // The blocked task still holds the worker until it finishes, so this is
        // asserting recovery rather than pretending the task was cancelled.
        keychain_await(Duration::from_secs(5), || Ok("cleared")).expect("queue wedged");
    }
}
