//! HTTP request handlers.

use std::collections::HashSet;
use std::time::{SystemTime, UNIX_EPOCH};

use axum::extract::{FromRequest, Multipart, Path, Query, Request, State};
use axum::http::{HeaderMap, StatusCode};
use axum::Json;
use base64::Engine;
use serde::Deserialize;
use serde_json::{json, Value};
use sha2::Digest;

use openvalut_core::{
    AppVersion, CloudEntry, CloudGroupShare, CloudGroupShareEntry, CloudShare, CloudVault,
    CreateGroupShareRequest, CreateScanLoginRequest, CreateScanLoginResponse, CreateShareRequest,
    EntriesResponse, EntryResponse, EntryUpsertRequest, GroupShareDetailResponse,
    GroupSharesResponse, LatestVersionResponse, LoginRequest, PollScanLoginResponse,
    RegisterRequest, SetPublicKeyRequest, SharesResponse, SyncEntriesRequest,
    UpsertGroupShareEntriesRequest, VaultResponse, VaultsResponse,
};

use crate::db::EntrySyncUpsert;
use crate::error::ApiError;
use crate::middleware::SIGNATURE_WINDOW_SEC;
use crate::models::{
    AuthUser, GroupShare, GroupShareEntry, PlainBody, UpdateVaultRequest, User, Vault,
};
use crate::state::AppState;

pub async fn healthz() -> Json<Value> {
    Json(json!({ "ok": true }))
}

pub async fn server_key(State(state): State<AppState>) -> Json<Value> {
    Json(json!({ "publicKey": state.server_public_base64() }))
}

pub async fn register(
    State(state): State<AppState>,
    Json(req): Json<RegisterRequest>,
) -> Result<(StatusCode, Json<Value>), ApiError> {
    let username = req.username.trim().to_lowercase();
    if username.is_empty() || username.contains([' ', '\t', '\r', '\n']) {
        return Err(ApiError::BadRequestMsg(
            "username must not contain spaces".into(),
        ));
    }

    let user = User {
        id: openvalut_core::generate_id(),
        username: username.clone(),
        password_hash: String::new(),
        public_key: req.public_key.trim().to_string(),
        created_at: now_secs(),
    };
    state.db.create_user(&user).await?;

    let token = create_token(&state, &user.id).await?;

    Ok((
        StatusCode::CREATED,
        Json(json!({
            "user": {
                "id": user.id,
                "username": user.username,
                "publicKey": user.public_key,
            },
            "token": token,
        })),
    ))
}

pub async fn login(
    State(state): State<AppState>,
    req: RequestParts,
) -> Result<Json<Value>, ApiError> {
    let Json(body) = req.json::<LoginRequest>().await?;

    // Optional signature verification for login: only enforce when the client
    // sent signature headers, matching the Go server's backwards-compatible
    // behavior.
    if req.has_signature_headers() {
        verify_optional_signature(&state, &req, &body.user_id)?;
    }

    let username = body.username.trim().to_lowercase();
    let user = state.db.user_by_username(&username).await?;
    if user.id != body.user_id.trim() {
        return Err(ApiError::Unauthorized);
    }

    if !body.public_key.trim().is_empty() {
        state
            .db
            .set_public_key(&user.id, body.public_key.trim())
            .await?;
    }

    let token = create_token(&state, &user.id).await?;
    Ok(Json(json!({ "token": token })))
}

async fn create_token(state: &AppState, user_id: &str) -> Result<String, ApiError> {
    let mut bytes = [0u8; 32];
    openvalut_core::secure_random_bytes(&mut bytes);
    let token = hex::encode(bytes);
    let token_hash = hex::encode(sha2::Sha256::digest(&token));
    // 30-day TTL, matching the Go server.
    let expires_at = now_secs() + 30 * 24 * 60 * 60;
    state
        .db
        .store_token(&token_hash, user_id, expires_at)
        .await?;
    Ok(token)
}

fn verify_optional_signature(
    state: &AppState,
    req: &RequestParts,
    user_id: &str,
) -> Result<(), ApiError> {
    let timestamp = req.header("x-timestamp").ok_or(ApiError::Unauthorized)?;
    let nonce = req.header("x-nonce").ok_or(ApiError::Unauthorized)?;
    let signature = req.header("x-signature").ok_or(ApiError::Unauthorized)?;

    let ts: i64 = timestamp.parse().map_err(|_| ApiError::Unauthorized)?;
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs() as i64;
    if (now - ts).abs() > SIGNATURE_WINDOW_SEC {
        return Err(ApiError::Unauthorized);
    }

    if !state
        .nonce_cache
        .use_nonce(&nonce, ts + SIGNATURE_WINDOW_SEC)
    {
        return Err(ApiError::Unauthorized);
    }

    openvalut_core::verify_request_signature(
        user_id,
        req.method(),
        req.path(),
        &timestamp,
        &nonce,
        req.body(),
        &signature,
    )
    .map_err(|_| ApiError::Unauthorized)
}

