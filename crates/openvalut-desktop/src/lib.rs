//! OpenValut desktop client (Tauri 2).
//!
//! The vault lives in `AppState`; the React frontend talks to it through
//! `#[tauri::command]`s in [`commands`] and reacts to state changes via
//! Tauri events (`vault:unlocked`, `vault:locked`, `vault:dirty`, ...).

mod commands;
mod services;
mod shell;
mod state;

use tauri::Manager;

/// True when this start came from the login item, so the window must not flash
/// before hiding. The lowercase spelling is what the Flutter client's login item
/// sets (`window_prefs.dart`), and an entry it wrote survives this rewrite —
/// Linux env var names are case-sensitive, so both have to be honoured.
fn starts_hidden() -> bool {
    std::env::args().any(|arg| arg == services::autostart::HIDDEN_ARG)
        || std::env::var_os("OPENVALUT_START_HIDDEN").is_some()
        || std::env::var_os("openvalut_START_HIDDEN").is_some()
}

/// One-shot maintenance switch: `openvalut --set-ui-zoom 0` stores the
/// requested zoom and exits without opening a window.
fn requested_ui_zoom<I: Iterator<Item = String>>(mut args: I) -> Option<u32> {
    while let Some(arg) = args.next() {
        if let Some(value) = arg.strip_prefix("--set-ui-zoom=") {
            return value.parse().ok();
        }
        if arg == "--set-ui-zoom" {
            return args.next().and_then(|value| value.parse().ok());
        }
    }
    None
}

/// Scale of the monitor this Hyprland session is focused on, falling back to the
/// first one reported. Unreadable output (another compositor, no socket, old
/// Hyprland without `-j`) answers None, which keeps every caller a no-op rather
/// than a guess.
#[cfg(target_os = "linux")]
fn compositor_scale() -> Option<f64> {
    let Ok(output) = std::process::Command::new("hyprctl")
        .args(["monitors", "-j"])
        .output()
    else {
        return None;
    };
    if !output.status.success() {
        return None;
    }
    serde_json::from_slice::<serde_json::Value>(&output.stdout)
        .ok()
        .and_then(|monitors| focused_scale(&monitors))
}

#[cfg(target_os = "linux")]
fn focused_scale(monitors: &serde_json::Value) -> Option<f64> {
    monitors.as_array().and_then(|rows| {
        rows.iter()
            .find(|row| row.get("focused").and_then(|flag| flag.as_bool()) == Some(true))
            .or_else(|| rows.first())
            .and_then(|row| row.get("scale").and_then(|scale| scale.as_f64()))
    })
}

/// True for a scale that is not a whole number.
#[cfg(target_os = "linux")]
fn fractional(scale: f64) -> bool {
    (scale - scale.round()).abs() > 0.01
}

/// Web content scale that makes one CSS pixel the same physical size as in the
/// rest of the desktop, in percent. This is what `ui_zoom = 0` ("auto") means.
///
/// On the XWayland fallback the compositor maps the surface pixel for pixel, so
/// GTK's integer scale is the whole story: a 1.6 panel with the `GDK_SCALE=2`
/// this desktop exports draws everything 25% large, and dividing the two lands
/// back on 1.6. On native Wayland GTK announces its integer buffer scale and the
/// compositor does the mapping, so there is nothing to compensate.
#[cfg(target_os = "linux")]
fn auto_zoom_percent(on_x11_fallback: bool, gdk_scale: u32, monitor_scale: Option<f64>) -> u32 {
    let (Some(scale), true) = (monitor_scale, on_x11_fallback) else {
        return 100;
    };
    if gdk_scale == 0 {
        return 100;
    }
    ((scale * 100.0) / f64::from(gdk_scale))
        .round()
        .clamp(50.0, 200.0) as u32
}

