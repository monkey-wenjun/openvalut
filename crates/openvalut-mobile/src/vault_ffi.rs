//! Vault operations exposed over FFI.
//!
//! Vaults are kept in a process-global registry and referenced by an opaque
//! handle (a `u64`). All returned strings are allocated on the Rust heap and
//! must be freed with `openvalut_vault_free_string`. Returned byte buffers must
//! be freed with `openvalut_vault_free_bytes`.

use std::collections::HashMap;
use std::ffi::{c_char, c_int, CStr, CString};
use std::slice;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Mutex;

use openvalut_core::{Entry, Vault, VaultKey, CreateEntryRequestDto, EntryDto, UpdateEntryRequestDto};

use crate::{
    OPENVALUT_ERROR_CORE, OPENVALUT_ERROR_INVALID_ARG, OPENVALUT_ERROR_NULL, OPENVALUT_OK,
};

/// Opaque handle to an opened vault.
pub type VaultHandle = u64;

static NEXT_HANDLE: AtomicU64 = AtomicU64::new(1);
static VAULTS: Mutex<Option<HashMap<VaultHandle, Vault>>> = Mutex::new(None);

fn with_vaults<F, R>(f: F) -> R
where
    F: FnOnce(&mut HashMap<VaultHandle, Vault>) -> R,
{
    let mut guard = VAULTS.lock().unwrap();
    let map = guard.get_or_insert_with(HashMap::new);
    f(map)
}

fn insert_vault(vault: Vault) -> VaultHandle {
    let handle = NEXT_HANDLE.fetch_add(1, Ordering::Relaxed);
    with_vaults(|map| map.insert(handle, vault));
    handle
}

fn take_vault(handle: VaultHandle) -> Option<Vault> {
    with_vaults(|map| map.remove(&handle))
}

fn get_vault(handle: VaultHandle) -> Option<Vault> {
    with_vaults(|map| map.get(&handle).cloned())
}

fn get_vault_mut(handle: VaultHandle) -> Option<Vault> {
    with_vaults(|map| map.get_mut(&handle).cloned())
}

fn c_str(ptr: *const c_char) -> Option<String> {
    if ptr.is_null() {
        return None;
    }
    unsafe { CStr::from_ptr(ptr) }
        .to_str()
        .ok()
        .map(|s| s.to_string())
}

fn c_str_required(ptr: *const c_char) -> Result<String, c_int> {
    c_str(ptr).ok_or(OPENVALUT_ERROR_NULL)
}

fn json_entries(entries: Vec<Entry>) -> Result<CString, c_int> {
    let dtos: Vec<EntryDto> = entries.into_iter().map(EntryDto::from).collect();
    let json = serde_json::to_string(&dtos).map_err(|_| OPENVALUT_ERROR_CORE)?;
    CString::new(json).map_err(|_| OPENVALUT_ERROR_CORE)
}

/// Create a new empty vault.
///
/// # Safety
/// - `name` must be a valid, NUL-terminated UTF-8 string.
/// - `out_handle` must be non-null.
#[no_mangle]
pub unsafe extern "C" fn openvalut_vault_create_new(
    name: *const c_char,
    out_handle: *mut VaultHandle,
) -> c_int {
    if out_handle.is_null() {
        return OPENVALUT_ERROR_NULL;
    }
    let name = match c_str_required(name) {
        Ok(s) => s,
        Err(rc) => return rc,
    };
    match Vault::create_new(name) {
        Ok(vault) => {
            *out_handle = insert_vault(vault);
            OPENVALUT_OK
        }
        Err(_) => OPENVALUT_ERROR_CORE,
    }
}