// ---------------------------------------------------------------------------
// me / users
// ---------------------------------------------------------------------------

pub async fn me(State(state): State<AppState>, user: AuthUser) -> Result<Json<Value>, ApiError> {
    let u = state.db.user_by_id(&user.id).await?;
    Ok(Json(json!({
        "user": {
            "id": u.id,
            "username": u.username,
            "publicKey": u.public_key,
        }
    })))
}

pub async fn set_public_key(
    State(state): State<AppState>,
    user: AuthUser,
    Json(req): Json<SetPublicKeyRequest>,
) -> Result<Json<Value>, ApiError> {
    state
        .db
        .set_public_key(&user.id, req.public_key.trim())
        .await?;
    Ok(Json(json!({ "ok": true })))
}

pub async fn get_user_public_key(
    State(state): State<AppState>,
    Path(username): Path<String>,
) -> Result<Json<Value>, ApiError> {
    let username = username.trim().to_lowercase();
    if username.is_empty() {
        return Err(ApiError::BadRequestMsg("missing username".into()));
    }
    let u = state.db.user_by_username(&username).await?;
    if u.public_key.is_empty() {
        return Err(ApiError::NotFound);
    }
    Ok(Json(json!({
        "username": u.username,
        "publicKey": u.public_key,
    })))
}

// ---------------------------------------------------------------------------
// vaults
// ---------------------------------------------------------------------------

pub async fn create_vault(
    State(state): State<AppState>,
    user: AuthUser,
    Json(req): Json<openvalut_core::VaultUpsertRequest>,
) -> Result<(StatusCode, Json<VaultResponse>), ApiError> {
    let nonce = base64_decode(&req.nonce)?;
    let ciphertext = base64_decode(&req.ciphertext)?;
    if req.name.is_empty() {
        return Err(ApiError::BadRequestMsg("missing name".into()));
    }

    let id = match req.id {
        Some(id) if is_hex_id(&id) => id,
        Some(_) => return Err(ApiError::BadRequestMsg("invalid id".into())),
        None => openvalut_core::generate_id(),
    };

    let now = now_secs();
    let vault = Vault {
        id: id.clone(),
        user_id: user.id,
        name: req.name,
        nonce,
        ciphertext,
        created_at: now,
        updated_at: now,
    };
    state.db.create_vault(&vault).await?;

    Ok((
        StatusCode::CREATED,
        Json(VaultResponse {
            vault: vault_to_json(vault),
        }),
    ))
}

pub async fn list_vaults(
    State(state): State<AppState>,
    user: AuthUser,
) -> Result<Json<VaultsResponse>, ApiError> {
    let vaults = state.db.vaults_by_user(&user.id).await?;
    Ok(Json(VaultsResponse {
        vaults: vaults.into_iter().map(vault_to_json).collect(),
    }))
}

pub async fn get_vault(
    State(state): State<AppState>,
    user: AuthUser,
    Path(id): Path<String>,
) -> Result<Json<VaultResponse>, ApiError> {
    let vault = state.db.vault_by_id(&user.id, &id).await?;
    Ok(Json(VaultResponse {
        vault: vault_to_json(vault),
    }))
}

pub async fn get_vault_meta(
    State(state): State<AppState>,
    user: AuthUser,
    Path(id): Path<String>,
) -> Result<Json<Value>, ApiError> {
    let vault = state.db.vault_meta(&user.id, &id).await?;
    Ok(Json(json!({
        "vault": {
            "id": vault.id,
            "name": vault.name,
            "size": vault.ciphertext.len(),
            "updatedAt": vault.updated_at,
        }
    })))
}

pub async fn update_vault(
    State(state): State<AppState>,
    user: AuthUser,
    Path(id): Path<String>,
    Json(req): Json<UpdateVaultRequest>,
) -> Result<Json<Value>, ApiError> {
    // Optimistic concurrency: every writer must state the version it based its
    // edit on, otherwise stale writers would silently overwrite newer data
    // (e.g. the app clobbering a CLI change). Missing base => reject.
    let base_updated_at = req
        .base_updated_at
        .ok_or_else(|| ApiError::BadRequestMsg("missing base_updated_at".into()))?;
    let nonce = base64_decode(&req.nonce)?;
    let ciphertext = base64_decode(&req.ciphertext)?;
    let updated_at = state
        .db
        .update_vault_blob(&user.id, &id, &nonce, &ciphertext, Some(base_updated_at))
        .await?;
    Ok(Json(json!({ "ok": true, "updatedAt": updated_at })))
}

pub async fn delete_vault(
    State(state): State<AppState>,
    user: AuthUser,
    Path(id): Path<String>,
) -> Result<Json<Value>, ApiError> {
    state.db.delete_vault(&user.id, &id).await?;
    Ok(Json(json!({ "ok": true })))
}

