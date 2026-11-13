//! Native file dialogs (open existing KDBX / choose save location).

use tauri::AppHandle;
use tauri_plugin_dialog::DialogExt;

/// Writes a text file (used to save the cloud Secret Key reminder).
#[tauri::command]
pub fn file_write_text(path: String, content: String) -> Result<(), String> {
    std::fs::write(&path, content).map_err(|e| format!("无法写入 {}: {e}", path))?;
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let _ = std::fs::set_permissions(&path, std::fs::Permissions::from_mode(0o600));
    }
    Ok(())
}

#[tauri::command]
pub fn dialog_pick_kdbx(app: AppHandle) -> Result<Option<String>, String> {
    let file = app
        .dialog()
        .file()
        .add_filter("KDBX 密码库", &["kdbx"])
        .blocking_pick_file();
    Ok(file.map(|p| p.to_string()))
}

#[tauri::command]
pub fn dialog_pick_save_path(
    app: AppHandle,
    default_name: Option<String>,
) -> Result<Option<String>, String> {
    let mut dialog = app.dialog().file().add_filter("KDBX 密码库", &["kdbx"]);
    if let Some(name) = default_name {
        dialog = dialog.set_file_name(name);
    }
    let file = dialog.blocking_save_file();
    Ok(file.map(|p| p.to_string()))
}
