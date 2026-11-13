//! OpenValut core library.
//!
//! This crate contains the platform-agnostic logic shared by the OpenValut
//! server, CLI, and Chrome native host:
//!
//! * KDBX vault operations
//! * End-to-end encryption (Argon2id, AES-256-GCM, X25519)
//! * Cloud sync protocol helpers
//! * TOTP generation
//! * Secret reference resolution
//! * Password generation
//!
//! The API is intentionally plain Rust (`String`, `Vec<u8>`) so it can be
//! exposed through FFI or used directly by other Rust crates.

pub mod cloud;
pub mod crypto;
pub mod dto;
pub mod error;
pub mod kdbx;
pub mod password;
pub mod secret_ref;
pub mod totp;

pub use cloud::{
    AppVersion, CloudEntry, CloudGroupShare, CloudGroupShareEntry, CloudShare, CloudUser,
    CloudVault, ConfirmScanLoginRequest, CreateGroupShareRequest, CreateScanLoginRequest,
    CreateScanLoginResponse, CreateShareRequest, EntriesResponse, EntryResponse,
    EntryUpsertRequest, EnvelopeRequest, ErrorResponse, GroupShareDetailResponse,
    GroupShareEntryInput, GroupSharesResponse, LatestVersionResponse, LoginRequest, LoginResponse,
    OkResponse, PollScanLoginResponse, RegisterRequest, RegisterResponse, SetPublicKeyRequest,
    SharesResponse, SignedRequestHeaders, SyncEntriesRequest, UpsertGroupShareEntriesRequest,
    UserPublicKeyResponse, VaultMeta, VaultMetaResponse, VaultResponse, VaultUpsertRequest,
    VaultsResponse,
};
pub use crypto::{
    aes_gcm_decrypt, aes_gcm_encrypt, argon2_hash, derive_key_argon2id, envelope_decrypt,
    envelope_encrypt, generate_id, generate_x25519_keypair, secure_random_bytes, sign_request,
    unwrap_share_key, verify_request_signature, wrap_share_key, x25519_public_from_secret,
};
pub use error::{Error, Result};
pub use dto::{CreateEntryRequestDto, CustomFieldDto, EntryDto, UpdateEntryRequestDto};
pub use kdbx::{
    CreateEntryRequest, Entry, Group, UpdateEntryRequest, Vault, VaultKey, COMPUTER_GROUP_NAME,
    FIELD_MACHINE_ID, FIELD_NOTES, FIELD_OTP, FIELD_PASSWORD, FIELD_SSH_PRIVATE_KEY, FIELD_TITLE,
    FIELD_URL, FIELD_USERNAME, TRASH_GROUP_NAME,
};
pub use password::generate_password;
pub use secret_ref::{resolve_secret_reference, SecretReference, SecretReferenceField};
pub use totp::{generate_totp, parse_otp_auth, OtpAuth};