fn vault_to_json(vault: Vault) -> CloudVault {
    CloudVault {
        id: vault.id,
        name: vault.name,
        nonce: base64::engine::general_purpose::STANDARD.encode(&vault.nonce),
        ciphertext: base64::engine::general_purpose::STANDARD.encode(&vault.ciphertext),
        created_at: vault.created_at,
        updated_at: vault.updated_at,
    }
}

// ---------------------------------------------------------------------------
// entries
// ---------------------------------------------------------------------------

pub async fn upsert_entry(
    State(state): State<AppState>,
    user: AuthUser,
    Path(vault_id): Path<String>,
    Json(req): Json<EntryUpsertRequest>,
) -> Result<Json<EntryResponse>, ApiError> {
    let nonce = base64_decode(&req.nonce)?;
    let ciphertext = base64_decode(&req.ciphertext)?;

    // The vault must belong to the caller.
    state.db.vault_by_id(&user.id, &vault_id).await?;

    let mut uuid = req.uuid.unwrap_or_default();
    if uuid.is_empty() {
        uuid = openvalut_core::generate_id();
    } else if !is_hex_id(&uuid) {
        return Err(ApiError::BadRequestMsg("invalid uuid".into()));
    }

    let now = now_secs();
    let updated_at = req.updated_at.unwrap_or(now);
    let created_at = req.created_at.unwrap_or(now);

    let entry = crate::models::Entry {
        uuid: uuid.clone(),
        vault_id: vault_id.clone(),
        group_name: req.group,
        nonce,
        ciphertext,
        updated_at,
        created_at,
    };
    let stored_updated_at = state.db.upsert_entry(&entry, req.base_updated_at).await?;

    Ok(Json(EntryResponse {
        entry: entry_to_json(crate::models::Entry {
            updated_at: stored_updated_at,
            ..entry
        }),
    }))
}

pub async fn list_entries(
    State(state): State<AppState>,
    user: AuthUser,
    Path(vault_id): Path<String>,
) -> Result<Json<EntriesResponse>, ApiError> {
    let entries = state.db.entries_by_vault(&user.id, &vault_id).await?;
    Ok(Json(EntriesResponse {
        entries: entries.into_iter().map(entry_to_json).collect(),
    }))
}

/// Batch row sync: upsert many entries and delete many uuids in one request so
/// a full migration or save-diff does not trip the per-request rate limit.
/// Per-row optimistic locking still rejects stale writers with a conflict.
pub async fn sync_entries(
    State(state): State<AppState>,
    user: AuthUser,
    Path(vault_id): Path<String>,
    Json(req): Json<SyncEntriesRequest>,
) -> Result<Json<Value>, ApiError> {
    const MAX_BATCH_ROWS: usize = 10_000;
    if req.upserts.len() + req.deletes.len() > MAX_BATCH_ROWS {
        return Err(ApiError::BadRequestMsg(format!(
            "batch exceeds {MAX_BATCH_ROWS} rows"
        )));
    }

    let now = now_secs();
    let mut seen = HashSet::with_capacity(req.upserts.len() + req.deletes.len());
    let mut upserts = Vec::with_capacity(req.upserts.len());
    for row in req.upserts {
        if !is_hex_id(&row.uuid) {
            return Err(ApiError::BadRequestMsg("invalid uuid".into()));
        }
        if !seen.insert(row.uuid.clone()) {
            return Err(ApiError::BadRequestMsg(
                "duplicate uuid in sync request".into(),
            ));
        }
        let nonce = base64_decode(&row.nonce)?;
        let ciphertext = base64_decode(&row.ciphertext)?;
        upserts.push(EntrySyncUpsert {
            entry: crate::models::Entry {
                uuid: row.uuid,
                vault_id: vault_id.clone(),
                group_name: row.group,
                nonce,
                ciphertext,
                updated_at: now,
                created_at: now,
            },
            base_updated_at: row.base_updated_at,
        });
    }
    for uuid in &req.deletes {
        if !is_hex_id(uuid) {
            return Err(ApiError::BadRequestMsg("invalid uuid".into()));
        }
        if !seen.insert(uuid.clone()) {
            return Err(ApiError::BadRequestMsg(
                "duplicate uuid in sync request".into(),
            ));
        }
    }

    let result = state
        .db
        .sync_entries(&user.id, &vault_id, upserts, &req.deletes)
        .await?;
    Ok(Json(json!({
        "ok": true,
        "upserted": result
            .upserted
            .into_iter()
            .map(|(uuid, updated_at)| json!({
                "uuid": uuid,
                "updatedAt": updated_at,
            }))
            .collect::<Vec<_>>(),
        "conflicts": result.conflicts,
    })))
}

pub async fn delete_entry(
    State(state): State<AppState>,
    user: AuthUser,
    Path((vault_id, uuid)): Path<(String, String)>,
) -> Result<Json<Value>, ApiError> {
    state.db.delete_entry(&user.id, &vault_id, &uuid).await?;
    Ok(Json(json!({ "ok": true })))
}

