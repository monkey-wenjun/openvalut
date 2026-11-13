//! Loopback HTTP bridge for the Chrome extension's native messaging host
//! (`openvalut-host`), protocol-compatible with the Flutter client's
//! `HostBridge` (openvalut/lib/host_bridge/host_bridge.dart).
//!
//! The server listens on 127.0.0.1 with a random port and requires a bearer
//! token; both are published in `host-bridge.json` (0600) inside the app's
//! config directory. `GET /vaults` serves encrypted KDBX bytes plus the
//! transformed key so the host can reopen the vault without the master
//! password; all entry mutations are delegated back to the app (which holds
//! the real credentials) and are persisted to disk immediately.

use std::sync::atomic::Ordering;
use std::sync::Arc;

use axum::body::Bytes;
use axum::extract::State;
use axum::http::{HeaderMap, StatusCode};
use axum::response::{IntoResponse, Response};
use axum::routing::{get, post};
use axum::{Json, Router};
use base64::engine::general_purpose::{STANDARD as B64, URL_SAFE_NO_PAD as B64URL};
use base64::Engine;
use rand::RngCore;
use serde::Deserialize;
use serde_json::{json, Value};
use sha2::{Digest, Sha256};
use tauri::{AppHandle, Emitter, Manager};

use crate::state::AppState;

/// The serialized KDBX snapshot served by `GET /vaults`, cached until the
/// content generation changes (KDF serialization costs an Argon2 run).
#[derive(Clone)]
struct Snapshot {
    generation: u64,
    vaults: Value,
}

struct Bridge<R: tauri::Runtime> {
    token: String,
    app: AppHandle<R>,
    snapshot: tokio::sync::Mutex<Option<Snapshot>>,
}

const KDBX4_KDF_PARAMS_HEADER_ID: u8 = 11;
const KDBX4_HEADER_OFFSET: usize = 12;

/// Spawns the bridge server in the background. It runs for the lifetime of
/// the app and publishes `host-bridge.json` once bound.
pub fn start(app: AppHandle) {
    tauri::async_runtime::spawn(async move {
        if let Err(e) = run(app).await {
            eprintln!("host bridge failed to start: {e}");
        }
    });
}

async fn run(app: AppHandle) -> Result<(), String> {
    let token = random_token();
    let listener = tokio::net::TcpListener::bind(("127.0.0.1", 0))
        .await
        .map_err(|e| format!("bind loopback: {e}"))?;
    let port = listener
        .local_addr()
        .map_err(|e| e.to_string())?
        .port();

    let state = app.state::<AppState>();
    let config_dir = state.config_dir.clone();
    std::fs::create_dir_all(&config_dir).map_err(|e| e.to_string())?;
    write_bridge_info(&config_dir, port, &token)?;

    let bridge = Arc::new(Bridge {
        token,
        app: app.clone(),
        snapshot: tokio::sync::Mutex::new(None),
    });

    println!("host bridge listening on 127.0.0.1:{port}");
    axum::serve(listener, router(bridge))
        .await
        .map_err(|e| format!("serve: {e}"))
}

fn router<R: tauri::Runtime>(bridge: Arc<Bridge<R>>) -> Router {
    Router::new()
        .route("/status", get(status::<R>))
        .route("/vaults", get(vaults::<R>))
        .route("/createEntry", post(create_entry::<R>))
        .route("/updateEntry", post(update_entry::<R>))
        .route("/deleteEntry", post(delete_entry::<R>))
        .route("/saveVault", post(save_vault::<R>))
        .route("/showWindow", post(show_window::<R>))
        .with_state(bridge)
}

fn random_token() -> String {
    let mut buf = [0u8; 32];
    rand::rngs::OsRng.fill_bytes(&mut buf);
    B64URL.encode(buf)
}