/// Open a vault from encrypted bytes with a password.
///
/// # Safety
/// - `bytes` must point to `len` readable bytes.
/// - `password` must be a valid, NUL-terminated UTF-8 string.
/// - `out_handle` must be non-null.
#[no_mangle]
pub unsafe extern "C" fn openvalut_vault_open(
    bytes: *const u8,
    len: usize,
    password: *const c_char,
    out_handle: *mut VaultHandle,
) -> c_int {
    if out_handle.is_null() {
        return OPENVALUT_ERROR_NULL;
    }
    if bytes.is_null() && len > 0 {
        return OPENVALUT_ERROR_NULL;
    }
    let password = match c_str_required(password) {
        Ok(s) => s,
        Err(rc) => return rc,
    };
    let bytes = slice::from_raw_parts(bytes, len);
    let key = VaultKey::with_password(password);
    match Vault::open(bytes, &key) {
        Ok(vault) => {
            *out_handle = insert_vault(vault);
            OPENVALUT_OK
        }
        Err(_) => OPENVALUT_ERROR_CORE,
    }
}

/// Open a vault from encrypted bytes with a pre-computed transformed key.
///
/// # Safety
/// - `bytes` must point to `len` readable bytes.
/// - `transformed_key` must point to 32 readable bytes.
/// - `out_handle` must be non-null.
#[no_mangle]
pub unsafe extern "C" fn openvalut_vault_open_with_transformed_key(
    bytes: *const u8,
    len: usize,
    transformed_key: *const u8,
    out_handle: *mut VaultHandle,
) -> c_int {
    if out_handle.is_null() {
        return OPENVALUT_ERROR_NULL;
    }
    if (bytes.is_null() && len > 0) || transformed_key.is_null() {
        return OPENVALUT_ERROR_NULL;
    }
    let bytes = slice::from_raw_parts(bytes, len);
    let mut tk = [0u8; 32];
    tk.copy_from_slice(slice::from_raw_parts(transformed_key, 32));
    let key = VaultKey::with_transformed_key(tk);
    match Vault::open(bytes, &key) {
        Ok(vault) => {
            *out_handle = insert_vault(vault);
            OPENVALUT_OK
        }
        Err(_) => OPENVALUT_ERROR_CORE,
    }
}

/// Serialize the vault back to KDBX bytes.
///
/// # Safety
/// - `handle` must be a valid vault handle.
/// - `out_bytes` and `out_len` must be non-null.
#[no_mangle]
pub unsafe extern "C" fn openvalut_vault_save(
    handle: VaultHandle,
    password: *const c_char,
    out_bytes: *mut *mut u8,
    out_len: *mut usize,
) -> c_int {
    if out_bytes.is_null() || out_len.is_null() {
        return OPENVALUT_ERROR_NULL;
    }
    let vault = match get_vault(handle) {
        Some(v) => v,
        None => return OPENVALUT_ERROR_INVALID_ARG,
    };
    let password = match c_str_required(password) {
        Ok(s) => s,
        Err(rc) => return rc,
    };
    let key = VaultKey::with_password(password);
    match vault.save(&key) {
        Ok(bytes) => {
            let mut bytes = bytes.into_boxed_slice();
            *out_bytes = bytes.as_mut_ptr();
            *out_len = bytes.len();
            Box::leak(bytes);
            OPENVALUT_OK
        }
        Err(_) => OPENVALUT_ERROR_CORE,
    }
}

/// List all entries in the vault as a JSON array.
///
/// # Safety
/// - `handle` must be a valid vault handle.
/// - `out_json` must be non-null.
#[no_mangle]
pub unsafe extern "C" fn openvalut_vault_entries(
    handle: VaultHandle,
    out_json: *mut *mut c_char,
) -> c_int {
    if out_json.is_null() {
        return OPENVALUT_ERROR_NULL;
    }
    let vault = match get_vault(handle) {
        Some(v) => v,
        None => return OPENVALUT_ERROR_INVALID_ARG,
    };
    let json = match json_entries(vault.entries()) {
        Ok(s) => s,
        Err(rc) => return rc,
    };
    *out_json = json.into_raw();
    OPENVALUT_OK
}