fn entry_to_json(entry: crate::models::Entry) -> CloudEntry {
    CloudEntry {
        uuid: entry.uuid,
        vault_id: entry.vault_id,
        group: entry.group_name,
        nonce: base64::engine::general_purpose::STANDARD.encode(&entry.nonce),
        ciphertext: base64::engine::general_purpose::STANDARD.encode(&entry.ciphertext),
        updated_at: entry.updated_at,
        created_at: entry.created_at,
    }
}

// ---------------------------------------------------------------------------
// shares
// ---------------------------------------------------------------------------

pub async fn create_share(
    State(state): State<AppState>,
    user: AuthUser,
    Path(vault_id): Path<String>,
    Json(req): Json<CreateShareRequest>,
) -> Result<(StatusCode, Json<Value>), ApiError> {
    if !state
        .db
        .entry_belongs_to_user(&user.id, &vault_id, &req.entry_uuid)
        .await
    {
        return Err(ApiError::NotFound);
    }

    let recipient_username = req.recipient_username.trim().to_lowercase();
    let recipient = state.db.user_by_username(&recipient_username).await?;

    let encrypted_share_key = base64_decode(&req.encrypted_share_key)?;
    let shared_nonce = base64_decode(&req.shared_nonce)?;
    let shared_ciphertext = base64_decode(&req.shared_ciphertext)?;

    let id = openvalut_core::generate_id();
    let created_at = now_secs();
    let share = crate::models::Share {
        id: id.clone(),
        entry_uuid: req.entry_uuid.clone(),
        owner_user_id: user.id.clone(),
        recipient_user_id: recipient.id.clone(),
        owner_username: user.username.clone(),
        recipient_username: recipient.username.clone(),
        encrypted_share_key,
        shared_nonce,
        shared_ciphertext,
        created_at,
    };
    state.db.create_share(&share).await?;

    let share_json = CloudShare {
        id,
        entry_uuid: req.entry_uuid,
        owner_username: user.username,
        recipient_username: recipient.username,
        encrypted_share_key: req.encrypted_share_key,
        shared_nonce: req.shared_nonce,
        shared_ciphertext: req.shared_ciphertext,
        created_at,
    };
    Ok((StatusCode::CREATED, Json(json!({ "share": share_json }))))
}

pub async fn list_incoming_shares(
    State(state): State<AppState>,
    user: AuthUser,
) -> Result<Json<SharesResponse>, ApiError> {
    let shares = state.db.shares_for_recipient(&user.id).await?;
    Ok(Json(SharesResponse {
        shares: shares.into_iter().map(share_to_json).collect(),
    }))
}

pub async fn list_outgoing_shares(
    State(state): State<AppState>,
    user: AuthUser,
) -> Result<Json<SharesResponse>, ApiError> {
    let shares = state.db.shares_by_owner(&user.id).await?;
    Ok(Json(SharesResponse {
        shares: shares.into_iter().map(share_to_json).collect(),
    }))
}

pub async fn delete_share(
    State(state): State<AppState>,
    user: AuthUser,
    Path(id): Path<String>,
) -> Result<Json<Value>, ApiError> {
    state.db.delete_share(&id, &user.id, &user.id).await?;
    Ok(Json(json!({ "ok": true })))
}

fn share_to_json(share: crate::models::Share) -> CloudShare {
    CloudShare {
        id: share.id,
        entry_uuid: share.entry_uuid,
        owner_username: share.owner_username,
        recipient_username: share.recipient_username,
        encrypted_share_key: base64::engine::general_purpose::STANDARD
            .encode(&share.encrypted_share_key),
        shared_nonce: base64::engine::general_purpose::STANDARD.encode(&share.shared_nonce),
        shared_ciphertext: base64::engine::general_purpose::STANDARD
            .encode(&share.shared_ciphertext),
        created_at: share.created_at,
    }
}

// ---------------------------------------------------------------------------
// dynamic group shares
// ---------------------------------------------------------------------------

