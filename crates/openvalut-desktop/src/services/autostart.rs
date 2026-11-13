//! Start-at-login. Written by Rust rather than the frontend so the entry always
//! points at the executable that is actually running: a per-user NSIS install
//! lives under `%LOCALAPPDATA%\openvalut`, and an upgrade moves it.

use tauri::AppHandle;

/// The argument telling `run()` to keep the window hidden at startup.
pub const HIDDEN_ARG: &str = "--hidden";

/// Registers (`enabled`) or unregisters the app as a login item.
pub fn set_enabled(app: &AppHandle, enabled: bool) -> Result<(), String> {
    #[cfg(windows)]
    {
        let _ = app;
        write_or_clear(enabled)
    }
    #[cfg(not(windows))]
    {
        use tauri_plugin_autostart::ManagerExt;
        let manager = app.autolaunch();
        if enabled {
            manager.enable()
        } else {
            manager.disable()
        }
        .map_err(|e| e.to_string())
    }
}

#[cfg(windows)]
const RUN_KEY: &str = r"Software\Microsoft\Windows\CurrentVersion\Run";
#[cfg(windows)]
const RUN_VALUE: &str = "openvalut";
/// `ERROR_FILE_NOT_FOUND` as an HRESULT: the registry reports an absent value
/// this way, and unregistering an already-unregistered app is a no-op.
#[cfg(windows)]
const NOT_FOUND: windows_result::HRESULT = windows_result::HRESULT::from_win32(0x8007_0002);

#[cfg(windows)]
fn write_or_clear(enabled: bool) -> Result<(), String> {
    // `cargo tauri dev` runs from target/debug; registering that as a login
    // item would survive the session and launch a stale binary. Refuse loudly
    // rather than reporting a change that was never made.
    if cfg!(debug_assertions) {
        return Err("调试构建不写开机自启动项,请用 release 构建切换".to_string());
    }
    let key = windows_registry::CURRENT_USER
        .create(RUN_KEY)
        .map_err(|e| e.to_string())?;
    if enabled {
        let exe = std::env::current_exe().map_err(|e| e.to_string())?;
        key.set_string(RUN_VALUE, run_command_line(&exe))
            .map_err(|e| e.to_string())
    } else {
        match key.remove_value(RUN_VALUE) {
            Ok(()) => Ok(()),
            Err(e) if e.code() == NOT_FOUND => Ok(()),
            Err(e) => Err(e.to_string()),
        }
    }
}

/// The `Run` value is parsed as a command line, so an unquoted path launches
/// `<exe up to the first space>.exe`. Per-user NSIS installs land under
/// `%LOCALAPPDATA%`, and that directory contains a space as soon as the account
/// name does.
#[cfg(any(windows, test))]
fn run_command_line(exe: &std::path::Path) -> String {
    format!("\"{}\" {HIDDEN_ARG}", exe.display())
}

/// Re-points an existing entry at the running executable, so a moved install
/// keeps starting. Debug builds never touch the login items.
pub fn heal(app: &AppHandle) {
    #[cfg(debug_assertions)]
    let _ = app;
    #[cfg(not(debug_assertions))]
    {
        use tauri::Manager;
        let enabled = app
            .state::<crate::state::AppState>()
            .settings
            .lock()
            .unwrap()
            .autostart;
        if enabled {
            if let Err(e) = set_enabled(app, true) {
                eprintln!("修复开机自启动失败: {e}");
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::run_command_line;
    use std::path::Path;

    #[test]
    fn the_run_value_quotes_the_executable_and_passes_hidden() {
        assert_eq!(
            run_command_line(Path::new(
                r"C:\Users\user\AppData\Local\openvalut\openvalut-desktop.exe"
            )),
            r#""C:\Users\user\AppData\Local\openvalut\openvalut-desktop.exe" --hidden"#
        );
    }

    #[test]
    fn a_user_name_with_a_space_stays_one_executable() {
        // Without the quotes Windows would start
        // `C:\Users\hs\wei\AppData\Local\openvalut\openvalut-desktop.exe`.
        let value = run_command_line(Path::new(
            r"C:\Users\hs wei\AppData\Local\openvalut\openvalut-desktop.exe",
        ));
        assert!(value.starts_with('"') && value.ends_with("--hidden"));
        let quoted_end = value
            .find(r#"" --hidden"#)
            .expect("space after the closing quote");
        let inner = &value[1..quoted_end];
        assert_eq!(
            inner,
            r"C:\Users\hs wei\AppData\Local\openvalut\openvalut-desktop.exe"
        );
        assert!(inner.contains(' '), "the path really carries the space");
    }
}
