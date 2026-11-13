//! OpenValut Cloud protocol models and request helpers.
//!
//! These structs match the JSON shapes produced and consumed by the Go server
//! in `server/internal/httpapi/router.go`. All encrypted blobs are base64
//! encoded on the wire; callers decode them with the crypto primitives before
//! use.

use serde::{Deserialize, Serialize};

/// Server public key response from `GET /api/server-key`.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct ServerKeyResponse {
    #[serde(rename = "publicKey")]
    pub public_key: String,
}

/// User object returned by the server.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct CloudUser {
    pub id: String,
    pub username: String,
    #[serde(rename = "publicKey")]
    pub public_key: String,
    #[serde(rename = "createdAt")]
    pub created_at: i64,
}

/// Request body for `POST /api/register`.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct RegisterRequest {
    pub username: String,
    #[serde(default)]
    pub password: String,
    #[serde(rename = "publicKey")]
    pub public_key: String,
}

/// Response body for `POST /api/register`.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct RegisterResponse {
    pub user: CloudUser,
    pub token: String,
}

/// Request body for `POST /api/login`.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct LoginRequest {
    pub username: String,
    #[serde(default)]
    pub password: String,
    #[serde(rename = "userId")]
    pub user_id: String,
    #[serde(default, rename = "publicKey")]
    pub public_key: String,
}

/// Response body for `POST /api/login`.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct LoginResponse {
    pub token: String,
}

/// Request body for `POST /api/login/scan`.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct CreateScanLoginRequest {
    #[serde(rename = "publicKey")]
    pub public_key: String,
}

/// Response body for `POST /api/login/scan`.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct CreateScanLoginResponse {
    #[serde(rename = "sessionId")]
    pub session_id: String,
    #[serde(rename = "qrContent")]
    pub qr_content: String,
    /// One-time secret held by the session creator (the not-yet-logged-in
    /// device). It is never put in the QR code; polling must present it to
    /// receive the login token, so someone who only sees the QR cannot steal
    /// the confirmed session's token.
    #[serde(rename = "sessionSecret")]
    pub session_secret: String,
}

/// Response body for `GET /api/login/scan/{id}`.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct PollScanLoginResponse {
    pub status: String,
    #[serde(rename = "publicKey")]
    pub public_key: Option<String>,
    pub token: Option<String>,
    pub username: Option<String>,
    /// Account id of the confirming user — the 32-char UUID that doubles as the
    /// account Secret Key used to sign authenticated requests. It is only
    /// released to the device that created the scan session (the one holding
    /// the one-time `x-scan-secret`), never in the QR code itself. A
    /// not-yet-logged-in PC needs it to sign every request after the QR login.
    #[serde(rename = "userId", default, skip_serializing_if = "Option::is_none")]
    pub user_id: Option<String>,
    #[serde(rename = "vaultCiphertext")]
    pub vault_ciphertext: Option<String>,
}

/// Request body for `POST /api/login/scan/{id}/confirm`.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct ConfirmScanLoginRequest {
    #[serde(rename = "vaultCiphertext")]
    pub vault_ciphertext: String,
}

/// Request body for `PUT /api/me/public-key`.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct SetPublicKeyRequest {
    #[serde(rename = "publicKey")]
    pub public_key: String,
}

/// Response body for `GET /api/users/{username}/public-key`.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct UserPublicKeyResponse {
    pub username: String,
    #[serde(rename = "publicKey")]
    pub public_key: String,
}

/// Vault as stored on the server.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct CloudVault {
    pub id: String,
    pub name: String,
    pub nonce: String,
    pub ciphertext: String,
    #[serde(rename = "createdAt")]
    pub created_at: i64,
    #[serde(rename = "updatedAt")]
    pub updated_at: i64,
}

/// Response wrapper for vault endpoints.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct VaultResponse {
    pub vault: CloudVault,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct VaultsResponse {
    pub vaults: Vec<CloudVault>,
}

/// Vault metadata (lightweight response from `GET /api/vaults/{id}/meta`).
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct VaultMeta {
    pub id: String,
    pub name: String,
    pub size: usize,
    #[serde(rename = "updatedAt")]
    pub updated_at: i64,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct VaultMetaResponse {
    pub vault: VaultMeta,
}

/// Request body for `POST /api/vaults` and `PUT /api/vaults/{id}`.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct VaultUpsertRequest {
    pub id: Option<String>,
    pub name: String,
    pub nonce: String,
    pub ciphertext: String,
}

