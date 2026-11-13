//! Status introspection for the background services.

use serde::Serialize;
use tauri::State;

use crate::state::AppState;

#[derive(Serialize)]
pub struct BridgeStatus {
    pub running: bool,
    pub port: Option<u16>,
}

/// Whether the host bridge (browser extension link) is listening, and on
/// which port. Reads `host-bridge.json` rather than keeping in-memory state,
/// so the answer is consistent with what `openvalut-host` sees on disk.
#[tauri::command]
pub fn bridge_status(state: State<'_, AppState>) -> Result<BridgeStatus, String> {
    let text = std::fs::read_to_string(state.config_dir.join("host-bridge.json"))
        .map_err(|e| e.to_string())?;
    let data: serde_json::Value =
        serde_json::from_str(&text).map_err(|e| format!("host-bridge.json 无效: {e}"))?;
    Ok(BridgeStatus {
        running: true,
        port: data
            .get("port")
            .and_then(serde_json::Value::as_u64)
            .map(|p| p as u16),
    })
}