/// Only a single token (`GDK_BACKEND=x11`) is somebody having chosen a backend.
/// The session-wide list (`GDK_BACKEND=wayland,x11,*`, which is what this
/// desktop exports) just states a preference order and must not disable the
/// fractional-scale fallback, or the fallback would never fire in practice.
#[cfg(target_os = "linux")]
fn backend_is_pinned(requested: Option<&str>) -> bool {
    matches!(requested, Some(value) if !value.is_empty() && !value.contains(','))
}

pub fn run() {
    if let Some(percent) = requested_ui_zoom(std::env::args().skip(1)) {
        let state = state::AppState::load().unwrap_or_else(|error| {
            eprintln!("无法读取设置: {error}");
            std::process::exit(1);
        });
        state.settings.lock().unwrap().ui_zoom = percent;
        state.persist_settings();
        eprintln!("ui_zoom={percent}");
        return;
    }

    // WebKitGTK's DMABUF renderer triggers Wayland protocol errors (Gdk error
    // 71) on some compositors (e.g. Hyprland), killing the window shortly
    // after startup. Fall back to the older render path unless overridden.
    #[cfg(target_os = "linux")]
    if std::env::var_os("WEBKIT_DISABLE_DMABUF_RENDERER").is_none() {
        std::env::set_var("WEBKIT_DISABLE_DMABUF_RENDERER", "1");
    }

    // GTK3 can only scale a Wayland surface by whole numbers. On a fractionally
    // scaled screen (this machine: Hyprland at 1.6) the web content is laid out
    // in physical pixels instead of logical ones, so the whole UI renders at
    // about 60% size and — the part that makes the app unusable — the pointer
    // stops agreeing with what is drawn: clicking a button hits empty space.
    // XWayland leaves the scaling to the compositor, where pixels and input
    // agree again, so prefer it whenever the compositor reports a fractional
    // scale. A compositor this code cannot ask is left on the Wayland path.
    #[cfg(target_os = "linux")]
    let scale = compositor_scale();
    #[cfg(target_os = "linux")]
    if !backend_is_pinned(std::env::var("GDK_BACKEND").ok().as_deref())
        && std::env::var_os("WAYLAND_DISPLAY").is_some()
        && scale.is_some_and(fractional)
    {
        std::env::set_var("GDK_BACKEND", "x11");
    }
    // What "auto" (ui_zoom = 0) means for the display this session is on, kept in
    // a global so both the startup apply and every later settings save resolve it
    // against the same geometry. A missing GDK_SCALE is GTK's own default of 1.
    #[cfg(target_os = "linux")]
    shell::set_auto_zoom(auto_zoom_percent(
        std::env::var("GDK_BACKEND").ok().as_deref() == Some("x11"),
        std::env::var("GDK_SCALE")
            .ok()
            .and_then(|value| value.parse::<u32>().ok())
            .unwrap_or(1),
        scale,
    ));

    tauri::Builder::default()
        // Autostart means a second process at login next to one the user may
        // have clicked; two of these would be two tray icons and two writers on
        // the same recents file. A repeated launch surfaces the window unless
        // that launch was itself an autostart start that lost the race.
        .plugin(tauri_plugin_single_instance::init(|app, args, _cwd| {
            if !args
                .iter()
                .any(|arg| arg == services::autostart::HIDDEN_ARG)
            {
                shell::show(app);
            }
        }))
        // The Linux login item is named after this `app_name`, so pin it to the
        // one every OpenValut build has used: leaving the default would add a
        // second entry next to the existing `openvalut.desktop`.
        .plugin(
            tauri_plugin_autostart::Builder::new()
                .args([services::autostart::HIDDEN_ARG])
                .app_name("openvalut")
                .build(),
        )
        .plugin(tauri_plugin_clipboard_manager::init())
        .plugin(tauri_plugin_dialog::init())
        // Re-apply after the page is live: WebKitGTK can finish setting up the
        // webview after `setup`, and an early zoom call alone is easy to lose.
        .on_page_load(|webview, payload| {
            if matches!(payload.event(), tauri::webview::PageLoadEvent::Finished) {
                if let Some(state) = webview.app_handle().try_state::<state::AppState>() {
                    let zoom = state.settings.lock().unwrap().ui_zoom;
                    shell::apply_zoom(webview.app_handle(), zoom);
                }
            }
        })
        .setup(|app| {
            let state = state::AppState::load()?;
            let ui_zoom = state.settings.lock().unwrap().ui_zoom;
            app.manage(state);
            shell::apply_zoom(app.handle(), ui_zoom);
            services::host_bridge::start(app.handle().clone());
            shell::build_tray(app.handle());
            // The window is created invisible (tauri.conf.json): showing it is
            // the decision of a start the user asked for, while an autostart
            // start stays in the tray. An interactive start also re-points the
            // login entry at this executable, in case an upgrade moved it.
            if !starts_hidden() {
                shell::show(app.handle());
                services::autostart::heal(app.handle());
            } else if !shell::tray_reachable(app.handle()) {
                // Started at login to hide in a tray that does not exist: the
                // window has to appear, or the install looks dead.
                shell::show(app.handle());
            }
            // The browser default menu (重新加载/另存为/打印…) must not appear
            // in a desktop app; the frontend provides its own context menus.
            #[cfg(target_os = "windows")]
            if let Some(win) = app.get_webview_window("main") {
                let _ = win.with_webview(|webview| unsafe {
                    if let Ok(core) = webview.controller().CoreWebView2() {
                        if let Ok(settings) = core.Settings() {
                            let _ = settings.SetAreDefaultContextMenusEnabled(false);
                        }
                    }
                });
            }
            Ok(())
        })
        .on_window_event(shell::on_window_event)
        .on_menu_event(shell::on_menu_event)
        .invoke_handler(tauri::generate_handler![
            commands::vault::vault_status,
            commands::vault::vault_open,
            commands::vault::vault_create,
            commands::vault::vault_lock,
            commands::vault::vault_save,
            commands::vault::vault_save_as,
            commands::vault::vault_get_meta,
            commands::vault::vault_set_name,
            commands::vault::vault_change_master_password,
            commands::vault::recents_list,
            commands::vault::recents_remove,
            commands::vault::recents_clear,
            commands::entries::entry_list,
            commands::entries::entry_get,
            commands::entries::entry_create,
            commands::entries::entry_update,
            commands::entries::entry_set_cli_read,
            commands::entries::entry_delete,
            commands::entries::entry_trash,
            commands::entries::entry_trash_duplicates,
            commands::entries::entry_restore,
            commands::entries::entry_field_value,
            commands::entries::trashed_list,
            commands::entries::group_list,
            commands::entries::group_create,
            commands::entries::group_rename,
            commands::entries::group_trash,
            commands::entries::group_set_cli_read,
            commands::totp::totp_for_entry,
            commands::generator::password_generate,
            commands::audit::audit_run,
            commands::clipboard::clipboard_copy,
            commands::settings::settings_get,
            commands::settings::settings_set,
            commands::remembered::remembered_status,
            commands::remembered::remembered_unlock,
            commands::remembered::remembered_forget,
            commands::bridge::bridge_status,
            commands::cloud::cloud_account_status,
            commands::cloud::cloud_account_save,
            commands::cloud::cloud_vaults,
            commands::cloud::cloud_open,
            commands::cloud::cloud_login,
            commands::cloud::cloud_register,
            commands::cloud::scan_start,
            commands::cloud::scan_poll,
            commands::cloud::scan_cancel,
            commands::generator::password_strength,
            commands::dialog::file_write_text,
            commands::dialog::dialog_pick_kdbx,
            commands::dialog::dialog_pick_save_path,
        ])
        .run(tauri::generate_context!())
        .expect("error while running openvalut desktop");
}