/// Server-stored encrypted entry.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct CloudEntry {
    pub uuid: String,
    #[serde(rename = "vaultId")]
    pub vault_id: String,
    pub group: String,
    pub nonce: String,
    pub ciphertext: String,
    #[serde(rename = "updatedAt")]
    pub updated_at: i64,
    #[serde(rename = "createdAt")]
    pub created_at: i64,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct EntryResponse {
    pub entry: CloudEntry,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct EntriesResponse {
    pub entries: Vec<CloudEntry>,
}

/// Request body for `POST /api/vaults/{id}/entries`.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct EntryUpsertRequest {
    pub uuid: Option<String>,
    pub group: String,
    pub nonce: String,
    pub ciphertext: String,
    #[serde(rename = "updatedAt")]
    pub updated_at: Option<i64>,
    #[serde(rename = "createdAt")]
    pub created_at: Option<i64>,
    /// Optimistic-concurrency base: the `updatedAt` this row last had. When
    /// present and the server row changed since, the upsert is rejected with
    /// 409 so row-level sync never silently overwrites another writer.
    #[serde(default, rename = "baseUpdatedAt")]
    pub base_updated_at: Option<i64>,
}

/// One row in a batch sync request.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncEntryRow {
    pub uuid: String,
    pub group: String,
    pub nonce: String,
    pub ciphertext: String,
    #[serde(rename = "baseUpdatedAt")]
    pub base_updated_at: i64,
}

/// Batch sync payload: upsert many rows and delete many uuids in one request,
/// so a full vault migration or save-diff does not trip the per-request rate
/// limit. Per-row optimistic locking still applies.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncEntriesRequest {
    #[serde(default)]
    pub upserts: Vec<SyncEntryRow>,
    #[serde(default)]
    pub deletes: Vec<String>,
}

/// Share as stored on the server.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct CloudShare {
    pub id: String,
    #[serde(rename = "entryUuid")]
    pub entry_uuid: String,
    #[serde(rename = "ownerUsername")]
    pub owner_username: String,
    #[serde(rename = "recipientUsername")]
    pub recipient_username: String,
    #[serde(rename = "encryptedShareKey")]
    pub encrypted_share_key: String,
    #[serde(rename = "sharedNonce")]
    pub shared_nonce: String,
    #[serde(rename = "sharedCiphertext")]
    pub shared_ciphertext: String,
    #[serde(rename = "createdAt")]
    pub created_at: i64,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct SharesResponse {
    pub shares: Vec<CloudShare>,
}

/// Request body for `POST /api/vaults/{id}/shares`.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct CreateShareRequest {
    #[serde(rename = "entryUuid")]
    pub entry_uuid: String,
    #[serde(rename = "recipientUsername")]
    pub recipient_username: String,
    #[serde(rename = "encryptedShareKey")]
    pub encrypted_share_key: String,
    #[serde(rename = "sharedNonce")]
    pub shared_nonce: String,
    #[serde(rename = "sharedCiphertext")]
    pub shared_ciphertext: String,
}

/// One entry row inside a dynamic group share. Like entry shares, the payload
/// is the entry's plain string fields encrypted with the group share key.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct CloudGroupShareEntry {
    #[serde(rename = "entryUuid")]
    pub entry_uuid: String,
    pub nonce: String,
    pub ciphertext: String,
    #[serde(rename = "updatedAt")]
    pub updated_at: i64,
}

/// Request payload for one group-share entry row (server assigns updatedAt).
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct GroupShareEntryInput {
    #[serde(rename = "entryUuid")]
    pub entry_uuid: String,
    pub nonce: String,
    pub ciphertext: String,
}

