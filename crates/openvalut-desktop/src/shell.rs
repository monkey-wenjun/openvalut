//! App shell: the tray icon, what the close button does, and coming back from
//! the tray. Windows must build the tray on the main thread, so this is called
//! from `setup` rather than from a command.

use std::sync::atomic::{AtomicU32, Ordering};

use tauri::image::Image;
use tauri::menu::{Menu, MenuEvent, MenuItem};
use tauri::tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent};
use tauri::{AppHandle, Manager, WebviewWindow, Window, WindowEvent};

use crate::state::AppState;

const TRAY_ID: &str = "ov-tray";
const SHOW_ITEM: &str = "tray-show";
const QUIT_ITEM: &str = "tray-quit";

fn main_window(app: &AppHandle) -> Option<WebviewWindow> {
    app.get_webview_window("main")
}

/// Brings the window back from the tray.
pub fn show(app: &AppHandle) {
    if let Some(window) = main_window(app) {
        let _ = window.unminimize();
        let _ = window.show();
        let _ = window.set_focus();
    }
}

static AUTO_ZOOM: AtomicU32 = AtomicU32::new(100);

/// The zoom computed from the live display geometry, remembered so that the
/// "auto" setting (percent 0) can be resolved later, when the startup call or a
/// settings save reaches `apply_zoom`.
pub fn set_auto_zoom(percent: u32) {
    AUTO_ZOOM.store(percent, Ordering::Relaxed);
}

/// `ui_zoom = 0` means the display-computed value, anything else is the user's
/// own choice. Clamped here so no caller can hand the webview a number it refuses.
fn resolve_zoom(percent: u32, auto: u32) -> u32 {
    let chosen = if percent == 0 { auto } else { percent };
    chosen.clamp(50, 200)
}

/// Scales the web content to compensate a fractional screen scale, in percent.
/// Called at startup and on every settings save so the change is visible before
/// the dialog closes.
pub fn apply_zoom(app: &AppHandle, percent: u32) {
    let factor = f64::from(resolve_zoom(percent, AUTO_ZOOM.load(Ordering::Relaxed))) / 100.0;
    if let Some(window) = main_window(app) {
        let _ = window.set_zoom(factor);
    }
}

fn toggle(app: &AppHandle) {
    let Some(window) = main_window(app) else {
        return;
    };
    if window.is_visible().unwrap_or(false) {
        let _ = window.hide();
    } else {
        show(app);
    }
}

/// Quitting through the tray is the only exit once the close button hides, so
/// unsaved edits are written out on the way instead of being dropped.
fn quit(app: &AppHandle) {
    if let Some(state) = app.try_state::<AppState>() {
        let guard = state.vault.read().unwrap();
        if let Some(handle) = guard.as_ref() {
            if handle.dirty.load(Ordering::Acquire) {
                if let Err(e) = handle.persist() {
                    eprintln!("退出前保存密码库失败: {e}");
                }
            }
        }
    }
    // The remember worker is asynchronous, so a vault opened moments ago may
    // still have its keychain write queued. Waiting for the queue to drain is
    // what keeps "unlock, then quit straight away" from silently losing the
    // entry that the next start is supposed to offer the PIN for.
    crate::commands::remembered::flush();
    app.exit(0);
}

fn record_tray(app: &AppHandle, available: bool) {
    if let Some(state) = app.try_state::<AppState>() {
        state.tray_available.store(available, Ordering::Release);
    }
}

fn build_with_icon(app: &AppHandle, icon: Image) -> tauri::Result<()> {
    let show_item = MenuItem::with_id(app, SHOW_ITEM, "显示 OpenValut", true, None::<&str>)?;
    let quit_item = MenuItem::with_id(app, QUIT_ITEM, "退出", true, None::<&str>)?;
    let menu = Menu::with_items(app, &[&show_item, &quit_item])?;
    TrayIconBuilder::with_id(TRAY_ID)
        .icon(icon)
        .menu(&menu)
        .tooltip("openvalut")
        // Left click shows or hides; the menu belongs to the right click. On
        // Linux the indicator backend never delivers the click at all (calling
        // StatusNotifierItem.Activate answers "No handler for Activate"), so a
        // left click there opens the menu instead of doing nothing.
        .show_menu_on_left_click(cfg!(target_os = "linux"))
        .on_tray_icon_event(|tray, event| {
            if let TrayIconEvent::Click {
                button: MouseButton::Left,
                button_state: MouseButtonState::Up,
                ..
            } = event
            {
                toggle(tray.app_handle());
            }
        })
        .build(app)?;
    Ok(())
}