fn write_bridge_info(config_dir: &std::path::Path, port: u16, token: &str) -> Result<(), String> {
    let path = config_dir.join("host-bridge.json");
    let text = json!({"port": port, "token": token}).to_string();
    std::fs::write(&path, text).map_err(|e| format!("write host-bridge.json: {e}"))?;
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        std::fs::set_permissions(&path, std::fs::Permissions::from_mode(0o600))
            .map_err(|e| format!("chmod host-bridge.json: {e}"))?;
    }
    Ok(())
}

// ---------------------------------------------------------------------------
// response helpers
// ---------------------------------------------------------------------------

fn unauthorized() -> Response {
    StatusCode::UNAUTHORIZED.into_response()
}

fn ok_json(value: Value) -> Response {
    Json(value).into_response()
}

fn err_json(message: impl Into<String>) -> Response {
    Json(json!({"ok": false, "error": message.into()})).into_response()
}

fn conflict(message: &str) -> Response {
    (StatusCode::CONFLICT, Json(json!({"ok": false, "error": message}))).into_response()
}

fn authorized(headers: &HeaderMap, token: &str) -> bool {
    headers
        .get("authorization")
        .and_then(|v| v.to_str().ok())
        .map(|v| v == format!("Bearer {token}"))
        .unwrap_or(false)
}

// ---------------------------------------------------------------------------
// vault helpers (run on blocking threads)
// ---------------------------------------------------------------------------

/// True if `id` refers to the open vault (path or database name).
fn vault_id_matches<R: tauri::Runtime>(app: &AppHandle<R>, id: &str) -> bool {
    let state = app.state::<AppState>();
    let guard = state.vault.read().unwrap();
    guard.as_ref().map(|h| h.matches(id)).unwrap_or(false)
}

/// Runs a mutation against the open vault, then serializes and persists it to
/// disk, bumps the content generation, and notifies the UI. Bridge mutations
/// behave like the Flutter bridge's `saveFile` calls: always saved, never
/// left dirty.
fn mutate_and_save<T, R: tauri::Runtime>(
    app: &AppHandle<R>,
    f: impl FnOnce(&mut openvalut_core::Vault) -> Result<T, String>,
) -> Result<T, String> {
    let state = app.state::<AppState>();
    let guard = state.vault.read().unwrap();
    let handle = guard.as_ref().ok_or("密码库未解锁")?;
    let out = {
        let mut vault = handle.vault.lock().unwrap();
        let out = f(&mut vault)?;
        drop(vault);
        handle.persist()?;
        out
    };
    handle.dirty.store(false, Ordering::Release);
    drop(guard);
    state.touch();
    let _ = app.emit("vault:changed", ());
    Ok(out)
}

/// base64(SHA256(raw KDF variant-dictionary bytes)), matching the Dart
/// `KdbxHeader.kdfFingerprint`. Consumers use it to detect that a stored
/// transformed key no longer matches the file's KDF parameters.
fn kdf_fingerprint(kdbx_bytes: &[u8]) -> Option<String> {
    let mut pos = KDBX4_HEADER_OFFSET;
    loop {
        let entry_type = *kdbx_bytes.get(pos)?;
        let len_bytes = kdbx_bytes.get(pos + 1..pos + 5)?;
        let len = u32::from_le_bytes(len_bytes.try_into().ok()?) as usize;
        let buffer = kdbx_bytes.get(pos + 5..pos + 5 + len)?;
        pos += 5 + len;
        if entry_type == 0 {
            return None;
        }
        if entry_type == KDBX4_KDF_PARAMS_HEADER_ID {
            return Some(B64.encode(Sha256::digest(buffer)));
        }
    }
}

