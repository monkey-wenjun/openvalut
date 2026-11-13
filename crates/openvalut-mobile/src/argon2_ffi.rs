//! Argon2 FFI bindings.

use std::ffi::{c_char, c_int, CStr};
use std::slice;

use crate::{
    OPENVALUT_ERROR_CORE, OPENVALUT_ERROR_INVALID_ARG, OPENVALUT_ERROR_NULL, OPENVALUT_ERROR_UTF8,
    OPENVALUT_OK,
};

/// Flexible Argon2 hash, matching the `Argon2Arguments` used by `kdbx.dart`.
///
/// # Safety
/// - `password` must point to at least `password_len` readable bytes.
/// - `salt` must point to at least `salt_len` readable bytes.
/// - `out` must point to at least `hash_len` writable bytes.
/// - `type_` is 0 for Argon2d, 1 for Argon2i, 2 for Argon2id.
/// - `version` is 0x10 (16) or 0x13 (19).
#[no_mangle]
pub unsafe extern "C" fn openvalut_argon2_hash(
    password: *const u8,
    password_len: usize,
    salt: *const u8,
    salt_len: usize,
    memory_kib: u32,
    iterations: u32,
    parallelism: u32,
    hash_len: usize,
    type_: u8,
    version: u32,
    out: *mut u8,
) -> c_int {
    if (password.is_null() && password_len > 0) || (salt.is_null() && salt_len > 0) || out.is_null()
    {
        return OPENVALUT_ERROR_NULL;
    }

    let algorithm = match type_ {
        0 => argon2::Algorithm::Argon2d,
        1 => argon2::Algorithm::Argon2i,
        2 => argon2::Algorithm::Argon2id,
        _ => return OPENVALUT_ERROR_INVALID_ARG,
    };
    let version = match argon2::Version::try_from(version) {
        Ok(v) => v,
        Err(_) => return OPENVALUT_ERROR_INVALID_ARG,
    };

    let password = slice::from_raw_parts(password, password_len);
    let salt = slice::from_raw_parts(salt, salt_len);
    let out = slice::from_raw_parts_mut(out, hash_len);

    match openvalut_core::argon2_hash(
        password,
        salt,
        algorithm,
        version,
        memory_kib,
        iterations,
        parallelism,
        out,
    ) {
        Ok(()) => OPENVALUT_OK,
        Err(_) => OPENVALUT_ERROR_CORE,
    }
}

/// Derive a 32-byte key from a UTF-8 `password` and `salt` using Argon2id
/// with the fixed OpenValut cloud-sync parameters.
///
/// # Safety
/// - `password` must be a valid, NUL-terminated UTF-8 string.
/// - `salt` must point to at least `salt_len` readable bytes.
/// - `out` must point to at least 32 writable bytes.
#[no_mangle]
pub unsafe extern "C" fn openvalut_argon2_derive(
    password: *const c_char,
    salt: *const u8,
    salt_len: usize,
    out: *mut u8,
) -> c_int {
    if password.is_null() || (salt.is_null() && salt_len > 0) || out.is_null() {
        return OPENVALUT_ERROR_NULL;
    }

    let password = match CStr::from_ptr(password).to_str() {
        Ok(s) => s,
        Err(_) => return OPENVALUT_ERROR_UTF8,
    };
    let salt = slice::from_raw_parts(salt, salt_len);
    let out = slice::from_raw_parts_mut(out, openvalut_core::crypto::ARGON2_OUTPUT_LEN);

    match openvalut_core::derive_key_argon2id(password, salt) {
        Ok(key) => {
            out.copy_from_slice(&key);
            OPENVALUT_OK
        }
        Err(_) => OPENVALUT_ERROR_CORE,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    #[test]
    fn argon2_hash_matches_core() {
        let password = b"demopass";
        let salt = b"somesalt";
        let mut out = [0u8; 32];
        let rc = unsafe {
            openvalut_argon2_hash(
                password.as_ptr(),
                password.len(),
                salt.as_ptr(),
                salt.len(),
                64 * 1024,
                3,
                4,
                32,
                2, // Argon2id
                0x13,
                out.as_mut_ptr(),
            )
        };
        assert_eq!(rc, OPENVALUT_OK);
        let expected = openvalut_core::derive_key_argon2id("demopass", salt).unwrap();
        assert_eq!(out, expected);
    }

    #[test]
    fn argon2_derive_matches_core() {
        let password = CString::new("demopass").unwrap();
        let salt = b"somesalt";
        let mut out = [0u8; 32];
        let rc = unsafe {
            openvalut_argon2_derive(
                password.as_ptr(),
                salt.as_ptr(),
                salt.len(),
                out.as_mut_ptr(),
            )
        };
        assert_eq!(rc, OPENVALUT_OK);
        let expected = openvalut_core::derive_key_argon2id("demopass", salt).unwrap();
        assert_eq!(out, expected);
    }
}