pub async fn create_group_share(
    State(state): State<AppState>,
    user: AuthUser,
    Path(vault_id): Path<String>,
    Json(req): Json<CreateGroupShareRequest>,
) -> Result<(StatusCode, Json<GroupShareDetailResponse>), ApiError> {
    // The vault must belong to the caller.
    state.db.vault_by_id(&user.id, &vault_id).await?;

    let recipient_username = req.recipient_username.trim().to_lowercase();
    let recipient = state.db.user_by_username(&recipient_username).await?;

    if req.entries.len() > 10_000 {
        return Err(ApiError::BadRequestMsg(
            "group share exceeds 10000 entries".into(),
        ));
    }
    let entry_uuids: Vec<String> = req.entries.iter().map(|e| e.entry_uuid.clone()).collect();
    for uuid in &entry_uuids {
        if !is_hex_id(uuid) {
            return Err(ApiError::BadRequestMsg("invalid uuid".into()));
        }
    }
    if !state
        .db
        .entries_exist_for_vault(&vault_id, &entry_uuids)
        .await?
    {
        return Err(ApiError::NotFound);
    }

    let encrypted_share_key = base64_decode(&req.encrypted_share_key)?;
    let name_nonce = base64_decode(&req.name_nonce)?;
    let name_ciphertext = base64_decode(&req.name_ciphertext)?;
    let id = openvalut_core::generate_id();
    let now = now_secs();
    let share = GroupShare {
        id: id.clone(),
        vault_id: vault_id.clone(),
        owner_user_id: user.id.clone(),
        recipient_user_id: recipient.id.clone(),
        owner_username: user.username.clone(),
        recipient_username: recipient.username.clone(),
        encrypted_share_key,
        name_nonce,
        name_ciphertext,
        created_at: now,
    };
    let mut entries = Vec::with_capacity(req.entries.len());
    for input in &req.entries {
        entries.push(GroupShareEntry {
            share_id: id.clone(),
            entry_uuid: input.entry_uuid.clone(),
            nonce: base64_decode(&input.nonce)?,
            ciphertext: base64_decode(&input.ciphertext)?,
            updated_at: now,
            created_at: now,
        });
    }
    state.db.create_group_share(&share, &entries).await?;

    let share_json = group_share_to_json(share);
    Ok((
        StatusCode::CREATED,
        Json(GroupShareDetailResponse {
            share: share_json,
            entries: entries.iter().map(group_share_entry_to_json).collect(),
        }),
    ))
}

pub async fn list_incoming_group_shares(
    State(state): State<AppState>,
    user: AuthUser,
) -> Result<Json<GroupSharesResponse>, ApiError> {
    let shares = state.db.group_shares_for_recipient(&user.id).await?;
    Ok(Json(GroupSharesResponse {
        shares: shares.into_iter().map(group_share_to_json).collect(),
    }))
}

pub async fn list_outgoing_group_shares(
    State(state): State<AppState>,
    user: AuthUser,
) -> Result<Json<GroupSharesResponse>, ApiError> {
    let shares = state.db.group_shares_by_owner(&user.id).await?;
    Ok(Json(GroupSharesResponse {
        shares: shares.into_iter().map(group_share_to_json).collect(),
    }))
}

pub async fn get_group_share(
    State(state): State<AppState>,
    user: AuthUser,
    Path(id): Path<String>,
) -> Result<Json<GroupShareDetailResponse>, ApiError> {
    let share = state.db.group_share_by_id_for_user(&id, &user.id).await?;
    let entries = state.db.group_share_entries(&id).await?;
    Ok(Json(GroupShareDetailResponse {
        share: group_share_to_json(share),
        entries: entries
            .iter()
            .map(group_share_entry_to_json)
            .collect(),
    }))
}

pub async fn upsert_group_share_entries(
    State(state): State<AppState>,
    user: AuthUser,
    Path(id): Path<String>,
    Json(req): Json<UpsertGroupShareEntriesRequest>,
) -> Result<Json<GroupShareDetailResponse>, ApiError> {
    let share = state.db.group_share_by_id_for_user(&id, &user.id).await?;
    if share.owner_user_id != user.id {
        return Err(ApiError::Forbidden);
    }
    if req.entries.len() > 10_000 {
        return Err(ApiError::BadRequestMsg(
            "group share exceeds 10000 entries".into(),
        ));
    }
    let uuids: Vec<String> = req.entries.iter().map(|e| e.entry_uuid.clone()).collect();
    for uuid in &uuids {
        if !is_hex_id(uuid) {
            return Err(ApiError::BadRequestMsg("invalid uuid".into()));
        }
    }
    if !state
        .db
        .entries_exist_for_vault(&share.vault_id, &uuids)
        .await?
    {
        return Err(ApiError::NotFound);
    }

    let now = now_secs();
    let mut rows = Vec::with_capacity(req.entries.len());
    for input in &req.entries {
        rows.push(GroupShareEntry {
            share_id: id.clone(),
            entry_uuid: input.entry_uuid.clone(),
            nonce: base64_decode(&input.nonce)?,
            ciphertext: base64_decode(&input.ciphertext)?,
            updated_at: now,
            created_at: now,
        });
    }
    state
        .db
        .upsert_group_share_entries(&id, &rows)
        .await?;
    let entries = state.db.group_share_entries(&id).await?;
    Ok(Json(GroupShareDetailResponse {
        share: group_share_to_json(share),
        entries: entries
            .iter()
            .map(group_share_entry_to_json)
            .collect(),
    }))
}

pub async fn remove_group_share_entry(
    State(state): State<AppState>,
    user: AuthUser,
    Path((id, entry_uuid)): Path<(String, String)>,
) -> Result<Json<Value>, ApiError> {
    let share = state.db.group_share_by_id_for_user(&id, &user.id).await?;
    if share.owner_user_id != user.id {
        return Err(ApiError::Forbidden);
    }
    state.db.remove_group_share_entry(&id, &entry_uuid).await?;
    Ok(Json(json!({ "ok": true })))
}