/// Builds the vault list for `GET /vaults`. Each save rotates the KDF seed,
/// so the transformed key is captured together with the bytes it belongs to.
fn build_snapshot<R: tauri::Runtime>(app: &AppHandle<R>) -> Result<Value, String> {
    let state = app.state::<AppState>();
    let guard = state.vault.read().unwrap();
    let handle = guard
        .as_ref()
        .ok_or_else(|| "密码库未解锁".to_string())?;
    let vault = handle.vault.lock().unwrap();

    let (bytes, transformed_key) = vault
        .save_with_transformed_key(&handle.key)
        .map_err(|e| format!("cannot serialize vault: {e}"))?;
    let transformed_key =
        transformed_key.ok_or_else(|| "vault did not produce a transformed key".to_string())?;
    let fingerprint = kdf_fingerprint(&bytes)
        .ok_or_else(|| "cannot compute KDF fingerprint".to_string())?;
    let id = handle.id_string();
    let name = vault
        .name()
        .map(str::to_string)
        .unwrap_or_else(|| {
            handle
                .source
                .local_path()
                .and_then(|p| p.file_stem().map(|s| s.to_string_lossy().to_string()))
                .unwrap_or_else(|| id.clone())
        });

    Ok(json!([{
        "id": id,
        "name": name,
        "kdbxBase64": B64.encode(bytes),
        "transformedKeyBase64": B64.encode(transformed_key),
        "kdfFingerprint": fingerprint,
    }]))
}

/// Extracts `(key, value, protected)` tuples from a bridge customFields map.
/// Values are either plain strings or `{value, protect}` objects.
fn parse_custom_fields(map: &serde_json::Map<String, Value>) -> Vec<(String, String, bool)> {
    let mut out = Vec::new();
    for (key, value) in map {
        match value {
            Value::String(s) => out.push((key.clone(), s.clone(), false)),
            Value::Object(obj) => {
                let Some(text) = obj.get("value").and_then(Value::as_str) else {
                    continue;
                };
                let protect = obj.get("protect").and_then(Value::as_bool).unwrap_or(false);
                out.push((key.clone(), text.to_string(), protect));
            }
            _ => {}
        }
    }
    out
}

// ---------------------------------------------------------------------------
// endpoints
// ---------------------------------------------------------------------------

async fn status<R: tauri::Runtime>(
    State(bridge): State<Arc<Bridge<R>>>,
    headers: HeaderMap,
) -> Response {
    if !authorized(&headers, &bridge.token) {
        return unauthorized();
    }
    let state = bridge.app.state::<AppState>();
    let unlocked = state.vault.read().unwrap().is_some();
    ok_json(json!({
        "ok": true,
        "generation": state.content_version().to_string(),
        "unlocked": unlocked,
    }))
}

