//! Entry CRUD, search, groups, and the recycle bin.

use openvalut_core::{
    resolve_secret_reference, CreateEntryRequestDto, EntryDto, SecretReference,
    UpdateEntryRequestDto,
};
use serde::Serialize;
use tauri::{AppHandle, Emitter, State};

use crate::state::{AppState, VaultHandle};

/// Lock the vault handle for the duration of an operation.
fn with_vault<T>(
    state: &AppState,
    f: impl FnOnce(&mut openvalut_core::Vault) -> Result<T, String>,
) -> Result<T, String> {
    let guard = state.vault.read().unwrap();
    let handle: &VaultHandle = guard.as_ref().ok_or("密码库未解锁")?;
    let mut vault = handle.vault.lock().unwrap();
    f(&mut vault)
}

fn after_change(app: &AppHandle, state: &AppState) -> Result<(), String> {
    let guard = state.vault.read().unwrap();
    if let Some(handle) = guard.as_ref() {
        handle.mark_dirty();
    }
    drop(guard);
    state.touch();
    let _ = app.emit("vault:changed", ());
    Ok(())
}

fn entry_matches(entry: &openvalut_core::Entry, term: &str) -> bool {
    let hay = format!(
        "{} {} {} {} {} {} {}",
        entry.title,
        entry.username,
        entry.url,
        entry.notes,
        entry.group,
        entry
            .custom
            .iter()
            .map(|(k, v)| format!("{k} {v}"))
            .collect::<Vec<_>>()
            .join(" "),
        entry.uuid,
    )
    .to_lowercase();
    hay.contains(term)
}

#[tauri::command]
pub fn entry_list(
    state: State<'_, AppState>,
    search: Option<String>,
    group: Option<String>,
) -> Result<Vec<EntryDto>, String> {
    with_vault(&state, |vault| {
        let mut entries: Vec<openvalut_core::Entry> = vault.entries();
        if let Some(g) = group {
            entries.retain(|e| e.group == g || e.group.starts_with(&format!("{g}/")));
        }
        if let Some(s) = search {
            let s = s.trim().to_lowercase();
            if !s.is_empty() {
                entries.retain(|e| entry_matches(e, &s));
            }
        }
        Ok(entries
            .into_iter()
            .map(EntryDto::from)
            .collect::<Vec<EntryDto>>())
    })
}

#[tauri::command]
pub fn entry_get(state: State<'_, AppState>, uuid: String) -> Result<EntryDto, String> {
    with_vault(&state, |vault| {
        vault
            .entries()
            .into_iter()
            .find(|e| e.uuid == uuid)
            .map(EntryDto::from)
            .ok_or_else(|| "条目不存在".to_string())
    })
}

#[tauri::command]
pub fn entry_create(
    app: AppHandle,
    state: State<'_, AppState>,
    request: CreateEntryRequestDto,
) -> Result<String, String> {
    if request.title.trim().is_empty() {
        return Err("标题不能为空".to_string());
    }
    let uuid = with_vault(&state, |vault| {
        vault
            .add_entry(&request.into())
            .map_err(|e| format!("创建条目失败: {e}"))
    })?;
    after_change(&app, &state)?;
    Ok(uuid)
}

/// Toggle whether an entry may be read by `openvalut-cli` / the local
/// credential server (the `openvalut.read-allowed` mark).
#[tauri::command]
pub fn entry_set_cli_read(
    app: AppHandle,
    state: State<'_, AppState>,
    uuid: String,
    allowed: bool,
) -> Result<(), String> {
    with_vault(&state, |vault| {
        vault
            .set_entry_read_allowed(&uuid, allowed)
            .map_err(|e| format!("更新读取权限失败: {e}"))
    })?;
    after_change(&app, &state)?;
    Ok(())
}

#[tauri::command]
pub fn entry_update(
    app: AppHandle,
    state: State<'_, AppState>,
    uuid: String,
    request: UpdateEntryRequestDto,
) -> Result<(), String> {
    if let Some(title) = &request.title {
        if title.trim().is_empty() {
            return Err("标题不能为空".to_string());
        }
    }
    with_vault(&state, |vault| {
        vault
            .update_entry(&uuid, &request.into())
            .map_err(|e| format!("更新条目失败: {e}"))
    })?;
    after_change(&app, &state)?;
    Ok(())
}

/// Permanently delete an entry.
#[tauri::command]
pub fn entry_delete(
    app: AppHandle,
    state: State<'_, AppState>,
    uuid: String,
) -> Result<(), String> {
    with_vault(&state, |vault| {
        vault.delete_entry(&uuid).map_err(|e| e.to_string())
    })?;
    after_change(&app, &state)?;
    Ok(())
}