pub async fn delete_group_share(
    State(state): State<AppState>,
    user: AuthUser,
    Path(id): Path<String>,
) -> Result<Json<Value>, ApiError> {
    state.db.delete_group_share(&id, &user.id).await?;
    Ok(Json(json!({ "ok": true })))
}

fn group_share_to_json(share: GroupShare) -> CloudGroupShare {
    CloudGroupShare {
        id: share.id,
        vault_id: share.vault_id,
        owner_username: share.owner_username,
        recipient_username: share.recipient_username,
        encrypted_share_key: base64::engine::general_purpose::STANDARD
            .encode(&share.encrypted_share_key),
        name_nonce: base64::engine::general_purpose::STANDARD.encode(&share.name_nonce),
        name_ciphertext: base64::engine::general_purpose::STANDARD
            .encode(&share.name_ciphertext),
        created_at: share.created_at,
    }
}

fn group_share_entry_to_json(entry: &GroupShareEntry) -> CloudGroupShareEntry {
    CloudGroupShareEntry {
        entry_uuid: entry.entry_uuid.clone(),
        nonce: base64::engine::general_purpose::STANDARD.encode(&entry.nonce),
        ciphertext: base64::engine::general_purpose::STANDARD.encode(&entry.ciphertext),
        updated_at: entry.updated_at,
    }
}

// ---------------------------------------------------------------------------
// scan login
// ---------------------------------------------------------------------------

pub async fn create_scan_login(
    State(state): State<AppState>,
    Json(req): Json<CreateScanLoginRequest>,
) -> Result<(StatusCode, Json<CreateScanLoginResponse>), ApiError> {
    let id = openvalut_core::generate_id();
    let now = now_secs();
    // Creator-held one-time secret: only the device that created the session
    // may poll it for the login token. Only its SHA-256 is stored; it is never
    // embedded in the QR code.
    let mut secret_bytes = [0u8; 32];
    openvalut_core::secure_random_bytes(&mut secret_bytes);
    let session_secret = hex::encode(secret_bytes);
    let secret_hash = hex::encode(sha2::Sha256::digest(&session_secret));
    let session = crate::models::ScanSession {
        id: id.clone(),
        status: "pending".into(),
        user_id: String::new(),
        public_key: req.public_key.trim().to_string(),
        vault_ciphertext: String::new(),
        secret_hash,
        created_at: now,
        expires_at: now + 2 * 60,
    };
    state.db.create_scan_session(&session).await?;

    Ok((
        StatusCode::CREATED,
        Json(CreateScanLoginResponse {
            session_id: id.clone(),
            qr_content: format!("openvalut://scan-login/{id}"),
            session_secret,
        }),
    ))
}

pub async fn poll_scan_login(
    State(state): State<AppState>,
    Path(id): Path<String>,
    headers: HeaderMap,
) -> Result<Json<PollScanLoginResponse>, ApiError> {
    let session = state.db.scan_session_by_id(&id).await?;
    let now = now_secs();
    let expired = session.expires_at < now;

    // Only the session creator holds the secret; it is required to receive the
    // login token so a third party who merely sees the QR code cannot steal it.
    let secret_ok = headers
        .get("x-scan-secret")
        .and_then(|v| v.to_str().ok())
        .map(|provided| {
            hex::encode(sha2::Sha256::digest(provided.as_bytes())) == session.secret_hash
        })
        .unwrap_or(false);

    if session.status == "confirmed" && !expired && secret_ok {
        let user = state.db.user_by_id(&session.user_id).await?;
        let token = create_token(&state, &user.id).await?;
        state.db.delete_scan_session(&id).await?;
        return Ok(Json(PollScanLoginResponse {
            status: "confirmed".into(),
            public_key: if session.public_key.is_empty() {
                None
            } else {
                Some(session.public_key)
            },
            token: Some(token),
            username: Some(user.username),
            // Hand the account id (= Secret Key) to the session creator so the
            // not-yet-logged-in device can sign its subsequent requests.
            user_id: Some(user.id),
            vault_ciphertext: if session.vault_ciphertext.is_empty() {
                None
            } else {
                Some(session.vault_ciphertext)
            },
        }));
    }

    if expired {
        state.db.delete_scan_session(&id).await?;
        return Ok(Json(PollScanLoginResponse {
            status: "expired".into(),
            public_key: None,
            token: None,
            username: None,
            user_id: None,
            vault_ciphertext: None,
        }));
    }

    Ok(Json(PollScanLoginResponse {
        status: session.status.clone(),
        public_key: if session.public_key.is_empty() {
            None
        } else {
            Some(session.public_key)
        },
        token: None,
        username: None,
        user_id: None,
        vault_ciphertext: None,
    }))
}