async fn vaults<R: tauri::Runtime>(
    State(bridge): State<Arc<Bridge<R>>>,
    headers: HeaderMap,
) -> Response {
    if !authorized(&headers, &bridge.token) {
        return unauthorized();
    }
    let state = bridge.app.state::<AppState>();
    let start_gen = state.content_version();
    if state.vault.read().unwrap().is_none() {
        return conflict("Vault session changed while creating the snapshot.");
    }

    let mut guard = bridge.snapshot.lock().await;
    if let Some(snap) = guard.as_ref() {
        if snap.generation == start_gen {
            return ok_json(json!({"vaults": snap.vaults.clone()}));
        }
    }

    let app = bridge.app.clone();
    let built = tokio::task::spawn_blocking(move || build_snapshot(&app)).await;
    match built {
        Ok(Ok(vaults)) => {
            if state.content_version() != start_gen {
                return conflict("Vault session changed while creating the snapshot.");
            }
            *guard = Some(Snapshot {
                generation: start_gen,
                vaults: vaults.clone(),
            });
            ok_json(json!({"vaults": vaults}))
        }
        Ok(Err(e)) => err_json(e),
        Err(e) => err_json(format!("snapshot build failed: {e}")),
    }
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct CreateEntryBody {
    id: Option<String>,
    title: Option<String>,
    username: Option<String>,
    url: Option<String>,
    custom_fields: Option<serde_json::Map<String, Value>>,
}

async fn create_entry<R: tauri::Runtime>(
    State(bridge): State<Arc<Bridge<R>>>,
    headers: HeaderMap,
    body: Bytes,
) -> Response {
    if !authorized(&headers, &bridge.token) {
        return unauthorized();
    }
    let parsed: CreateEntryBody = match serde_json::from_slice(&body) {
        Ok(v) => v,
        Err(e) => return err_json(e.to_string()),
    };
    let Some(id) = parsed.id else {
        return err_json("Missing required fields.");
    };
    if !vault_id_matches(&bridge.app, &id) {
        return err_json(format!("Vault {id} is not open."));
    }

    let app = bridge.app.clone();
    let result = tokio::task::spawn_blocking(move || {
        mutate_and_save(&app, |vault| {
            let request = openvalut_core::CreateEntryRequest {
                title: parsed.title.clone().unwrap_or_default(),
                username: parsed.username.clone().unwrap_or_default(),
                url: parsed.url.clone().unwrap_or_default(),
                ..Default::default()
            };
            let uuid = vault
                .add_entry(&request)
                .map_err(|e| format!("create entry failed: {e}"))?;
            if let Some(custom) = &parsed.custom_fields {
                let fields = parse_custom_fields(custom);
                vault
                    .set_entry_custom_fields(&uuid, &fields)
                    .map_err(|e| format!("set custom fields failed: {e}"))?;
            }
            Ok(uuid)
        })
    })
    .await;

    match result {
        Ok(Ok(uuid)) => {
            let _ = bridge.app.emit("bridge:entry_created", ());
            ok_json(json!({"ok": true, "entryUuid": uuid}))
        }
        Ok(Err(e)) => err_json(e),
        Err(e) => err_json(format!("create entry failed: {e}")),
    }
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct UpdateEntryBody {
    id: Option<String>,
    entry_uuid: Option<String>,
    title: Option<String>,
    username: Option<String>,
    password: Option<String>,
    url: Option<String>,
    notes: Option<String>,
    custom_fields: Option<serde_json::Map<String, Value>>,
}

async fn update_entry<R: tauri::Runtime>(
    State(bridge): State<Arc<Bridge<R>>>,
    headers: HeaderMap,
    body: Bytes,
) -> Response {
    if !authorized(&headers, &bridge.token) {
        return unauthorized();
    }
    let parsed: UpdateEntryBody = match serde_json::from_slice(&body) {
        Ok(v) => v,
        Err(e) => return err_json(e.to_string()),
    };
    let (Some(id), Some(entry_uuid)) = (parsed.id, parsed.entry_uuid) else {
        return err_json("Missing required fields.");
    };
    if !vault_id_matches(&bridge.app, &id) {
        return err_json(format!("Vault {id} is not open."));
    }

    let app = bridge.app.clone();
    let result = tokio::task::spawn_blocking(move || {
        mutate_and_save(&app, |vault| {
            let request = openvalut_core::UpdateEntryRequest {
                title: parsed.title,
                username: parsed.username,
                password: parsed.password,
                url: parsed.url,
                notes: parsed.notes,
                ..Default::default()
            };
            vault
                .update_entry(&entry_uuid, &request)
                .map_err(|e| format!("update entry failed: {e}"))?;
            if let Some(custom) = &parsed.custom_fields {
                let fields = parse_custom_fields(custom);
                vault
                    .set_entry_custom_fields(&entry_uuid, &fields)
                    .map_err(|e| format!("set custom fields failed: {e}"))?;
            }
            Ok(())
        })
    })
    .await;

    match result {
        Ok(Ok(())) => ok_json(json!({"ok": true})),
        Ok(Err(e)) => err_json(e),
        Err(e) => err_json(format!("update entry failed: {e}")),
    }
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct DeleteEntryBody {
    id: Option<String>,
    entry_uuid: Option<String>,
}

async fn delete_entry<R: tauri::Runtime>(
    State(bridge): State<Arc<Bridge<R>>>,
    headers: HeaderMap,
    body: Bytes,
) -> Response {
    if !authorized(&headers, &bridge.token) {
        return unauthorized();
    }
    let parsed: DeleteEntryBody = match serde_json::from_slice(&body) {
        Ok(v) => v,
        Err(e) => return err_json(e.to_string()),
    };
    let (Some(id), Some(entry_uuid)) = (parsed.id, parsed.entry_uuid) else {
        return err_json("Missing required fields.");
    };
    if !vault_id_matches(&bridge.app, &id) {
        return err_json(format!("Vault {id} is not open."));
    }

    let app = bridge.app.clone();
    let result = tokio::task::spawn_blocking(move || {
        mutate_and_save(&app, |vault| {
            vault
                .delete_entry(&entry_uuid)
                .map_err(|e| format!("delete entry failed: {e}"))
        })
    })
    .await;

    match result {
        Ok(Ok(())) => ok_json(json!({"ok": true})),
        Ok(Err(e)) => err_json(e),
        Err(e) => err_json(format!("delete entry failed: {e}")),
    }
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct SaveVaultBody {
    id: Option<String>,
    kdbx_base64: Option<String>,
    transformed_key_base64: Option<String>,
    kdf_fingerprint: Option<String>,
}

async fn save_vault<R: tauri::Runtime>(
    State(bridge): State<Arc<Bridge<R>>>,
    headers: HeaderMap,
    body: Bytes,
) -> Response {
    if !authorized(&headers, &bridge.token) {
        return unauthorized();
    }
    let parsed: SaveVaultBody = match serde_json::from_slice(&body) {
        Ok(v) => v,
        Err(e) => return err_json(e.to_string()),
    };
    let (Some(id), Some(kdbx_base64), Some(tk_base64), Some(_kdf_fingerprint)) = (
        parsed.id,
        parsed.kdbx_base64,
        parsed.transformed_key_base64,
        parsed.kdf_fingerprint,
    ) else {
        return err_json("Missing required fields.");
    };
    if !vault_id_matches(&bridge.app, &id) {
        return err_json(format!("Vault {id} is not open."));
    }

    let bytes = match B64.decode(kdbx_base64.as_bytes()) {
        Ok(b) => b,
        Err(e) => return err_json(format!("invalid kdbxBase64: {e}")),
    };
    let key_bytes = match B64.decode(tk_base64.as_bytes()) {
        Ok(b) => b,
        Err(e) => return err_json(format!("invalid transformedKeyBase64: {e}")),
    };
    let Ok(transformed_key) = <[u8; 32]>::try_from(key_bytes.as_slice()) else {
        return err_json("invalid transformed key length");
    };

    let app = bridge.app.clone();
    let result = tokio::task::spawn_blocking(move || -> Result<(), String> {
        // Validate the incoming bytes with the provided transformed key
        // before accepting them, so a bad payload can't corrupt the session.
        let vault = openvalut_core::Vault::open(
            &bytes,
            &openvalut_core::VaultKey::with_transformed_key(transformed_key),
        )
        .map_err(|e| format!("invalid vault bytes: {e}"))?;
        let state = app.state::<AppState>();
        let guard = state.vault.read().unwrap();
        let handle = guard
            .as_ref()
            .ok_or_else(|| "密码库未解锁".to_string())?;
        *handle.vault.lock().unwrap() = vault;
        drop(guard);
        state.touch();
        let _ = app.emit("vault:changed", ());
        Ok(())
    })
    .await;

    match result {
        Ok(Ok(())) => ok_json(json!({"ok": true})),
        Ok(Err(e)) => err_json(e),
        Err(e) => err_json(format!("save vault failed: {e}")),
    }
}

async fn show_window<R: tauri::Runtime>(
    State(bridge): State<Arc<Bridge<R>>>,
    headers: HeaderMap,
) -> Response {
    if !authorized(&headers, &bridge.token) {
        return unauthorized();
    }
    if let Some(window) = bridge.app.get_webview_window("main") {
        let _ = window.show();
        let _ = window.unminimize();
        let _ = window.set_focus();
    }
    ok_json(json!({"ok": true}))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::state::VaultHandle;
    use axum::body::Body;
    use axum::http::Request;
    use tauri::Manager;
    use tower::ServiceExt;

    const TOKEN: &str = "test-bridge-token";

    struct TestApp {
        router: Router,
        handle: AppHandle<tauri::test::MockRuntime>,
        vault_path: std::path::PathBuf,
        _dir: tempfile::TempDir,
    }

    async fn request(
        router: &Router,
        method: &str,
        path: &str,
        body: Option<Value>,
        token: Option<&str>,
    ) -> (StatusCode, Value) {
        let mut builder = Request::builder().method(method).uri(path);
        if let Some(t) = token {
            builder = builder.header("authorization", format!("Bearer {t}"));
        }
        let request = match body {
            Some(v) => builder
                .header("content-type", "application/json")
                .body(Body::from(v.to_string()))
                .unwrap(),
            None => builder.body(Body::empty()).unwrap(),
        };
        let response = router.clone().oneshot(request).await.unwrap();
        let status = response.status();
        let bytes = axum::body::to_bytes(response.into_body(), usize::MAX)
            .await
            .unwrap();
        let value = if bytes.is_empty() {
            Value::Null
        } else {
            serde_json::from_slice(&bytes).unwrap()
        };
        (status, value)
    }

    /// Builds a mock Tauri app with a real (Argon2-keyed) vault unlocked, plus
    /// the bridge router in front of it.
    fn setup() -> TestApp {
        let dir = tempfile::tempdir().unwrap();
        let config_dir = dir.path().to_path_buf();
        let vault_path = dir.path().join("test.kdbx");

        let key = openvalut_core::VaultKey::with_password("master-pw");
        let vault = openvalut_core::Vault::create_new("Bridge Test").unwrap();
        let bytes = vault.save(&key).unwrap();
        std::fs::write(&vault_path, bytes).unwrap();

        let app = tauri::test::mock_app();
        let handle = app.handle().clone();
        let state = AppState::load_in(config_dir).unwrap();
        state.content_version.store(7, Ordering::Release);
        handle.manage(state);
        {
            let state = handle.state::<AppState>();
            let mut guard = state.vault.write().unwrap();
            *guard = Some(VaultHandle {
                vault: std::sync::Mutex::new(vault),
                key,
                source: crate::state::VaultSource::Local { path: vault_path.clone() },
                dirty: std::sync::atomic::AtomicBool::new(false),
            });
        }

        let bridge = Arc::new(Bridge {
            token: TOKEN.to_string(),
            app: handle.clone(),
            snapshot: tokio::sync::Mutex::new(None),
        });
        TestApp {
            router: router(bridge),
            handle,
            vault_path,
            _dir: dir,
        }
    }

    #[tokio::test]
    async fn status_and_authentication() {
        let app = setup();
        let (status, _) = request(&app.router, "GET", "/status", None, None).await;
        assert_eq!(status, StatusCode::UNAUTHORIZED);

        let (status, body) = request(&app.router, "GET", "/status", None, Some(TOKEN)).await;
        assert_eq!(status, StatusCode::OK);
        assert_eq!(body["generation"], json!("7"));
        assert_eq!(body["unlocked"], json!(true));
    }

    /// Mirrors what `openvalut-host` does with `GET /vaults`: decode the KDBX
    /// bytes and reopen the vault with the served transformed key alone.
    #[tokio::test]
    async fn vaults_snapshot_reopens_with_transformed_key() {
        let app = setup();
        let (status, body) = request(&app.router, "GET", "/vaults", None, Some(TOKEN)).await;
        assert_eq!(status, StatusCode::OK);

        let vault = &body["vaults"][0];
        assert_eq!(vault["id"], json!(app.vault_path.to_string_lossy()));
        assert_eq!(vault["name"], json!("Bridge Test"));
        assert!(vault["kdfFingerprint"].as_str().unwrap().len() == 44);

        let kdbx_bytes = B64.decode(vault["kdbxBase64"].as_str().unwrap()).unwrap();
        let tk_bytes = B64
            .decode(vault["transformedKeyBase64"].as_str().unwrap())
            .unwrap();
        let transformed_key: [u8; 32] = tk_bytes.try_into().unwrap();
        let reopened = openvalut_core::Vault::open(
            &kdbx_bytes,
            &openvalut_core::VaultKey::with_transformed_key(transformed_key),
        )
        .unwrap();
        assert_eq!(reopened.name(), Some("Bridge Test"));

        // Cached snapshot is served with an unchanged generation.
        let (status, body2) = request(&app.router, "GET", "/vaults", None, Some(TOKEN)).await;
        assert_eq!(status, StatusCode::OK);
        assert_eq!(body2["vaults"][0]["kdbxBase64"], vault["kdbxBase64"]);
    }

    #[tokio::test]
    async fn locked_vault_conflicts() {
        let app = setup();
        let state = app.handle.state::<AppState>();
        *state.vault.write().unwrap() = None;
        state.touch();
        drop(state);
        let (status, body) = request(&app.router, "GET", "/vaults", None, Some(TOKEN)).await;
        assert_eq!(status, StatusCode::CONFLICT);
        assert_eq!(body["ok"], json!(false));
    }

    #[tokio::test]
    async fn create_update_delete_entry_round_trip() {
        let app = setup();
        let id = app.vault_path.to_string_lossy().to_string();

        let (_, body) = request(
            &app.router,
            "POST",
            "/createEntry",
            Some(json!({
                "id": id,
                "title": "Example",
                "username": "alice",
                "url": "https://example.com",
                "customFields": {
                    "plain": "hello",
                    "secret": {"value": "s3cret", "protect": true},
                    "skip": {"protect": true},
                },
            })),
            Some(TOKEN),
        )
        .await;
        assert_eq!(body["ok"], json!(true), "create failed: {body}");
        let uuid = body["entryUuid"].as_str().unwrap().to_string();

        // The mutation was persisted to disk and honors the protect flag.
        let disk_bytes = std::fs::read(&app.vault_path).unwrap();
        let disk = openvalut_core::Vault::open(
            &disk_bytes,
            &openvalut_core::VaultKey::with_password("master-pw"),
        )
        .unwrap();
        let entry = disk.entries().into_iter().find(|e| e.uuid == uuid).unwrap();
        assert_eq!(entry.title, "Example");
        assert_eq!(entry.username, "alice");
        assert_eq!(entry.url, "https://example.com");
        assert!(entry.custom.iter().any(|(k, _)| k == "plain"));
        assert!(!entry.custom.iter().any(|(k, _)| k == "skip"));

        let (_, body) = request(
            &app.router,
            "POST",
            "/updateEntry",
            Some(json!({
                "id": id,
                "entryUuid": uuid,
                "title": "Renamed",
                "password": "new-password",
            })),
            Some(TOKEN),
        )
        .await;
        assert_eq!(body["ok"], json!(true), "update failed: {body}");

        let (_, body) = request(
            &app.router,
            "POST",
            "/updateEntry",
            Some(json!({
                "id": id,
                "entryUuid": uuid,
                "customFields": {"plain": "updated"},
            })),
            Some(TOKEN),
        )
        .await;
        assert_eq!(body["ok"], json!(true), "custom update failed: {body}");

        // Entries modified through the bridge are visible through /vaults.
        let (_, body) = request(&app.router, "GET", "/vaults", None, Some(TOKEN)).await;
        let kdbx_bytes = B64
            .decode(body["vaults"][0]["kdbxBase64"].as_str().unwrap())
            .unwrap();
        let tk_bytes = B64
            .decode(body["vaults"][0]["transformedKeyBase64"].as_str().unwrap())
            .unwrap();
        let tk: [u8; 32] = tk_bytes.try_into().unwrap();
        let vault = openvalut_core::Vault::open(
            &kdbx_bytes,
            &openvalut_core::VaultKey::with_transformed_key(tk),
        )
        .unwrap();
        let entry = vault.entries().into_iter().find(|e| e.uuid == uuid).unwrap();
        assert_eq!(entry.title, "Renamed");

        let (_, body) = request(
            &app.router,
            "POST",
            "/deleteEntry",
            Some(json!({"id": id, "entryUuid": uuid})),
            Some(TOKEN),
        )
        .await;
        assert_eq!(body["ok"], json!(true), "delete failed: {body}");

        let disk_bytes = std::fs::read(&app.vault_path).unwrap();
        let disk = openvalut_core::Vault::open(
            &disk_bytes,
            &openvalut_core::VaultKey::with_password("master-pw"),
        )
        .unwrap();
        assert!(disk.entries().is_empty());
    }

    #[tokio::test]
    async fn save_vault_rejects_mismatched_key() {
        let app = setup();
        let id = app.vault_path.to_string_lossy().to_string();

        let (status, body) = request(
            &app.router,
            "POST",
            "/saveVault",
            Some(json!({
                "id": id,
                "kdbxBase64": B64.encode(b"not a kdbx file"),
                "transformedKeyBase64": B64.encode([0u8; 32]),
                "kdfFingerprint": "x",
            })),
            Some(TOKEN),
        )
        .await;
        assert_eq!(status, StatusCode::OK);
        assert_eq!(body["ok"], json!(false));
        assert!(body["error"].as_str().unwrap().contains("invalid vault bytes"));
    }

    #[tokio::test]
    async fn unknown_vault_id_rejected() {
        let app = setup();
        let (_, body) = request(
            &app.router,
            "POST",
            "/createEntry",
            Some(json!({"id": "no-such-vault", "title": "x"})),
            Some(TOKEN),
        )
        .await;
        assert_eq!(body["ok"], json!(false));
        assert_eq!(body["error"], json!("Vault no-such-vault is not open."));

        let (_, body) = request(
            &app.router,
            "POST",
            "/createEntry",
            Some(json!({"id": "Bridge Test", "title": "by name"})),
            Some(TOKEN),
        )
        .await;
        assert_eq!(body["ok"], json!(true), "name lookup failed: {body}");
    }

    #[test]
    fn custom_fields_parse_both_shapes() {
        let mut map = serde_json::Map::new();
        map.insert("plain".into(), Value::String("v".into()));
        map.insert("secret".into(), json!({"value": "s", "protect": true}));
        map.insert("skip".into(), json!({"protect": true}));
        let fields = parse_custom_fields(&map);
        assert_eq!(
            fields,
            vec![
                ("plain".to_string(), "v".to_string(), false),
                ("secret".to_string(), "s".to_string(), true),
            ]
        );
    }

    #[test]
    fn fingerprint_follows_kdf_seed_rotation() {
        let key = openvalut_core::VaultKey::with_password("pw");
        let vault = openvalut_core::Vault::create_new("T").unwrap();
        let bytes = vault.save(&key).unwrap();
        let fp = kdf_fingerprint(&bytes).expect("kdf params must be present");
        assert_eq!(fp.len(), 44, "base64(sha256) is 44 chars");

        let bytes2 = vault.save(&key).unwrap();
        let fp2 = kdf_fingerprint(&bytes2).unwrap();
        assert_ne!(fp, fp2, "a re-save rotates the KDF seed");
    }
}
