//! Vault lifecycle: open/create/lock/save plus the recents list.

use std::fs;
use std::sync::atomic::Ordering;

use openvalut_core::{Vault, VaultKey};
use serde::Serialize;
use tauri::{AppHandle, Emitter, State};

use crate::state::{AppState, RecentFile, VaultHandle};

#[derive(Serialize, Clone)]
pub struct VaultMeta {
    pub locked: bool,
    pub name: Option<String>,
    pub path: Option<String>,
    pub dirty: bool,
    pub cloud: bool,
    pub entry_count: usize,
}

impl VaultMeta {
    fn locked() -> Self {
        Self {
            locked: true,
            name: None,
            path: None,
            dirty: false,
            cloud: false,
            entry_count: 0,
        }
    }

    fn from_handle(handle: &VaultHandle) -> Self {
        let vault = handle.vault.lock().unwrap();
        Self {
            locked: false,
            name: vault.name().map(|s| s.to_string()),
            path: Some(handle.id_string()),
            dirty: handle.dirty.load(Ordering::Acquire),
            cloud: matches!(handle.source, crate::state::VaultSource::Cloud { .. }),
            entry_count: vault.entries().len(),
        }
    }
}

pub(crate) fn open_key(password: &str, keyfile_path: Option<&str>) -> Result<VaultKey, String> {
    Ok(match keyfile_path {
        Some(p) => {
            let keyfile = fs::read(p).map_err(|e| format!("读取密钥文件失败: {e}"))?;
            VaultKey::with_password_and_keyfile(password, keyfile)
        }
        None => VaultKey::with_password(password),
    })
}

#[tauri::command]
pub fn vault_status(state: State<'_, AppState>) -> Result<VaultMeta, String> {
    let guard = state.vault.read().unwrap();
    Ok(match guard.as_ref() {
        Some(h) => VaultMeta::from_handle(h),
        None => VaultMeta::locked(),
    })
}

#[tauri::command]
pub fn vault_open(
    app: AppHandle,
    state: State<'_, AppState>,
    path: String,
    password: String,
    keyfile_path: Option<String>,
) -> Result<VaultMeta, String> {
    let bytes = fs::read(&path).map_err(|e| format!("打开密码库文件失败: {e}"))?;
    let key = open_key(&password, keyfile_path.as_deref())?;
    let vault = Vault::open(&bytes, &key).map_err(|e| format!("解锁失败: {e}"))?;
    let name = vault.name().unwrap_or("openvalut").to_string();
    crate::commands::remembered::remember_local(
        &state,
        &path,
        &name,
        &password,
        keyfile_path.as_deref(),
    );
    install_local_handle(&app, &state, &path, &name, vault, key)
}

/// Installs an opened local vault as the current one and announces the unlock.
pub(crate) fn install_local_handle(
    app: &AppHandle,
    state: &AppState,
    path: &str,
    name: &str,
    vault: Vault,
    key: VaultKey,
) -> Result<VaultMeta, String> {
    let mut guard = state.vault.write().unwrap();
    *guard = Some(VaultHandle {
        vault: std::sync::Mutex::new(vault),
        key,
        source: crate::state::VaultSource::Local { path: path.into() },
        dirty: std::sync::atomic::AtomicBool::new(false),
    });
    drop(guard);

    state.add_recent(path, name);
    state.touch();
    let meta = vault_status_inner(state)?;
    let _ = app.emit("vault:unlocked", &meta);
    Ok(meta)
}

pub(crate) fn vault_status_inner(state: &AppState) -> Result<VaultMeta, String> {
    let guard = state.vault.read().unwrap();
    Ok(match guard.as_ref() {
        Some(h) => VaultMeta::from_handle(h),
        None => VaultMeta::locked(),
    })
}

#[tauri::command]
pub fn vault_create(
    app: AppHandle,
    state: State<'_, AppState>,
    path: String,
    name: String,
    password: String,
    keyfile_path: Option<String>,
) -> Result<VaultMeta, String> {
    if fs::metadata(&path).is_ok() {
        return Err("文件已存在".into());
    }
    let vault = Vault::create_new(&name).map_err(|e| e.to_string())?;
    let key = open_key(&password, keyfile_path.as_deref())?;
    let bytes = vault.save(&key).map_err(|e| e.to_string())?;
    fs::write(&path, &bytes).map_err(|e| format!("写入密码库文件失败: {e}"))?;
    crate::commands::remembered::remember_local(
        &state,
        &path,
        &name,
        &password,
        keyfile_path.as_deref(),
    );
    install_local_handle(&app, &state, &path, &name, vault, key)
}

#[tauri::command]
pub fn vault_lock(app: AppHandle, state: State<'_, AppState>) -> Result<VaultMeta, String> {
    *state.vault.write().unwrap() = None;
    state.touch();
    let _ = app.emit("vault:locked", ());
    Ok(VaultMeta::locked())
}