pub async fn confirm_scan_login(
    State(state): State<AppState>,
    user: AuthUser,
    Path(id): Path<String>,
    body: Option<Json<openvalut_core::ConfirmScanLoginRequest>>,
) -> Result<Json<Value>, ApiError> {
    let session = state.db.scan_session_by_id(&id).await?;
    let now = now_secs();
    if session.expires_at < now {
        return Err(ApiError::Gone);
    }

    let vault_ciphertext = body
        .map(|b| b.vault_ciphertext.trim().to_string())
        .unwrap_or_default();
    state
        .db
        .confirm_scan_session(&id, &user.id, &vault_ciphertext)
        .await?;

    Ok(Json(json!({ "ok": true })))
}

// ---------------------------------------------------------------------------
// app versions
// ---------------------------------------------------------------------------

#[derive(Debug, Deserialize)]
pub struct LatestVersionQuery {
    pub platform: String,
}

pub async fn latest_version(
    State(state): State<AppState>,
    Query(query): Query<LatestVersionQuery>,
) -> Result<Json<LatestVersionResponse>, ApiError> {
    let platform = query.platform.trim();
    if platform.is_empty() {
        return Err(ApiError::BadRequestMsg("platform required".into()));
    }
    let mut version = state
        .db
        .latest_app_version(platform)
        .await?
        .ok_or(ApiError::NotFound)?;
    // Artifacts live in a private OSS bucket; hand the app a freshly signed
    // short-lived URL instead of a permanent (and world-readable) link.
    if !version.file_key.is_empty() {
        if let Some(oss) = &state.oss {
            if let Ok(url) = oss.signed_get_url(&version.file_key, 600) {
                version.download_url = url;
            }
        }
    }
    Ok(Json(LatestVersionResponse {
        version: app_version_to_json(version),
    }))
}

#[derive(Debug, Deserialize)]
pub struct PublishVersionRequest {
    pub platform: String,
    #[serde(rename = "versionName")]
    pub version_name: String,
    #[serde(rename = "versionCode")]
    pub version_code: i64,
    pub changelog: Option<String>,
    #[serde(rename = "downloadUrl")]
    pub download_url: Option<String>,
    pub sha256: Option<String>,
    #[serde(rename = "fileSize")]
    pub file_size: Option<i64>,
}

/// Accepts a release in either form:
/// - multipart/form-data (`platform`, `versionName`, `versionCode`,
///   `changelog`, `downloadUrl`, optional `file`), matching the publish script;
/// - JSON metadata only (metadata publishing without a file upload).
///
/// When a `file` is present it is uploaded to the private OSS bucket and the
/// object key is recorded so `latest` can mint signed download URLs.
pub async fn publish_version(
    State(state): State<AppState>,
    headers: HeaderMap,
    req: Request,
) -> Result<(StatusCode, Json<Value>), ApiError> {
    let publish_key = state.publish_key.as_deref().unwrap_or("");
    let provided = headers
        .get("x-publish-key")
        .and_then(|v| v.to_str().ok())
        .unwrap_or("");
    if publish_key.is_empty() || !constant_time_eq(provided, publish_key) {
        return Err(ApiError::Unauthorized);
    }

    let content_type = headers
        .get(axum::http::header::CONTENT_TYPE)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("")
        .to_string();
    let is_multipart = content_type.starts_with("multipart/form-data");

    let mut platform = String::new();
    let mut version_name = String::new();
    let mut version_code: i64 = 0;
    let mut changelog = String::new();
    let mut download_url = String::new();
    let mut sha256 = String::new();
    let mut file_size: i64 = 0;
    let mut file_bytes: Option<Vec<u8>> = None;
    let mut file_name = String::new();

    if is_multipart {
        let mut multipart = Multipart::from_request(req, &state)
            .await
            .map_err(|_| ApiError::BadRequestMsg("bad multipart body".into()))?;
        while let Some(field) = multipart
            .next_field()
            .await
            .map_err(|_| ApiError::BadRequestMsg("bad multipart field".into()))?
        {
            let name = field.name().unwrap_or_default().to_string();
            match name.as_str() {
                "platform" => platform = field.text().await.unwrap_or_default().trim().to_string(),
                "versionName" => {
                    version_name = field.text().await.unwrap_or_default().trim().to_string()
                }
                "versionCode" => {
                    version_code = field
                        .text()
                        .await
                        .unwrap_or_default()
                        .trim()
                        .parse()
                        .unwrap_or(0)
                }
                "changelog" => changelog = field.text().await.unwrap_or_default(),
                "downloadUrl" => {
                    download_url = field.text().await.unwrap_or_default().trim().to_string()
                }
                "file" => {
                    file_name = field.file_name().unwrap_or_default().to_string();
                    file_bytes = Some(
                        field
                            .bytes()
                            .await
                            .map_err(|_| ApiError::BadRequestMsg("bad file".into()))?
                            .to_vec(),
                    );
                }
                _ => {}
            }
        }
    } else {
        let Json(req) = Json::<PublishVersionRequest>::from_request(req, &state)
            .await
            .map_err(|_| ApiError::BadRequest)?;
        let PublishVersionRequest {
            platform: p,
            version_name: vn,
            version_code: vc,
            changelog: cl,
            download_url: du,
            sha256: sh,
            file_size: fs,
        } = req;
        platform = p.trim().to_string();
        version_name = vn.trim().to_string();
        version_code = vc;
        changelog = cl.unwrap_or_default();
        download_url = du.unwrap_or_default();
        sha256 = sh.unwrap_or_default();
        file_size = fs.unwrap_or_default();
    }

    if platform.is_empty() || version_name.is_empty() || version_code <= 0 {
        return Err(ApiError::BadRequestMsg(
            "platform/versionName/versionCode required".into(),
        ));
    }

    if let Some(existing) = state.db.latest_app_version(&platform).await? {
        if existing.version_code >= version_code {
            return Err(ApiError::Conflict);
        }
    }

    let mut file_key = String::new();
    if let Some(bytes) = file_bytes {
        let oss = state
            .oss
            .as_ref()
            .ok_or_else(|| ApiError::InternalMsg("oss not configured".into()))?;
        if file_name.is_empty() {
            file_name = format!("openvalut-{version_name}.apk");
        }
        let key = format!("releases/{platform}/{version_name}-{version_code}/{file_name}");
        sha256 = hex::encode(sha2::Sha256::digest(&bytes));
        file_size = bytes.len() as i64;
        oss.put_object(&key, &bytes)
            .await
            .map_err(ApiError::InternalMsg)?;
        file_key = key;
    }

    let version = crate::models::AppVersion {
        id: openvalut_core::generate_id(),
        platform,
        version_name,
        version_code,
        changelog,
        file_key,
        download_url,
        sha256,
        file_size,
        created_at: now_secs(),
    };
    state.db.insert_app_version(&version).await?;

    Ok((StatusCode::CREATED, Json(json!({ "ok": true }))))
}