#[cfg(all(test, target_os = "linux"))]
mod scale_tests {
    use super::{
        auto_zoom_percent, backend_is_pinned, focused_scale, fractional, requested_ui_zoom,
    };

    #[test]
    fn ui_zoom_maintenance_switch_accepts_both_spellings() {
        let args = |items: &[&str]| -> std::vec::IntoIter<String> {
            items
                .iter()
                .map(|item| item.to_string())
                .collect::<Vec<_>>()
                .into_iter()
        };
        assert_eq!(requested_ui_zoom(args(&["--set-ui-zoom", "80"])), Some(80));
        assert_eq!(requested_ui_zoom(args(&["--set-ui-zoom=0"])), Some(0));
        assert_eq!(requested_ui_zoom(args(&["--hidden"])), None);
    }

    /// 1.6 is what GTK3 cannot do to a Wayland surface; 1 and 2 are what it can,
    /// so only the fractional answer may switch the backend.
    #[test]
    fn only_a_non_whole_scale_is_fractional() {
        assert!(fractional(1.6));
        assert!(!fractional(2.0));
        assert!(!fractional(1.0));
        // A compositor that reports 1.5999999 means 1.6.
        assert!(fractional(1.5999999));
        // One that reports 1.9999 for an integer 2 is rounding noise, and must
        // not push the session onto the x11 path.
        assert!(!fractional(1.9999));
    }