#[tauri::command]
pub fn vault_save(state: State<'_, AppState>) -> Result<VaultMeta, String> {
    let (meta, recent_path) = {
        let guard = state.vault.read().unwrap();
        let handle = guard.as_ref().ok_or("密码库未解锁")?;
        handle.persist()?;
        handle.dirty.store(false, Ordering::Release);
        let meta = VaultMeta::from_handle(handle);
        let recent = handle
            .source
            .local_path()
            .map(|p| p.to_string_lossy().to_string());
        (meta, recent)
    };
    if let Some(path) = recent_path {
        let name = meta.name.clone().unwrap_or_default();
        state.add_recent(&path, &name);
    }
    crate::commands::remembered::touch_saved(&state);
    Ok(meta)
}

#[tauri::command]
pub fn vault_save_as(state: State<'_, AppState>, path: String) -> Result<VaultMeta, String> {
    {
        let guard = state.vault.read().unwrap();
        let handle = guard.as_ref().ok_or("密码库未解锁")?;
        let vault = handle.vault.lock().unwrap();
        let bytes = vault
            .save(&handle.key)
            .map_err(|e| format!("保存失败: {e}"))?;
        fs::write(&path, bytes).map_err(|e| format!("写入密码库文件失败: {e}"))?;
    }
    // For local vaults the new path becomes the vault's home; a cloud vault
    // keeps syncing to the cloud, the file is just an exported copy.
    {
        let mut guard = state.vault.write().unwrap();
        if let Some(h) = guard.as_mut() {
            if h.source.local_path().is_some() {
                h.source = crate::state::VaultSource::Local {
                    path: path.clone().into(),
                };
                h.dirty.store(false, Ordering::Release);
            }
        }
    }
    let meta = vault_status_inner(&state)?;
    state.add_recent(&path, &meta.name.clone().unwrap_or_default());
    Ok(meta)
}

#[tauri::command]
pub fn vault_get_meta(state: State<'_, AppState>) -> Result<VaultMeta, String> {
    vault_status_inner(&state)
}

#[tauri::command]
pub fn vault_set_name(
    app: AppHandle,
    state: State<'_, AppState>,
    name: String,
) -> Result<(), String> {
    let guard = state.vault.read().unwrap();
    let handle = guard.as_ref().ok_or("密码库未解锁")?;
    let mut vault = handle.vault.lock().unwrap();
    vault.set_name(&name);
    drop(vault);
    handle.mark_dirty();
    drop(guard);
    state.touch();
    let _ = app.emit("vault:dirty", ());
    Ok(())
}

#[tauri::command]
pub fn vault_change_master_password(
    state: State<'_, AppState>,
    current_password: String,
    new_password: String,
    keyfile_path: Option<String>,
) -> Result<(), String> {
    let path = {
        let guard = state.vault.read().unwrap();
        let handle = guard.as_ref().ok_or("密码库未解锁")?;
        if handle.source.local_path().is_none() {
            return Err("云端密码库暂不支持在桌面端修改主密码，请使用手机端操作".into());
        }
        handle
            .source
            .local_path()
            .map(|p| p.to_path_buf())
            .ok_or("密码库未解锁")?
    };
    let bytes = {
        let guard = state.vault.read().unwrap();
        let handle = guard.as_ref().ok_or("密码库未解锁")?;
        let vault = handle.vault.lock().unwrap();
        vault.save(&handle.key).map_err(|e| e.to_string())?
    };
    // Verify the caller really knows the current password before re-keying.
    let current_key = open_key(&current_password, keyfile_path.as_deref())?;
    Vault::open(&bytes, &current_key).map_err(|_| "当前主密码不正确".to_string())?;

    let new_key = open_key(&new_password, keyfile_path.as_deref())?;
    let name = {
        let guard = state.vault.read().unwrap();
        let handle = guard.as_ref().ok_or("密码库未解锁")?;
        let vault = handle.vault.lock().unwrap();
        vault.name().unwrap_or("openvalut").to_string()
    };
    {
        let mut guard = state.vault.write().unwrap();
        let handle = guard.as_mut().ok_or("密码库未解锁")?;
        let vault = handle.vault.lock().unwrap();
        let bytes = vault.save(&new_key).map_err(|e| e.to_string())?;
        fs::write(&path, &bytes).map_err(|e| format!("写入密码库文件失败: {e}"))?;
        handle.key = new_key;
        handle.dirty.store(false, Ordering::Release);
    };
    // What was remembered before the re-key no longer opens the file, so the
    // entry is replaced by the new password (or left alone when the setting is
    // off, in which case remember() writes nothing at all).
    crate::commands::remembered::remember_local(
        &state,
        &path.to_string_lossy(),
        &name,
        &new_password,
        keyfile_path.as_deref(),
    );
    Ok(())
}

#[tauri::command]
pub fn recents_list(state: State<'_, AppState>) -> Result<Vec<RecentFile>, String> {
    Ok(state.recents.lock().unwrap().clone())
}

#[tauri::command]
pub fn recents_remove(state: State<'_, AppState>, path: String) -> Result<(), String> {
    let mut recents = state.recents.lock().unwrap();
    recents.retain(|r| r.path != path);
    state.persist_recents();
    Ok(())
}

#[tauri::command]
pub fn recents_clear(state: State<'_, AppState>) -> Result<(), String> {
    state.recents.lock().unwrap().clear();
    state.persist_recents();
    Ok(())
}