/// Read a single field value for an entry by UUID.
///
/// # Safety
/// - `handle` must be a valid vault handle.
/// - `uuid` and `key` must be valid, NUL-terminated UTF-8 strings.
/// - `out_value` must be non-null.
#[no_mangle]
pub unsafe extern "C" fn openvalut_vault_entry_value(
    handle: VaultHandle,
    uuid: *const c_char,
    key: *const c_char,
    out_value: *mut *mut c_char,
) -> c_int {
    if out_value.is_null() {
        return OPENVALUT_ERROR_NULL;
    }
    let vault = match get_vault(handle) {
        Some(v) => v,
        None => return OPENVALUT_ERROR_INVALID_ARG,
    };
    let uuid = match c_str_required(uuid) {
        Ok(s) => s,
        Err(rc) => return rc,
    };
    let key = match c_str_required(key) {
        Ok(s) => s,
        Err(rc) => return rc,
    };

    match vault.entry_value(&uuid, &key) {
        Some(value) => {
            let c_value = match CString::new(value) {
                Ok(s) => s,
                Err(_) => return OPENVALUT_ERROR_CORE,
            };
            *out_value = c_value.into_raw();
            OPENVALUT_OK
        }
        None => {
            *out_value = std::ptr::null_mut();
            OPENVALUT_OK
        }
    }
}

/// Create a new entry and return its UUID.
///
/// # Safety
/// - `handle` must be a valid vault handle.
/// - `json` must be a valid, NUL-terminated UTF-8 JSON string.
/// - `out_uuid` must be non-null.
#[no_mangle]
pub unsafe extern "C" fn openvalut_vault_create_entry(
    handle: VaultHandle,
    json: *const c_char,
    out_uuid: *mut *mut c_char,
) -> c_int {
    if out_uuid.is_null() {
        return OPENVALUT_ERROR_NULL;
    }
    let json = match c_str_required(json) {
        Ok(s) => s,
        Err(rc) => return rc,
    };
    let request: CreateEntryRequestDto =
        match serde_json::from_str(&json).map_err(|_| OPENVALUT_ERROR_INVALID_ARG) {
            Ok(r) => r,
            Err(rc) => return rc,
        };

    let mut vault = match get_vault_mut(handle) {
        Some(v) => v,
        None => return OPENVALUT_ERROR_INVALID_ARG,
    };
    match vault.add_entry(&request.into()) {
        Ok(uuid) => {
            let c_uuid = match CString::new(uuid) {
                Ok(s) => s,
                Err(_) => return OPENVALUT_ERROR_CORE,
            };
            // Update the stored vault because add_entry mutates it.
            with_vaults(|map| map.insert(handle, vault));
            *out_uuid = c_uuid.into_raw();
            OPENVALUT_OK
        }
        Err(_) => OPENVALUT_ERROR_CORE,
    }
}

/// Update an existing entry by UUID.
///
/// # Safety
/// - `handle` must be a valid vault handle.
/// - `uuid` and `json` must be valid, NUL-terminated UTF-8 strings.
#[no_mangle]
pub unsafe extern "C" fn openvalut_vault_update_entry(
    handle: VaultHandle,
    uuid: *const c_char,
    json: *const c_char,
) -> c_int {
    let uuid = match c_str_required(uuid) {
        Ok(s) => s,
        Err(rc) => return rc,
    };
    let json = match c_str_required(json) {
        Ok(s) => s,
        Err(rc) => return rc,
    };
    let request: UpdateEntryRequestDto =
        match serde_json::from_str(&json).map_err(|_| OPENVALUT_ERROR_INVALID_ARG) {
            Ok(r) => r,
            Err(rc) => return rc,
        };

    let mut vault = match get_vault_mut(handle) {
        Some(v) => v,
        None => return OPENVALUT_ERROR_INVALID_ARG,
    };
    match vault.update_entry(&uuid, &request.into()) {
        Ok(()) => {
            with_vaults(|map| map.insert(handle, vault));
            OPENVALUT_OK
        }
        Err(_) => OPENVALUT_ERROR_CORE,
    }
}