/// Builds the tray and records whether it is reachable.
pub fn build_tray(app: &AppHandle) {
    let Some(icon) = app.default_window_icon().cloned() else {
        record_tray(app, false);
        return;
    };
    match build_with_icon(app, icon) {
        Ok(()) => {
            record_tray(app, true);
            // libappindicator reports success whether or not anything can show
            // the icon, so say out loud when the tray is really unserviced.
            #[cfg(target_os = "linux")]
            if !sni_host_present() {
                eprintln!("系统托盘没有可用的 StatusNotifier 宿主，关闭按钮将直接退出应用");
            }
        }
        // Hiding on close would strand the app, so the close button keeps
        // quitting. This is normal on a Wayland session without an indicator
        // host, not something to interrupt the user for.
        Err(e) => {
            eprintln!("创建系统托盘失败，关闭按钮将直接退出应用: {e}");
            record_tray(app, false);
        }
    }
}

pub fn on_menu_event(app: &AppHandle, event: MenuEvent) {
    match event.id().as_ref() {
        SHOW_ITEM => show(app),
        QUIT_ITEM => quit(app),
        _ => {}
    }
}

/// The close button follows the `close_action` setting, except when there is no
/// tray to hide into.
pub fn on_window_event(window: &Window, event: &WindowEvent) {
    let WindowEvent::CloseRequested { api, .. } = event else {
        return;
    };
    let Some(state) = window.app_handle().try_state::<AppState>() else {
        return;
    };
    let action = state.settings.lock().unwrap().close_action.clone();
    let tray = tray_reachable(window.app_handle());
    match close_move(&action, tray) {
        CloseMove::Quit => {}
        CloseMove::Minimize => {
            api.prevent_close();
            let _ = window.minimize();
        }
        CloseMove::Hide => {
            api.prevent_close();
            let _ = window.hide();
        }
    }
}

#[derive(Debug, PartialEq, Eq)]
enum CloseMove {
    Quit,
    Minimize,
    Hide,
}

/// An unreachably-hidden window has no way back, so `hide` (the default, and
/// anything unrecognized) only hides while the tray can show the window again.
fn close_move(action: &str, tray_reachable: bool) -> CloseMove {
    match action {
        "exit" => CloseMove::Quit,
        "minimize" => CloseMove::Minimize,
        _ if tray_reachable => CloseMove::Hide,
        _ => CloseMove::Quit,
    }
}

/// Whether hiding the window still leaves a way back: the icon has to be on a
/// tray that someone can actually click.
pub fn tray_reachable(app: &AppHandle) -> bool {
    let built = app
        .try_state::<AppState>()
        .is_some_and(|state| state.tray_available.load(Ordering::Acquire));
    if !built {
        return false;
    }
    #[cfg(target_os = "linux")]
    return sni_host_present();
    #[cfg(not(target_os = "linux"))]
    return true;
}

/// libappindicator registers with whatever bus name it likes and returns a
/// working tray even when no StatusNotifier host is listening, so `build()`
/// succeeding proves nothing. Hiding into an invisible tray would leave the app
/// unreachable, so ask the watcher before doing it.
#[cfg(target_os = "linux")]
fn sni_host_present() -> bool {
    use std::time::Duration;
    use zbus::blocking::{connection::Builder, Proxy};

    const WATCHER: &str = "org.kde.StatusNotifierWatcher";
    // Bounded because this runs where a click expects an answer; a wedged host
    // must not be able to freeze the close button.
    let Ok(connection) = Builder::session()
        .and_then(|builder| builder.method_timeout(Duration::from_millis(400)).build())
    else {
        return false;
    };
    let Ok(proxy) = Proxy::new(&connection, WATCHER, "/StatusNotifierWatcher", WATCHER) else {
        return false;
    };
    proxy
        .get_property::<bool>("IsStatusNotifierHostRegistered")
        .unwrap_or(false)
}

#[cfg(test)]
mod tests {
    use super::{close_move, resolve_zoom};

    /// 0 is the handle on the display-computed value; the value is remembered in
    /// a global so both the startup apply and a later settings save see the same
    /// one. A number the webview would refuse never reaches it.
    #[test]
    fn auto_zoom_resolves_to_the_computed_value() {
        assert_eq!(resolve_zoom(0, 80), 80);
        assert_eq!(resolve_zoom(125, 80), 125);
        assert_eq!(resolve_zoom(0, 100), 100);
        assert_eq!(resolve_zoom(30, 100), 50);
        assert_eq!(resolve_zoom(0, 900), 200);
    }

    #[test]
    fn hide_only_when_the_tray_can_show_the_window_again() {
        assert_eq!(close_move("hide", true), super::CloseMove::Hide);
        assert_eq!(close_move("hide", false), super::CloseMove::Quit);
    }

    #[test]
    fn an_unknown_action_is_the_default_hide() {
        assert_eq!(close_move("", true), super::CloseMove::Hide);
        assert_eq!(close_move("minimise", true), super::CloseMove::Hide);
        assert_eq!(close_move("minimise", false), super::CloseMove::Quit);
    }

    #[test]
    fn exit_and_minimize_ignore_the_tray() {
        assert_eq!(close_move("exit", true), super::CloseMove::Quit);
        assert_eq!(close_move("exit", false), super::CloseMove::Quit);
        assert_eq!(close_move("minimize", true), super::CloseMove::Minimize);
        assert_eq!(close_move("minimize", false), super::CloseMove::Minimize);
    }
}
