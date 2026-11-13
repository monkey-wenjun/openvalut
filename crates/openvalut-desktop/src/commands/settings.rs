//! User settings persisted as JSON next to the recents file.

use tauri::{AppHandle, State};

use crate::services::autostart;
use crate::state::{AppState, Settings};

#[tauri::command]
pub fn settings_get(state: State<'_, AppState>) -> Result<Settings, String> {
    Ok(state.settings.lock().unwrap().clone())
}

/// What a proposed save really changes. Kept separate from the command so the
/// keychain-wiping decision can be tested without an `AppHandle`.
#[derive(Debug, PartialEq, Eq)]
struct Changes {
    autostart: Option<bool>,
    forget_all: bool,
}

fn changes(current: &Settings, next: &Settings) -> Changes {
    Changes {
        autostart: (current.autostart != next.autostart).then_some(next.autostart),
        // Only the transition off wipes. Saving an unrelated field while the
        // feature is already off must not reach into the keychain.
        forget_all: current.remember_unlock_days != 0 && next.remember_unlock_days == 0,
    }
}

#[tauri::command]
pub fn settings_set(
    app: AppHandle,
    state: State<'_, AppState>,
    settings: Settings,
) -> Result<(), String> {
    let changes = {
        let current = state.settings.lock().unwrap();
        changes(&current, &settings)
    };
    // Apply the login item before storing the flag: a failed registry (or XDG)
    // write has to look like the failed save it is, not like a saved setting
    // that does nothing.
    if let Some(enabled) = changes.autostart {
        autostart::set_enabled(&app, enabled)?;
    }
    let zoom = settings.ui_zoom;
    *state.settings.lock().unwrap() = settings;
    state.persist_settings();
    // Applied here rather than on the next start: the dialog is still on screen
    // while this returns, so a wrong choice is corrected in front of the user.
    crate::shell::apply_zoom(&app, zoom);
    if changes.forget_all {
        // Turning the feature off really has to forget: an orphaned entry would
        // otherwise sit in the keychain until its window elapsed. This goes
        // through the remember worker rather than calling the keychain directly,
        // because a remember queued by the unlock that just happened would
        // otherwise land after the wipe.
        crate::commands::remembered::forget_everything(&state)?;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::changes;
    use crate::state::Settings;

    fn stored(autostart: bool, days: u32) -> Settings {
        let mut settings = Settings::default();
        settings.autostart = autostart;
        settings.remember_unlock_days = days;
        settings
    }

    #[test]
    fn the_keychain_is_cleared_only_when_remembering_is_switched_off() {
        assert!(changes(&stored(false, 30), &stored(false, 0)).forget_all);
        assert!(!changes(&stored(false, 0), &stored(false, 0)).forget_all);
        assert!(!changes(&stored(false, 7), &stored(false, 30)).forget_all);
    }

    #[test]
    fn an_unrelated_save_touches_neither_the_login_item_nor_the_keychain() {
        let mut next = stored(true, 30);
        next.theme = "light".into();
        let changes = changes(&stored(true, 30), &next);
        assert_eq!(changes.autostart, None);
        assert!(!changes.forget_all);
    }

    #[test]
    fn the_login_item_follows_an_actual_change_with_the_requested_value() {
        assert_eq!(changes(&stored(false, 0), &stored(true, 0)).autostart, Some(true));
        assert_eq!(changes(&stored(true, 0), &stored(false, 0)).autostart, Some(false));
    }
}