/// Move an entry to the recycle bin.
#[tauri::command]
pub fn entry_trash(app: AppHandle, state: State<'_, AppState>, uuid: String) -> Result<(), String> {
    with_vault(&state, |vault| {
        vault.trash_entry(&uuid).map_err(|e| e.to_string())
    })?;
    after_change(&app, &state)?;
    Ok(())
}

/// Move every copy of one title+username into the recycle bin except the most
/// recently changed one. Returns how many entries were moved.
#[tauri::command]
pub fn entry_trash_duplicates(
    app: AppHandle,
    state: State<'_, AppState>,
    title: String,
    username: String,
) -> Result<usize, String> {
    let moved = with_vault(&state, |vault| {
        vault
            .trash_duplicate_entries(&title, &username)
            .map_err(|e| e.to_string())
    })?;
    if moved > 0 {
        after_change(&app, &state)?;
    }
    Ok(moved)
}

/// Restore an entry from the recycle bin.
#[tauri::command]
pub fn entry_restore(
    app: AppHandle,
    state: State<'_, AppState>,
    uuid: String,
) -> Result<(), String> {
    with_vault(&state, |vault| {
        vault.restore_entry(&uuid).map_err(|e| e.to_string())
    })?;
    after_change(&app, &state)?;
    Ok(())
}

#[tauri::command]
pub fn trashed_list(state: State<'_, AppState>) -> Result<Vec<EntryDto>, String> {
    with_vault(&state, |vault| {
        Ok(vault
            .trashed_entries()
            .into_iter()
            .map(EntryDto::from)
            .collect())
    })
}

/// Read a field for clipboard copy; resolves `ov://` / `op://` references.
#[tauri::command]
pub fn entry_field_value(
    state: State<'_, AppState>,
    uuid: String,
    key: String,
) -> Result<String, String> {
    with_vault(&state, |vault| {
        let value = vault
            .entry_value(&uuid, &key)
            .ok_or_else(|| "字段不存在".to_string())?;
        if let Ok(reference) = SecretReference::parse(&value) {
            let vault_name = vault.name().unwrap_or_default().to_string();
            let vaults: [(&str, &openvalut_core::Vault); 1] = [(vault_name.as_str(), vault)];
            return resolve_secret_reference(&reference, &vaults)
                .map_err(|e| format!("解析引用失败: {e}"));
        }
        Ok(value)
    })
}

#[derive(Serialize)]
pub struct GroupInfo {
    pub uuid: String,
    pub name: String,
    pub path: String,
    pub entry_count: usize,
}

/// The group tree as the file holds it, empty groups included — a group that
/// 自动整理 created but never filled still has to show in the sidebar.
#[tauri::command]
pub fn group_list(state: State<'_, AppState>) -> Result<Vec<GroupInfo>, String> {
    with_vault(&state, |vault| {
        Ok(vault
            .groups()
            .into_iter()
            .map(|g| GroupInfo {
                uuid: g.uuid,
                name: g.name,
                path: g.path,
                entry_count: g.entry_count,
            })
            .collect::<Vec<GroupInfo>>())
    })
}

/// Create a group; `/` in the path creates the whole branch. Returns its UUID.
#[tauri::command]
pub fn group_create(
    app: AppHandle,
    state: State<'_, AppState>,
    path: String,
) -> Result<String, String> {
    let uuid = with_vault(&state, |vault| {
        vault
            .create_group(&path)
            .map_err(|e| format!("创建分组失败: {e}"))
    })?;
    after_change(&app, &state)?;
    Ok(uuid)
}

#[tauri::command]
pub fn group_rename(
    app: AppHandle,
    state: State<'_, AppState>,
    uuid: String,
    name: String,
) -> Result<(), String> {
    with_vault(&state, |vault| {
        vault
            .rename_group(&uuid, &name)
            .map_err(|e| format!("重命名分组失败: {e}"))
    })?;
    after_change(&app, &state)?;
    Ok(())
}

/// Move a group and its contents to the recycle bin.
#[tauri::command]
pub fn group_trash(app: AppHandle, state: State<'_, AppState>, uuid: String) -> Result<(), String> {
    with_vault(&state, |vault| {
        vault
            .trash_group(&uuid)
            .map_err(|e| format!("删除分组失败: {e}"))
    })?;
    after_change(&app, &state)?;
    Ok(())
}

/// Toggle CLI/script read access for every entry in a group and its subgroups.
/// Returns how many entries were changed.
#[tauri::command]
pub fn group_set_cli_read(
    app: AppHandle,
    state: State<'_, AppState>,
    uuid: String,
    allowed: bool,
) -> Result<usize, String> {
    let changed = with_vault(&state, |vault| {
        vault
            .set_group_read_allowed(&uuid, allowed)
            .map_err(|e| format!("更新读取权限失败: {e}"))
    })?;
    after_change(&app, &state)?;
    Ok(changed)
}