/// Delete an entry by UUID.
///
/// # Safety
/// - `handle` must be a valid vault handle.
/// - `uuid` must be a valid, NUL-terminated UTF-8 string.
#[no_mangle]
pub unsafe extern "C" fn openvalut_vault_delete_entry(
    handle: VaultHandle,
    uuid: *const c_char,
) -> c_int {
    let uuid = match c_str_required(uuid) {
        Ok(s) => s,
        Err(rc) => return rc,
    };
    let mut vault = match get_vault_mut(handle) {
        Some(v) => v,
        None => return OPENVALUT_ERROR_INVALID_ARG,
    };
    match vault.delete_entry(&uuid) {
        Ok(()) => {
            with_vaults(|map| map.insert(handle, vault));
            OPENVALUT_OK
        }
        Err(_) => OPENVALUT_ERROR_CORE,
    }
}

/// Close a vault handle and free its resources.
///
/// # Safety
/// - `handle` must be a valid vault handle (or 0, which is a no-op).
#[no_mangle]
pub unsafe extern "C" fn openvalut_vault_close(handle: VaultHandle) -> c_int {
    if handle == 0 {
        return OPENVALUT_OK;
    }
    take_vault(handle);
    OPENVALUT_OK
}

/// Free a string previously returned by this module.
///
/// # Safety
/// - `ptr` must have been returned by a function in this module, or be null.
#[no_mangle]
pub unsafe extern "C" fn openvalut_vault_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        let _ = CString::from_raw(ptr);
    }
}

/// Free a byte buffer previously returned by `openvalut_vault_save`.
///
/// # Safety
/// - `ptr` and `len` must match a previous `openvalut_vault_save` output, or
///   be null/0.
#[no_mangle]
pub unsafe extern "C" fn openvalut_vault_free_bytes(ptr: *mut u8, len: usize) {
    if !ptr.is_null() && len > 0 {
        let _ = Box::from_raw(std::ptr::slice_from_raw_parts_mut(ptr, len));
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    #[test]
    fn vault_create_save_open_round_trip() {
        let name = CString::new("Test").unwrap();
        let mut handle: VaultHandle = 0;
        let rc = unsafe { openvalut_vault_create_new(name.as_ptr(), &mut handle) };
        assert_eq!(rc, OPENVALUT_OK);
        assert_ne!(handle, 0);

        let password = CString::new("pw").unwrap();
        let mut bytes_ptr: *mut u8 = std::ptr::null_mut();
        let mut bytes_len: usize = 0;
        let rc = unsafe {
            openvalut_vault_save(handle, password.as_ptr(), &mut bytes_ptr, &mut bytes_len)
        };
        assert_eq!(rc, OPENVALUT_OK);
        assert!(!bytes_ptr.is_null());
        assert!(bytes_len > 0);

        let bytes = unsafe { slice::from_raw_parts(bytes_ptr, bytes_len).to_vec() };
        unsafe { openvalut_vault_free_bytes(bytes_ptr, bytes_len) };

        unsafe { openvalut_vault_close(handle) };

        let mut handle2: VaultHandle = 0;
        let rc = unsafe {
            openvalut_vault_open(bytes.as_ptr(), bytes.len(), password.as_ptr(), &mut handle2)
        };
        assert_eq!(rc, OPENVALUT_OK);
        assert_ne!(handle2, 0);

        let mut json_ptr: *mut c_char = std::ptr::null_mut();
        let rc = unsafe { openvalut_vault_entries(handle2, &mut json_ptr) };
        assert_eq!(rc, OPENVALUT_OK);
        let json = unsafe { CStr::from_ptr(json_ptr).to_str().unwrap().to_string() };
        unsafe { openvalut_vault_free_string(json_ptr) };
        assert_eq!(json, "[]");

        unsafe { openvalut_vault_close(handle2) };
    }
}