    /// The session exports the preference list, so only that form has to be
    /// overridable; a lone token is an explicit choice and stays.
    #[test]
    fn only_a_single_backend_token_pins_the_choice() {
        assert!(!backend_is_pinned(Some("wayland,x11,*")));
        assert!(!backend_is_pinned(Some("")));
        assert!(!backend_is_pinned(None));
        assert!(backend_is_pinned(Some("x11")));
        assert!(backend_is_pinned(Some("wayland")));
    }

    /// The window is on the monitor under the pointer, not the first one the
    /// compositor happens to enumerate.
    #[test]
    fn the_focused_monitor_is_the_one_that_is_measured() {
        assert_eq!(
            focused_scale(&serde_json::json!([
                {"scale": 1.0},
                {"scale": 1.6, "focused": true}
            ])),
            Some(1.6)
        );
        // Old Hyprland without the focused flag: the first row is still a scale.
        assert_eq!(
            focused_scale(&serde_json::json!([{"scale": 1.6}])),
            Some(1.6)
        );
        assert_eq!(focused_scale(&serde_json::json!([])), None);
        // Unreadable output answers None, which keeps every caller a no-op
        // rather than a guess.
        assert_eq!(focused_scale(&serde_json::json!([{"name": "eDP-1"}])), None);
        assert_eq!(focused_scale(&serde_json::Value::Null), None);
    }

    /// This machine: a 1.6 panel with the session's GDK_SCALE=2 behind the
    /// XWayland fallback. GTK spends 2 physical pixels per CSS pixel where the
    /// rest of the desktop spends 1.6, so the content comes back by 1.6/2.
    #[test]
    fn fallback_zoom_divides_the_gdk_scale_out_of_the_monitor_scale() {
        assert_eq!(auto_zoom_percent(true, 2, Some(1.6)), 80);
        assert_eq!(auto_zoom_percent(true, 2, Some(1.5)), 75);
        assert_eq!(auto_zoom_percent(true, 1, Some(1.6)), 160);
    }

    /// Nothing to compensate on native Wayland (GTK announces its buffer scale
    /// and the compositor maps it), nor with no compositor to ask, nor with a
    /// GDK_SCALE that cannot be divided by. All three stay neutral.
    #[test]
    fn zoom_is_neutral_without_something_to_compensate() {
        assert_eq!(auto_zoom_percent(false, 2, Some(1.6)), 100);
        assert_eq!(auto_zoom_percent(true, 2, None), 100);
        assert_eq!(auto_zoom_percent(true, 0, Some(1.6)), 100);
    }

    /// apply_zoom clamps to 50..200 before handing the number to the webview, so
    /// an extreme display has to land in that range here rather than be silently
    /// re-clamped by a different rule somewhere else.
    #[test]
    fn zoom_stays_inside_the_range_the_webview_accepts() {
        assert_eq!(auto_zoom_percent(true, 2, Some(0.5)), 50);
        assert_eq!(auto_zoom_percent(true, 2, Some(5.0)), 200);
    }
}