fn app_version_to_json(v: crate::models::AppVersion) -> AppVersion {
    AppVersion {
        platform: v.platform,
        version_name: v.version_name,
        version_code: v.version_code,
        changelog: v.changelog,
        download_url: v.download_url,
        sha256: v.sha256,
        file_size: v.file_size,
        published_at: v.created_at,
    }
}

// ---------------------------------------------------------------------------
// helpers
// ---------------------------------------------------------------------------

fn base64_decode(s: &str) -> Result<Vec<u8>, ApiError> {
    base64::engine::general_purpose::STANDARD
        .decode(s.trim())
        .map_err(|_| ApiError::BadRequestMsg("invalid base64".into()))
}

fn is_hex_id(s: &str) -> bool {
    s.len() == 32
        && s.chars()
            .all(|c| c.is_ascii_digit() || ('a'..='f').contains(&c))
}

fn now_secs() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs() as i64
}

fn constant_time_eq(a: &str, b: &str) -> bool {
    use sha2::Digest;
    let ha = sha2::Sha256::digest(a.as_bytes());
    let hb = sha2::Sha256::digest(b.as_bytes());
    ha.as_slice() == hb.as_slice()
}

/// Extractor that lets the login handler read the raw request alongside the
/// JSON body, needed for optional signature verification.
pub struct RequestParts {
    method: String,
    path: String,
    headers: axum::http::HeaderMap,
    body: Vec<u8>,
}

impl RequestParts {
    pub async fn json<T: serde::de::DeserializeOwned>(&self) -> Result<Json<T>, ApiError> {
        let value = serde_json::from_slice(&self.body)?;
        Ok(Json(value))
    }

    pub fn has_signature_headers(&self) -> bool {
        self.headers.contains_key("x-signature")
            || self.headers.contains_key("x-timestamp")
            || self.headers.contains_key("x-nonce")
    }

    pub fn header(&self, name: &str) -> Option<String> {
        self.headers
            .get(name)
            .and_then(|v| v.to_str().ok())
            .map(String::from)
    }

    pub fn method(&self) -> &str {
        &self.method
    }

    pub fn path(&self) -> &str {
        &self.path
    }

    pub fn body(&self) -> &[u8] {
        &self.body
    }
}

#[axum::async_trait]
impl<S: Send + Sync> axum::extract::FromRequestParts<S> for RequestParts {
    type Rejection = ApiError;

    async fn from_request_parts(
        parts: &mut axum::http::request::Parts,
        _state: &S,
    ) -> Result<Self, Self::Rejection> {
        let method = parts.method.as_str().to_string();
        let path = parts.uri.path().to_string();
        let headers = parts.headers.clone();
        let body = parts
            .extensions
            .get::<PlainBody>()
            .map(|b| b.0.clone())
            .unwrap_or_default();
        Ok(RequestParts {
            method,
            path,
            headers,
            body,
        })
    }
}