/// Dynamic group share as stored on the server. The share key is wrapped to
/// the recipient once; every member row is encrypted with that same key.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct CloudGroupShare {
    pub id: String,
    #[serde(rename = "vaultId")]
    pub vault_id: String,
    #[serde(rename = "ownerUsername")]
    pub owner_username: String,
    #[serde(rename = "recipientUsername")]
    pub recipient_username: String,
    #[serde(rename = "encryptedShareKey")]
    pub encrypted_share_key: String,
    /// Encrypted display name (the owner's group path) under the share key.
    #[serde(rename = "nameNonce")]
    pub name_nonce: String,
    #[serde(rename = "nameCiphertext")]
    pub name_ciphertext: String,
    #[serde(rename = "createdAt")]
    pub created_at: i64,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct GroupSharesResponse {
    pub shares: Vec<CloudGroupShare>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct GroupShareDetailResponse {
    pub share: CloudGroupShare,
    pub entries: Vec<CloudGroupShareEntry>,
}

/// Request body for `POST /api/vaults/{id}/group-shares`.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct CreateGroupShareRequest {
    #[serde(rename = "recipientUsername")]
    pub recipient_username: String,
    #[serde(rename = "encryptedShareKey")]
    pub encrypted_share_key: String,
    #[serde(rename = "nameNonce")]
    pub name_nonce: String,
    #[serde(rename = "nameCiphertext")]
    pub name_ciphertext: String,
    #[serde(default)]
    pub entries: Vec<GroupShareEntryInput>,
}

/// Request body for `POST /api/group-shares/{id}/entries`.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct UpsertGroupShareEntriesRequest {
    #[serde(default)]
    pub entries: Vec<GroupShareEntryInput>,
}

/// Generic `{ "ok": true }` response used by many endpoints.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct OkResponse {
    pub ok: bool,
}

/// App version returned by `GET /api/versions/latest`.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct AppVersion {
    pub platform: String,
    #[serde(rename = "versionName")]
    pub version_name: String,
    #[serde(rename = "versionCode")]
    pub version_code: i64,
    pub changelog: String,
    #[serde(rename = "downloadUrl")]
    pub download_url: String,
    pub sha256: String,
    #[serde(rename = "fileSize")]
    pub file_size: i64,
    #[serde(rename = "publishedAt")]
    pub published_at: i64,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct LatestVersionResponse {
    pub version: AppVersion,
}

/// Error response body from the server.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct ErrorResponse {
    pub error: String,
}

/// Request envelope wrapper: bodies sent to the server are encrypted and sent
/// as `{ "enc": "<base64 blob>" }`.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct EnvelopeRequest {
    pub enc: String,
}

impl EnvelopeRequest {
    pub fn new(base64_blob: impl Into<String>) -> Self {
        Self {
            enc: base64_blob.into(),
        }
    }
}

/// Build the signature headers used by authenticated requests.
#[derive(Debug, Clone)]
pub struct SignedRequestHeaders {
    pub timestamp: String,
    pub nonce: String,
    pub signature: String,
}

impl SignedRequestHeaders {
    /// Sign a request body for the given user.
    pub fn new(user_id: &str, method: &str, path: &str, body: &[u8]) -> crate::Result<Self> {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs()
            .to_string();
        let nonce = crate::generate_id();
        let signature = crate::sign_request(user_id, method, path, &timestamp, &nonce, body)?;
        Ok(Self {
            timestamp,
            nonce,
            signature,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn serialize_vault_response() {
        let resp = VaultResponse {
            vault: CloudVault {
                id: "abc".into(),
                name: "Personal".into(),
                nonce: "nonce".into(),
                ciphertext: "ct".into(),
                created_at: 1,
                updated_at: 2,
            },
        };
        let json = serde_json::to_string(&resp).unwrap();
        assert!(json.contains("\"createdAt\":1"));
        assert!(json.contains("\"updatedAt\":2"));
    }

    #[test]
    fn envelope_request_round_trip() {
        let req = EnvelopeRequest::new("hello");
        let json = serde_json::to_string(&req).unwrap();
        let decoded: EnvelopeRequest = serde_json::from_str(&json).unwrap();
        assert_eq!(decoded.enc, "hello");
    }

    #[test]
    fn signed_headers_have_expected_length() {
        let headers = SignedRequestHeaders::new(
            "0123456789abcdef0123456789abcdef",
            "GET",
            "/api/vaults",
            b"",
        )
        .unwrap();
        assert_eq!(headers.nonce.len(), 32);
        assert_eq!(headers.signature.len(), 64);
        assert!(!headers.timestamp.is_empty());
    }
}
