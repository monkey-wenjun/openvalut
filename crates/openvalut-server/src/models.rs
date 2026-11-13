//! Internal request/response models.
//!
//! Where possible the server re-uses the protocol types from `openvalut_core::cloud`.

use serde::Deserialize;

/// Database representation of a user.
#[derive(Debug, Clone)]
pub struct User {
    pub id: String,
    pub username: String,
    pub password_hash: String,
    pub public_key: String,
    pub created_at: i64,
}

/// Database representation of a vault.
#[derive(Debug, Clone)]
pub struct Vault {
    pub id: String,
    pub user_id: String,
    pub name: String,
    pub nonce: Vec<u8>,
    pub ciphertext: Vec<u8>,
    pub created_at: i64,
    pub updated_at: i64,
}

/// Database representation of an entry.
#[derive(Debug, Clone)]
pub struct Entry {
    pub uuid: String,
    pub vault_id: String,
    pub group_name: String,
    pub nonce: Vec<u8>,
    pub ciphertext: Vec<u8>,
    pub updated_at: i64,
    pub created_at: i64,
}

/// Database representation of a share, including joined usernames.
#[derive(Debug, Clone)]
pub struct Share {
    pub id: String,
    pub entry_uuid: String,
    pub owner_user_id: String,
    pub recipient_user_id: String,
    pub owner_username: String,
    pub recipient_username: String,
    pub encrypted_share_key: Vec<u8>,
    pub shared_nonce: Vec<u8>,
    pub shared_ciphertext: Vec<u8>,
    pub created_at: i64,
}

/// Database representation of a dynamic group share, including joined
/// usernames. The share key (wrapped to the recipient) and the encrypted
/// display name are stored once; member rows live in `group_share_entries`.
#[derive(Debug, Clone)]
pub struct GroupShare {
    pub id: String,
    pub vault_id: String,
    pub owner_user_id: String,
    pub recipient_user_id: String,
    pub owner_username: String,
    pub recipient_username: String,
    pub encrypted_share_key: Vec<u8>,
    pub name_nonce: Vec<u8>,
    pub name_ciphertext: Vec<u8>,
    pub created_at: i64,
}

/// One member entry of a dynamic group share.
#[derive(Debug, Clone)]
pub struct GroupShareEntry {
    pub share_id: String,
    pub entry_uuid: String,
    pub nonce: Vec<u8>,
    pub ciphertext: Vec<u8>,
    pub updated_at: i64,
    pub created_at: i64,
}

/// Database representation of a published app version.
#[derive(Debug, Clone)]
pub struct AppVersion {
    pub id: String,
    pub platform: String,
    pub version_name: String,
    pub version_code: i64,
    pub changelog: String,
    pub file_key: String,
    pub download_url: String,
    pub sha256: String,
    pub file_size: i64,
    pub created_at: i64,
}

/// Database representation of a QR-code login session.
#[derive(Debug, Clone)]
pub struct ScanSession {
    pub id: String,
    pub status: String,
    pub user_id: String,
    pub public_key: String,
    pub vault_ciphertext: String,
    /// SHA-256 (hex) of the creator-held poll secret.
    pub secret_hash: String,
    pub created_at: i64,
    pub expires_at: i64,
}

/// Request body for `PUT /api/vaults/{id}`.
///
/// `name` is optional because clients that only want to refresh the encrypted
/// blob (e.g. the desktop app after editing an entry) do not need to resend
/// the vault name.
#[derive(Debug, Deserialize)]
pub struct UpdateVaultRequest {
    #[serde(default)]
    pub name: String,
    pub nonce: String,
    pub ciphertext: String,
    /// Optimistic-concurrency base: the `updatedAt` the client last read.
    /// When present, the update is rejected with 409 if the server blob
    /// changed since then, preventing silent last-writer-wins overwrites
    /// between the app and the CLI.
    #[serde(default)]
    pub base_updated_at: Option<i64>,
}

/// Plaintext body extracted by the envelope middleware.
#[derive(Debug, Clone)]
pub struct PlainBody(pub Vec<u8>);

/// Authenticated user injected by the auth middleware.
#[derive(Debug, Clone)]
pub struct AuthUser {
    pub id: String,
    pub username: String,
    pub public_key: Option<String>,
}

#[axum::async_trait]
impl<S: Send + Sync> axum::extract::FromRequestParts<S> for AuthUser {
    type Rejection = crate::error::ApiError;

    async fn from_request_parts(
        parts: &mut axum::http::request::Parts,
        _state: &S,
    ) -> Result<Self, Self::Rejection> {
        parts
            .extensions
            .get::<AuthUser>()
            .cloned()
            .ok_or(crate::error::ApiError::Unauthorized)
    }
}

/// X25519 public key of the intended response-envelope recipient.
#[derive(Debug, Clone, Copy)]
pub struct EnvelopeRecipient(pub [u8; 32]);
