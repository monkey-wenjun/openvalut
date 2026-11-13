//! Clipboard copy with automatic clearing of sensitive values.

use std::thread;
use std::time::Duration;

use tauri::{AppHandle, State};
use tauri_plugin_clipboard_manager::ClipboardExt;

use crate::state::AppState;

#[tauri::command]
pub fn clipboard_copy(
    app: AppHandle,
    state: State<'_, AppState>,
    value: String,
    sensitive: bool,
) -> Result<(), String> {
    app.clipboard()
        .write_text(&value)
        .map_err(|e| format!("写入剪贴板失败: {e}"))?;

    let clear_seconds = state.settings.lock().unwrap().clipboard_clear_seconds;
    if sensitive && clear_seconds > 0 {
        let app = app.clone();
        thread::spawn(move || {
            thread::sleep(Duration::from_secs(clear_seconds));
            // Only clear if the user hasn't copied something else in the meantime.
            if let Ok(current) = app.clipboard().read_text() {
                if current == value {
                    let _ = app.clipboard().write_text("");
                }
            }
        });
    }
    Ok(())
}
