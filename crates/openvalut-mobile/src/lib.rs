//! Flutter FFI bridge for OpenValut core.
//!
//! Exposes a small, stable C ABI so Dart can call into the Rust core on
//! Android (and eventually iOS). The API is intentionally low-level:
//! byte buffers and JSON strings cross the boundary, and Dart owns the
//! allocation of output buffers for fixed-size operations.

mod argon2_ffi;
mod vault_ffi;

pub use argon2_ffi::*;
pub use vault_ffi::*;

/// Result code: success.
pub const OPENVALUT_OK: i32 = 0;
/// Result code: a null pointer was passed where it was not allowed.
pub const OPENVALUT_ERROR_NULL: i32 = -1;
/// Result code: invalid UTF-8 in a string argument.
pub const OPENVALUT_ERROR_UTF8: i32 = -2;
/// Result code: the output buffer is too small.
pub const OPENVALUT_ERROR_BUFFER_TOO_SMALL: i32 = -3;
/// Result code: an internal core operation failed.
pub const OPENVALUT_ERROR_CORE: i32 = -4;
/// Result code: invalid argument (e.g. unsupported Argon2 type).
pub const OPENVALUT_ERROR_INVALID_ARG: i32 = -5;
