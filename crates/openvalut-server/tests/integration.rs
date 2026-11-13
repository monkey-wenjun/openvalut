//! Integration tests for the OpenValut Rust server.
//!
//! Each test spins up a server instance on a random local port and exercises
//! the HTTP API using reqwest. Request signing follows the protocol used by
//! the Flutter and CLI clients.

use std::time::{SystemTime, UNIX_EPOCH};

use base64::Engine;
use openvalut_core::{
    envelope_encrypt, generate_id, generate_x25519_keypair, sign_request, RegisterRequest,
};
use openvalut_server::db::DbKind;
use openvalut_server::state::AppState;
use serde_json::{json, Value};

#[tokio::test]
async fn healthz_and_server_key() {
    let base_url = spawn_server().await;

    let client = reqwest::Client::new();
    let health: Value = client
        .get(format!("{}/healthz", base_url))
        .send()
        .await
        .unwrap()
        .json()
        .await
        .unwrap();
    assert_eq!(health["ok"], true);

    let key: Value = client
        .get(format!("{}/api/server-key", base_url))
        .send()
        .await
        .unwrap()
        .json()
        .await
        .unwrap();
    assert!(!key["publicKey"].as_str().unwrap().is_empty());
}

#[tokio::test]
async fn register_and_login() {
    let base_url = spawn_server().await;
    let (_user_id, _token) = register_user(&base_url, "alice@example.com").await;
}

#[tokio::test]
async fn register_with_envelope() {
    let base_url = spawn_server().await;
    let client = reqwest::Client::new();

    let key: Value = client
        .get(format!("{}/api/server-key", base_url))
        .send()
        .await
        .unwrap()
        .json()
        .await
        .unwrap();
    let server_public_b64 = key["publicKey"].as_str().unwrap();
    let server_public = base64::engine::general_purpose::STANDARD
        .decode(server_public_b64)
        .unwrap();
    let server_public: [u8; 32] = server_public.try_into().unwrap();

    let (user_secret, user_public) = generate_x25519_keypair();
    let username = "charlie@example.com";

    let plaintext = serde_json::to_vec(&RegisterRequest {
        username: username.into(),
        password: "master-password".into(),
        public_key: base64::engine::general_purpose::STANDARD.encode(user_public),
    })
    .unwrap();

    let encrypted = envelope_encrypt(&server_public, &plaintext).unwrap();
    let body = json!({ "enc": base64::engine::general_purpose::STANDARD.encode(encrypted) });

    let resp: Value = client
        .post(format!("{}/api/register", base_url))
        .header("X-Envelope", "1")
        .json(&body)
        .send()
        .await
        .unwrap()
        .json()
        .await
        .unwrap();

    let enc = base64::engine::general_purpose::STANDARD
        .decode(resp["enc"].as_str().unwrap())
        .unwrap();
    let decrypted = openvalut_core::envelope_decrypt(&user_secret, &enc).unwrap();
    let resp: Value = serde_json::from_slice(&decrypted).unwrap();

    assert_eq!(resp["user"]["username"].as_str().unwrap(), username);
    assert!(!resp["token"].as_str().unwrap().is_empty());
}

#[tokio::test]
async fn vault_crud_with_signatures() {
    let base_url = spawn_server().await;
    let (user_id, token) = register_user(&base_url, "bob@example.com").await;

    // Create a vault
    let vault_id = generate_id();
    let nonce = b"0123456789ab";
    let ciphertext = b"encrypted-blob";
    let create_body = json!({
        "id": vault_id,
        "name": "Personal",
        "nonce": base64::engine::general_purpose::STANDARD.encode(nonce),
        "ciphertext": base64::engine::general_purpose::STANDARD.encode(ciphertext),
    });

    let resp: Value = signed_request(
        &base_url,
        "POST",
        "/api/vaults",
        &user_id,
        &token,
        create_body,
    )
    .await
    .json()
    .await
    .unwrap();
    assert_eq!(resp["vault"]["id"].as_str().unwrap(), vault_id);
    assert_eq!(resp["vault"]["name"].as_str().unwrap(), "Personal");

    // List vaults
    let resp: Value = signed_request(&base_url, "GET", "/api/vaults", &user_id, &token, json!({}))
        .await
        .json()
        .await
        .unwrap();
    let vaults = resp["vaults"].as_array().unwrap();
    assert_eq!(vaults.len(), 1);
    assert_eq!(vaults[0]["id"].as_str().unwrap(), vault_id);

    // Get vault
    let resp: Value = signed_request(
        &base_url,
        "GET",
        &format!("/api/vaults/{}", vault_id),
        &user_id,
        &token,
        json!({}),
    )
    .await
    .json()
    .await
    .unwrap();
    assert_eq!(resp["vault"]["id"].as_str().unwrap(), vault_id);
    let base_updated_at = resp["vault"]["updatedAt"].as_i64().unwrap();

    // Update vault
    let new_nonce = b"fedcba987654";
    let new_ciphertext = b"updated-blob";
    let update_body = json!({
        "name": "Work",
        "nonce": base64::engine::general_purpose::STANDARD.encode(new_nonce),
        "ciphertext": base64::engine::general_purpose::STANDARD.encode(new_ciphertext),
        "base_updated_at": base_updated_at,
    });
    let resp: Value = signed_request(
        &base_url,
        "PUT",
        &format!("/api/vaults/{}", vault_id),
        &user_id,
        &token,
        update_body,
    )
    .await
    .json()
    .await
    .unwrap();
    assert_eq!(resp["ok"], true);

    // Verify update
    let resp: Value = signed_request(
        &base_url,
        "GET",
        &format!("/api/vaults/{}", vault_id),
        &user_id,
        &token,
        json!({}),
    )
    .await
    .json()
    .await
    .unwrap();
    assert_eq!(resp["vault"]["name"].as_str().unwrap(), "Personal");
    assert_eq!(
        resp["vault"]["nonce"].as_str().unwrap(),
        base64::engine::general_purpose::STANDARD.encode(new_nonce)
    );

    // Delete vault
    let resp: Value = signed_request(
        &base_url,
        "DELETE",
        &format!("/api/vaults/{}", vault_id),
        &user_id,
        &token,
        json!({}),
    )
    .await
    .json()
    .await
    .unwrap();
    assert_eq!(resp["ok"], true);

    // List should be empty
    let resp: Value = signed_request(&base_url, "GET", "/api/vaults", &user_id, &token, json!({}))
        .await
        .json()
        .await
        .unwrap();
    assert!(resp["vaults"].as_array().unwrap().is_empty());
}

#[tokio::test]
async fn update_vault_blob_without_name() {
    let base_url = spawn_server().await;
    let (user_id, token) = register_user(&base_url, "noname@example.com").await;

    let vault_id = generate_id();
    signed_request(
        &base_url,
        "POST",
        "/api/vaults",
        &user_id,
        &token,
        json!({
            "id": vault_id,
            "name": "Personal",
            "nonce": b64(b"initial-nonce"),
            "ciphertext": b64(b"initial-ct"),
        }),
    )
    .await;

    // The desktop client reads the current version first, then sends it back
    // as base_updated_at so a stale writer is rejected instead of overwriting.
    let cur: Value = signed_request(
        &base_url,
        "GET",
        &format!("/api/vaults/{}", vault_id),
        &user_id,
        &token,
        json!({}),
    )
    .await
    .json()
    .await
    .unwrap();
    let base = cur["vault"]["updatedAt"].as_i64().unwrap();

    let resp: Value = signed_request(
        &base_url,
        "PUT",
        &format!("/api/vaults/{}", vault_id),
        &user_id,
        &token,
        json!({
            "nonce": b64(b"updated-nonce"),
            "ciphertext": b64(b"updated-ct"),
            "base_updated_at": base,
        }),
    )
    .await
    .json()
    .await
    .unwrap();
    assert_eq!(resp["ok"], true);
    let new_version = resp["updatedAt"].as_i64().unwrap();
    assert!(new_version > base);

    // A writer based on the OLD version must be rejected with 409.
    let conflict_resp = signed_request_no_assert(
        &base_url,
        "PUT",
        &format!("/api/vaults/{}", vault_id),
        &user_id,
        &token,
        json!({
            "nonce": b64(b"stale-nonce"),
            "ciphertext": b64(b"stale-ct"),
            "base_updated_at": base,
        }),
    )
    .await;
    assert_eq!(conflict_resp.status().as_u16(), 409);
    let conflict: Value = conflict_resp.json().await.unwrap();
    assert_eq!(conflict["error"], "conflict");

    // A writer with no base_updated_at is rejected outright.
    let missing_resp = signed_request_no_assert(
        &base_url,
        "PUT",
        &format!("/api/vaults/{}", vault_id),
        &user_id,
        &token,
        json!({
            "nonce": b64(b"no-base-nonce"),
            "ciphertext": b64(b"no-base-ct"),
        }),
    )
    .await;
    assert_eq!(missing_resp.status().as_u16(), 400);
    let missing: Value = missing_resp.json().await.unwrap();
    assert_eq!(missing["error"], "missing base_updated_at");

    // Name must stay unchanged.
    let resp: Value = signed_request(
        &base_url,
        "GET",
        &format!("/api/vaults/{}", vault_id),
        &user_id,
        &token,
        json!({}),
    )
    .await
    .json()
    .await
    .unwrap();
    assert_eq!(resp["vault"]["name"].as_str().unwrap(), "Personal");
    assert_eq!(
        resp["vault"]["nonce"].as_str().unwrap(),
        b64(b"updated-nonce")
    );
}

#[tokio::test]
async fn entry_crud() {
    let base_url = spawn_server().await;
    let (user_id, token) = register_user(&base_url, "entry-user@example.com").await;

    // Create vault
    let vault_id = generate_id();
    signed_request(
        &base_url,
        "POST",
        "/api/vaults",
        &user_id,
        &token,
        json!({
            "id": vault_id,
            "name": "Entries",
            "nonce": b64(b"vault-nonce"),
            "ciphertext": b64(b"vault-ct"),
        }),
    )
    .await;

    // Create entry
    let entry_uuid = generate_id();
    let resp: Value = signed_request(
        &base_url,
        "POST",
        &format!("/api/vaults/{}/entries", vault_id),
        &user_id,
        &token,
        json!({
            "uuid": entry_uuid,
            "group": "Social",
            "nonce": b64(b"entry-nonce"),
            "ciphertext": b64(b"entry-ct"),
        }),
    )
    .await
    .json()
    .await
    .unwrap();
    assert_eq!(resp["entry"]["uuid"].as_str().unwrap(), entry_uuid);
    assert_eq!(resp["entry"]["vaultId"].as_str().unwrap(), vault_id);
    assert_eq!(resp["entry"]["group"].as_str().unwrap(), "Social");

    // List entries
    let resp: Value = signed_request(
        &base_url,
        "GET",
        &format!("/api/vaults/{}/entries", vault_id),
        &user_id,
        &token,
        json!({}),
    )
    .await
    .json()
    .await
    .unwrap();
    let entries = resp["entries"].as_array().unwrap();
    assert_eq!(entries.len(), 1);
    assert_eq!(entries[0]["uuid"].as_str().unwrap(), entry_uuid);

    // Update entry (upsert)
    let resp: Value = signed_request(
        &base_url,
        "POST",
        &format!("/api/vaults/{}/entries", vault_id),
        &user_id,
        &token,
        json!({
            "uuid": entry_uuid,
            "group": "Work",
            "nonce": b64(b"entry-nonce-2"),
            "ciphertext": b64(b"entry-ct-2"),
        }),
    )
    .await
    .json()
    .await
    .unwrap();
    assert_eq!(resp["entry"]["group"].as_str().unwrap(), "Work");

    // Delete entry
    let resp: Value = signed_request(
        &base_url,
        "DELETE",
        &format!("/api/vaults/{}/entries/{}", vault_id, entry_uuid),
        &user_id,
        &token,
        json!({}),
    )
    .await
    .json()
    .await
    .unwrap();
    assert_eq!(resp["ok"], true);

    let resp: Value = signed_request(
        &base_url,
        "GET",
        &format!("/api/vaults/{}/entries", vault_id),
        &user_id,
        &token,
        json!({}),
    )
    .await
    .json()
    .await
    .unwrap();
    assert!(resp["entries"].as_array().unwrap().is_empty());
}

#[tokio::test]
async fn entry_uuid_cannot_overwrite_another_users_vault() {
    let base_url = spawn_server().await;
    let (owner_id, owner_token) = register_user(&base_url, "uuid-owner@example.com").await;
    let (attacker_id, attacker_token) = register_user(&base_url, "uuid-attacker@example.com").await;
    let owner_vault = generate_id();
    let attacker_vault = generate_id();

    for (user_id, token, vault_id, name) in [
        (&owner_id, &owner_token, &owner_vault, "Owner"),
        (&attacker_id, &attacker_token, &attacker_vault, "Attacker"),
    ] {
        signed_request(
            &base_url,
            "POST",
            "/api/vaults",
            user_id,
            token,
            json!({
                "id": vault_id,
                "name": name,
                "nonce": b64(b"vault-nonce"),
                "ciphertext": b64(b"vault-ct"),
            }),
        )
        .await;
    }

    let entry_uuid = generate_id();
    signed_request(
        &base_url,
        "POST",
        &format!("/api/vaults/{}/entries", owner_vault),
        &owner_id,
        &owner_token,
        json!({
            "uuid": entry_uuid,
            "group": "Owner",
            "nonce": b64(b"owner-nonce"),
            "ciphertext": b64(b"owner-ciphertext"),
        }),
    )
    .await;

    let attack = signed_request_no_assert(
        &base_url,
        "POST",
        &format!("/api/vaults/{}/entries", attacker_vault),
        &attacker_id,
        &attacker_token,
        json!({
            "uuid": entry_uuid,
            "group": "Attacker",
            "nonce": b64(b"attacker-nonce"),
            "ciphertext": b64(b"attacker-ciphertext"),
        }),
    )
    .await;
    assert_eq!(attack.status().as_u16(), 403);

    let owner_entries: Value = signed_request(
        &base_url,
        "GET",
        &format!("/api/vaults/{}/entries", owner_vault),
        &owner_id,
        &owner_token,
        json!({}),
    )
    .await
    .json()
    .await
    .unwrap();
    assert_eq!(
        owner_entries["entries"][0]["ciphertext"].as_str().unwrap(),
        b64(b"owner-ciphertext")
    );

    let attacker_entries: Value = signed_request(
        &base_url,
        "GET",
        &format!("/api/vaults/{}/entries", attacker_vault),
        &attacker_id,
        &attacker_token,
        json!({}),
    )
    .await
    .json()
    .await
    .unwrap();
    assert!(attacker_entries["entries"].as_array().unwrap().is_empty());
}

#[tokio::test]
async fn entry_row_optimistic_lock() {
    let base_url = spawn_server().await;
    let (user_id, token) = register_user(&base_url, "entry-lock@example.com").await;

    let vault_id = generate_id();
    signed_request(
        &base_url,
        "POST",
        "/api/vaults",
        &user_id,
        &token,
        json!({
            "id": vault_id,
            "name": "Lock",
            "nonce": b64(b"vault-nonce"),
            "ciphertext": b64(b"vault-ct"),
        }),
    )
    .await;

    let entry_uuid = generate_id();
    signed_request(
        &base_url,
        "POST",
        &format!("/api/vaults/{}/entries", vault_id),
        &user_id,
        &token,
        json!({
            "uuid": entry_uuid,
            "group": "A",
            "nonce": b64(b"n1"),
            "ciphertext": b64(b"c1"),
        }),
    )
    .await;

    // Read the row's current version.
    let listed: Value = signed_request(
        &base_url,
        "GET",
        &format!("/api/vaults/{}/entries", vault_id),
        &user_id,
        &token,
        json!({}),
    )
    .await
    .json()
    .await
    .unwrap();
    let base = listed["entries"][0]["updatedAt"].as_i64().unwrap();

    // Upsert based on the current version succeeds.
    let ok_resp = signed_request(
        &base_url,
        "POST",
        &format!("/api/vaults/{}/entries", vault_id),
        &user_id,
        &token,
        json!({
            "uuid": entry_uuid,
            "group": "B",
            "nonce": b64(b"n2"),
            "ciphertext": b64(b"c2"),
            "baseUpdatedAt": base,
        }),
    )
    .await;
    assert!(ok_resp.status().is_success());

    // A stale base is rejected with 409.
    let stale = signed_request_no_assert(
        &base_url,
        "POST",
        &format!("/api/vaults/{}/entries", vault_id),
        &user_id,
        &token,
        json!({
            "uuid": entry_uuid,
            "group": "C",
            "nonce": b64(b"n3"),
            "ciphertext": b64(b"c3"),
            "baseUpdatedAt": base,
        }),
    )
    .await;
    assert_eq!(stale.status().as_u16(), 409);
    let stale_json: Value = stale.json().await.unwrap();
    assert_eq!(stale_json["error"], "conflict");

    // Without a base the upsert is legacy-unconditional.
    let legacy = signed_request_no_assert(
        &base_url,
        "POST",
        &format!("/api/vaults/{}/entries", vault_id),
        &user_id,
        &token,
        json!({
            "uuid": entry_uuid,
            "group": "D",
            "nonce": b64(b"n4"),
            "ciphertext": b64(b"c4"),
        }),
    )
    .await;
    assert!(legacy.status().is_success());

    // A brand-new row with a base is fine (no existing row to conflict with).
    let new_uuid = generate_id();
    let new_row = signed_request(
        &base_url,
        "POST",
        &format!("/api/vaults/{}/entries", vault_id),
        &user_id,
        &token,
        json!({
            "uuid": new_uuid,
            "group": "E",
            "nonce": b64(b"n5"),
            "ciphertext": b64(b"c5"),
            "baseUpdatedAt": 0,
        }),
    )
    .await;
    assert!(new_row.status().is_success());
}

#[tokio::test]
async fn entry_batch_sync() {
    let base_url = spawn_server().await;
    let (user_id, token) = register_user(&base_url, "batch@example.com").await;

    let vault_id = generate_id();
    signed_request(
        &base_url,
        "POST",
        "/api/vaults",
        &user_id,
        &token,
        json!({
            "id": vault_id,
            "name": "Batch",
            "nonce": b64(b"vault-nonce"),
            "ciphertext": b64(b"vault-ct"),
        }),
    )
    .await;

    // Batch upsert of three fresh rows + one delete.
    let a = generate_id();
    let b = generate_id();
    let c = generate_id();
    let resp: Value = signed_request(
        &base_url,
        "POST",
        &format!("/api/vaults/{}/entries/sync", vault_id),
        &user_id,
        &token,
        json!({
            "upserts": [
                {"uuid": a, "group": "G", "nonce": b64(b"a1"), "ciphertext": b64(b"c1"), "baseUpdatedAt": 0},
                {"uuid": b, "group": "G", "nonce": b64(b"a2"), "ciphertext": b64(b"c2"), "baseUpdatedAt": 0},
                {"uuid": c, "group": "G", "nonce": b64(b"a3"), "ciphertext": b64(b"c3"), "baseUpdatedAt": 0},
            ],
            "deletes": [],
        }),
    )
    .await
    .json()
    .await
    .unwrap();
    assert_eq!(resp["upserted"].as_array().unwrap().len(), 3);
    assert!(resp["conflicts"].as_array().unwrap().is_empty());

    // Re-uploading the same rows with a stale base (0) flags them as conflicts
    // instead of overwriting.
    let resp: Value = signed_request(
        &base_url,
        "POST",
        &format!("/api/vaults/{}/entries/sync", vault_id),
        &user_id,
        &token,
        json!({
            "upserts": [
                {"uuid": a, "group": "G", "nonce": b64(b"z"), "ciphertext": b64(b"z"), "baseUpdatedAt": 0},
                {"uuid": b, "group": "G", "nonce": b64(b"z"), "ciphertext": b64(b"z"), "baseUpdatedAt": 0},
            ],
            "deletes": [c],
        }),
    )
    .await
    .json()
    .await
    .unwrap();
    assert_eq!(resp["upserted"].as_array().unwrap().len(), 0);
    assert_eq!(resp["conflicts"].as_array().unwrap().len(), 2);

    // c was deleted.
    let listed: Value = signed_request(
        &base_url,
        "GET",
        &format!("/api/vaults/{}/entries", vault_id),
        &user_id,
        &token,
        json!({}),
    )
    .await
    .json()
    .await
    .unwrap();
    let uuids = listed["entries"]
        .as_array()
        .unwrap()
        .iter()
        .map(|e| e["uuid"].as_str().unwrap().to_string())
        .collect::<Vec<_>>();
    assert!(uuids.contains(&a));
    assert!(uuids.contains(&b));
    assert!(!uuids.contains(&c));
}

#[tokio::test]
async fn entry_batch_sync_spans_sql_chunks() {
    let base_url = spawn_server().await;
    let (user_id, token) = register_user(&base_url, "batch-chunks@example.com").await;
    let vault_id = generate_id();
    signed_request(
        &base_url,
        "POST",
        "/api/vaults",
        &user_id,
        &token,
        json!({
            "id": vault_id,
            "name": "Chunked batch",
            "nonce": b64(b"vault-nonce"),
            "ciphertext": b64(b"vault-ct"),
        }),
    )
    .await;

    let upserts: Vec<Value> = (0..130)
        .map(|index| {
            json!({
                "uuid": generate_id(),
                "group": "G",
                "nonce": b64(format!("nonce-{index}").as_bytes()),
                "ciphertext": b64(format!("ciphertext-{index}").as_bytes()),
                "baseUpdatedAt": 0,
            })
        })
        .collect();
    let response: Value = signed_request(
        &base_url,
        "POST",
        &format!("/api/vaults/{}/entries/sync", vault_id),
        &user_id,
        &token,
        json!({"upserts": upserts, "deletes": []}),
    )
    .await
    .json()
    .await
    .unwrap();
    assert_eq!(response["upserted"].as_array().unwrap().len(), 130);

    let listed: Value = signed_request(
        &base_url,
        "GET",
        &format!("/api/vaults/{}/entries", vault_id),
        &user_id,
        &token,
        json!({}),
    )
    .await
    .json()
    .await
    .unwrap();
    assert_eq!(listed["entries"].as_array().unwrap().len(), 130);
}

#[tokio::test]
async fn sync_entries_validation_failure_is_atomic_bits_ut() {
    let base_url = spawn_server().await;
    let (user_id, token) = register_user(&base_url, "batch-atomic@example.com").await;
    let vault_id = generate_id();
    signed_request(
        &base_url,
        "POST",
        "/api/vaults",
        &user_id,
        &token,
        json!({
            "id": vault_id,
            "name": "Atomic batch",
            "nonce": b64(b"vault-nonce"),
            "ciphertext": b64(b"vault-ct"),
        }),
    )
    .await;

    let response = signed_request_no_assert(
        &base_url,
        "POST",
        &format!("/api/vaults/{}/entries/sync", vault_id),
        &user_id,
        &token,
        json!({
            "upserts": [
                {
                    "uuid": generate_id(),
                    "group": "valid",
                    "nonce": b64(b"valid-nonce"),
                    "ciphertext": b64(b"valid-ciphertext"),
                    "baseUpdatedAt": 0
                },
                {
                    "uuid": generate_id(),
                    "group": "invalid",
                    "nonce": "not-base64!",
                    "ciphertext": b64(b"invalid-ciphertext"),
                    "baseUpdatedAt": 0
                }
            ],
            "deletes": [],
        }),
    )
    .await;
    assert_eq!(response.status().as_u16(), 400);

    let listed: Value = signed_request(
        &base_url,
        "GET",
        &format!("/api/vaults/{}/entries", vault_id),
        &user_id,
        &token,
        json!({}),
    )
    .await
    .json()
    .await
    .unwrap();
    assert!(
        listed["entries"].as_array().unwrap().is_empty(),
        "a rejected batch must not leave earlier rows committed"
    );
}

#[tokio::test]
async fn share_crud() {
    let base_url = spawn_server().await;
    let (owner_id, owner_token) = register_user(&base_url, "owner@example.com").await;
    let (recipient_id, recipient_token) = register_user(&base_url, "recipient@example.com").await;

    // Owner creates a vault + entry
    let vault_id = generate_id();
    signed_request(
        &base_url,
        "POST",
        "/api/vaults",
        &owner_id,
        &owner_token,
        json!({
            "id": vault_id,
            "name": "Shared",
            "nonce": b64(b"vault-nonce"),
            "ciphertext": b64(b"vault-ct"),
        }),
    )
    .await;
    let entry_uuid = generate_id();
    signed_request(
        &base_url,
        "POST",
        &format!("/api/vaults/{}/entries", vault_id),
        &owner_id,
        &owner_token,
        json!({
            "uuid": entry_uuid,
            "group": "Shared",
            "nonce": b64(b"entry-nonce"),
            "ciphertext": b64(b"entry-ct"),
        }),
    )
    .await;

    // Create share
    let resp: Value = signed_request(
        &base_url,
        "POST",
        &format!("/api/vaults/{}/shares", vault_id),
        &owner_id,
        &owner_token,
        json!({
            "entryUuid": entry_uuid,
            "recipientUsername": "recipient@example.com",
            "encryptedShareKey": b64(b"share-key"),
            "sharedNonce": b64(b"share-nonce"),
            "sharedCiphertext": b64(b"share-ct"),
        }),
    )
    .await
    .json()
    .await
    .unwrap();
    assert_eq!(resp["share"]["entryUuid"].as_str().unwrap(), entry_uuid);
    assert_eq!(
        resp["share"]["recipientUsername"].as_str().unwrap(),
        "recipient@example.com"
    );
    let share_id = resp["share"]["id"].as_str().unwrap().to_string();

    // Owner outgoing shares
    let resp: Value = signed_request(
        &base_url,
        "GET",
        "/api/shares/outgoing",
        &owner_id,
        &owner_token,
        json!({}),
    )
    .await
    .json()
    .await
    .unwrap();
    let outgoing = resp["shares"].as_array().unwrap();
    assert_eq!(outgoing.len(), 1);
    assert_eq!(outgoing[0]["id"].as_str().unwrap(), share_id);

    // Recipient incoming shares
    let resp: Value = signed_request(
        &base_url,
        "GET",
        "/api/shares/incoming",
        &recipient_id,
        &recipient_token,
        json!({}),
    )
    .await
    .json()
    .await
    .unwrap();
    let incoming = resp["shares"].as_array().unwrap();
    assert_eq!(incoming.len(), 1);
    assert_eq!(incoming[0]["entryUuid"].as_str().unwrap(), entry_uuid);

    // Delete share as recipient
    let resp: Value = signed_request(
        &base_url,
        "DELETE",
        &format!("/api/shares/{}", share_id),
        &recipient_id,
        &recipient_token,
        json!({}),
    )
    .await
    .json()
    .await
    .unwrap();
    assert_eq!(resp["ok"], true);

    let resp: Value = signed_request(
        &base_url,
        "GET",
        "/api/shares/incoming",
        &recipient_id,
        &recipient_token,
        json!({}),
    )
    .await
    .json()
    .await
    .unwrap();
    assert!(resp["shares"].as_array().unwrap().is_empty());
}

#[tokio::test]
async fn group_share_crud() {
    let base_url = spawn_server().await;
    let (owner_id, owner_token) = register_user(&base_url, "g-owner@example.com").await;
    let (recipient_id, recipient_token) = register_user(&base_url, "g-recipient@example.com").await;

    // Owner creates a vault with two entries.
    let vault_id = generate_id();
    signed_request(
        &base_url,
        "POST",
        "/api/vaults",
        &owner_id,
        &owner_token,
        json!({
            "id": vault_id,
            "name": "Team",
            "nonce": b64(b"vault-nonce"),
            "ciphertext": b64(b"vault-ct"),
        }),
    )
    .await;
    let first_uuid = generate_id();
    let second_uuid = generate_id();
    for uuid in [&first_uuid, &second_uuid] {
        signed_request(
            &base_url,
            "POST",
            &format!("/api/vaults/{}/entries", vault_id),
            &owner_id,
            &owner_token,
            json!({
                "uuid": uuid,
                "group": "Shared",
                "nonce": b64(b"entry-nonce"),
                "ciphertext": b64(b"entry-ct"),
            }),
        )
        .await;
    }

    // Create a dynamic group share with both rows.
    let resp: Value = signed_request(
        &base_url,
        "POST",
        &format!("/api/vaults/{}/group-shares", vault_id),
        &owner_id,
        &owner_token,
        json!({
            "recipientUsername": "g-recipient@example.com",
            "encryptedShareKey": b64(b"group-share-key"),
            "nameNonce": b64(b"name-nonce"),
            "nameCiphertext": b64(b"name-ct"),
            "entries": [
                {"entryUuid": first_uuid, "nonce": b64(b"row-1-nonce"), "ciphertext": b64(b"row-1-ct")},
                {"entryUuid": second_uuid, "nonce": b64(b"row-2-nonce"), "ciphertext": b64(b"row-2-ct")}
            ],
        }),
    )
    .await
    .json()
    .await
    .unwrap();
    let share_id = resp["share"]["id"].as_str().unwrap().to_string();
    assert_eq!(resp["entries"].as_array().unwrap().len(), 2);

    // Owner sees it in outgoing; recipient sees it in incoming with the rows.
    let resp: Value = signed_request(
        &base_url,
        "GET",
        "/api/group-shares/outgoing",
        &owner_id,
        &owner_token,
        json!({}),
    )
    .await
    .json()
    .await
    .unwrap();
    assert_eq!(resp["shares"].as_array().unwrap().len(), 1);

    let resp: Value = signed_request(
        &base_url,
        "GET",
        "/api/group-shares/incoming",
        &recipient_id,
        &recipient_token,
        json!({}),
    )
    .await
    .json()
    .await
    .unwrap();
    assert_eq!(resp["shares"].as_array().unwrap().len(), 1);

    let detail: Value = signed_request(
        &base_url,
        "GET",
        &format!("/api/group-shares/{}", share_id),
        &recipient_id,
        &recipient_token,
        json!({}),
    )
    .await
    .json()
    .await
    .unwrap();
    let rows = detail["entries"].as_array().unwrap();
    assert_eq!(rows.len(), 2);
    let row_uuids: Vec<&str> = rows
        .iter()
        .filter_map(|row| row["entryUuid"].as_str())
        .collect();
    assert!(row_uuids.contains(&first_uuid.as_str()));
    assert!(row_uuids.contains(&second_uuid.as_str()));

    // Owner pushes a third row dynamically.
    let third_uuid = generate_id();
    signed_request(
        &base_url,
        "POST",
        &format!("/api/vaults/{}/entries", vault_id),
        &owner_id,
        &owner_token,
        json!({
            "uuid": third_uuid,
            "group": "Shared",
            "nonce": b64(b"entry-3-nonce"),
            "ciphertext": b64(b"entry-3-ct"),
        }),
    )
    .await;
    let resp: Value = signed_request(
        &base_url,
        "POST",
        &format!("/api/group-shares/{}/entries", share_id),
        &owner_id,
        &owner_token,
        json!({
            "entries": [
                {"entryUuid": third_uuid, "nonce": b64(b"row-3-nonce"), "ciphertext": b64(b"row-3-ct")}
            ],
        }),
    )
    .await
    .json()
    .await
    .unwrap();
    assert_eq!(resp["entries"].as_array().unwrap().len(), 3);

    // Owner removes one row; recipient no longer sees it.
    let resp: Value = signed_request(
        &base_url,
        "DELETE",
        &format!("/api/group-shares/{}/entries/{}", share_id, second_uuid),
        &owner_id,
        &owner_token,
        json!({}),
    )
    .await
    .json()
    .await
    .unwrap();
    assert_eq!(resp["ok"], true);
    let detail: Value = signed_request(
        &base_url,
        "GET",
        &format!("/api/group-shares/{}", share_id),
        &recipient_id,
        &recipient_token,
        json!({}),
    )
    .await
    .json()
    .await
    .unwrap();
    let uuids: Vec<&str> = detail["entries"]
        .as_array()
        .unwrap()
        .iter()
        .filter_map(|row| row["entryUuid"].as_str())
        .collect();
    assert_eq!(uuids.len(), 2);
    assert!(!uuids.contains(&second_uuid.as_str()));

    // Recipient can delete the whole group share.
    let resp: Value = signed_request(
        &base_url,
        "DELETE",
        &format!("/api/group-shares/{}", share_id),
        &recipient_id,
        &recipient_token,
        json!({}),
    )
    .await
    .json()
    .await
    .unwrap();
    assert_eq!(resp["ok"], true);
    let resp: Value = signed_request(
        &base_url,
        "GET",
        "/api/group-shares/incoming",
        &recipient_id,
        &recipient_token,
        json!({}),
    )
    .await
    .json()
    .await
    .unwrap();
    assert!(resp["shares"].as_array().unwrap().is_empty());
}

#[tokio::test]
async fn scan_login() {
    let base_url = spawn_server().await;
    let (user_id, token) = register_user(&base_url, "scan-user@example.com").await;
    let client = reqwest::Client::new();

    let (_pc_secret, pc_public) = generate_x25519_keypair();
    let resp: Value = client
        .post(format!("{}/api/login/scan", base_url))
        .json(&json!({
            "publicKey": base64::engine::general_purpose::STANDARD.encode(pc_public)
        }))
        .send()
        .await
        .unwrap()
        .json()
        .await
        .unwrap();
    let session_id = resp["sessionId"].as_str().unwrap().to_string();
    let session_secret = resp["sessionSecret"].as_str().unwrap().to_string();
    assert!(!session_id.is_empty());
    assert!(!session_secret.is_empty());
    assert!(resp["qrContent"].as_str().unwrap().contains(&session_id));

    // Poll pending
    let resp: Value = client
        .get(format!("{}/api/login/scan/{}", base_url, session_id))
        .send()
        .await
        .unwrap()
        .json()
        .await
        .unwrap();
    assert_eq!(resp["status"].as_str().unwrap(), "pending");
    assert!(resp["publicKey"].as_str().is_some());

    // Confirm
    let resp: Value = signed_request(
        &base_url,
        "POST",
        &format!("/api/login/scan/{}/confirm", session_id),
        &user_id,
        &token,
        json!({ "vaultCiphertext": b64(b"vault-ciphertext") }),
    )
    .await
    .json()
    .await
    .unwrap();
    assert_eq!(resp["ok"], true);

    // Poll confirmed WITHOUT the creator secret: the status is visible but the
    // token must never be released to someone who only knows the session id.
    let resp: Value = client
        .get(format!("{}/api/login/scan/{}", base_url, session_id))
        .send()
        .await
        .unwrap()
        .json()
        .await
        .unwrap();
    assert_eq!(resp["status"].as_str().unwrap(), "confirmed");
    assert!(resp["token"].is_null());
    assert!(resp["username"].is_null());
    // The account id (= Secret Key) is part of the confirmed payload and must
    // stay hidden from anyone without the creator secret.
    assert!(resp["userId"].is_null());
    assert!(resp["vaultCiphertext"].is_null());

    // Poll confirmed WITH the creator secret: one-time token is handed over.
    let resp: Value = client
        .get(format!("{}/api/login/scan/{}", base_url, session_id))
        .header("X-Scan-Secret", &session_secret)
        .send()
        .await
        .unwrap()
        .json()
        .await
        .unwrap();
    assert_eq!(resp["status"].as_str().unwrap(), "confirmed");
    assert!(!resp["token"].as_str().unwrap().is_empty());
    assert_eq!(resp["username"].as_str().unwrap(), "scan-user@example.com");
    // The creator also learns the account id so it can sign later requests.
    assert_eq!(resp["userId"].as_str().unwrap(), user_id);
    assert_eq!(
        resp["vaultCiphertext"].as_str().unwrap(),
        base64::engine::general_purpose::STANDARD.encode(b"vault-ciphertext")
    );

    // The session is consumed: a second poll (even with the secret) fails.
    let status = client
        .get(format!("{}/api/login/scan/{}", base_url, session_id))
        .header("X-Scan-Secret", &session_secret)
        .send()
        .await
        .unwrap()
        .status()
        .as_u16();
    assert_eq!(status, 404);
}

#[tokio::test]
async fn app_versions() {
    let base_url = spawn_server().await;
    let client = reqwest::Client::new();

    // No version yet
    let resp = client
        .get(format!("{}/api/versions/latest?platform=android", base_url))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 404);

    // Publish without key fails
    let resp = client
        .post(format!("{}/api/versions/publish", base_url))
        .json(&json!({
            "platform": "android",
            "versionName": "1.0.0",
            "versionCode": 1,
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 401);

    // Publish with key
    let resp = client
        .post(format!("{}/api/versions/publish", base_url))
        .header("X-Publish-Key", "secret-publish-key")
        .json(&json!({
            "platform": "android",
            "versionName": "1.0.0",
            "versionCode": 1,
            "changelog": "first release",
            "downloadUrl": "https://example.com/app.apk",
            "sha256": "deadbeef",
            "fileSize": 123456,
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 201);

    // Get latest
    let resp: Value = client
        .get(format!("{}/api/versions/latest?platform=android", base_url))
        .send()
        .await
        .unwrap()
        .json()
        .await
        .unwrap();
    let v = &resp["version"];
    assert_eq!(v["platform"].as_str().unwrap(), "android");
    assert_eq!(v["versionName"].as_str().unwrap(), "1.0.0");
    assert_eq!(v["versionCode"].as_i64().unwrap(), 1);
    assert_eq!(v["changelog"].as_str().unwrap(), "first release");
    assert_eq!(
        v["downloadUrl"].as_str().unwrap(),
        "https://example.com/app.apk"
    );
    assert_eq!(v["sha256"].as_str().unwrap(), "deadbeef");
    assert_eq!(v["fileSize"].as_i64().unwrap(), 123456);

    // Older/equal version conflicts
    let resp = client
        .post(format!("{}/api/versions/publish", base_url))
        .header("X-Publish-Key", "secret-publish-key")
        .json(&json!({
            "platform": "android",
            "versionName": "0.9.0",
            "versionCode": 1,
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 409);
}

// -----------------------------------------------------------------------------
// helpers
// -----------------------------------------------------------------------------

fn b64(bytes: &[u8]) -> String {
    base64::engine::general_purpose::STANDARD.encode(bytes)
}

async fn spawn_server() -> String {
    let db_url = "sqlite::memory:";
    let mut server_secret = [0u8; 32];
    openvalut_core::secure_random_bytes(&mut server_secret);
    let state = AppState::open(
        DbKind::Sqlite,
        db_url,
        server_secret,
        Some("secret-publish-key".into()),
    )
    .await
    .unwrap();
    let router = openvalut_server::router(state);

    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let port = listener.local_addr().unwrap().port();

    tokio::spawn(async move {
        axum::serve(listener, router).await.unwrap();
    });

    format!("http://127.0.0.1:{}", port)
}

async fn register_user(base_url: &str, username: &str) -> (String, String) {
    let client = reqwest::Client::new();
    let (_user_secret, user_public) = generate_x25519_keypair();
    let body = RegisterRequest {
        username: username.into(),
        password: "master-password".into(),
        public_key: base64::engine::general_purpose::STANDARD.encode(user_public),
    };
    let resp: Value = client
        .post(format!("{}/api/register", base_url))
        .json(&body)
        .send()
        .await
        .unwrap()
        .json()
        .await
        .unwrap();
    let user_id = resp["user"]["id"].as_str().unwrap().to_string();
    let token = resp["token"].as_str().unwrap().to_string();
    (user_id, token)
}

async fn signed_request(
    base_url: &str,
    method: &str,
    path: &str,
    user_id: &str,
    token: &str,
    body: Value,
) -> reqwest::Response {
    let resp = signed_request_no_assert(base_url, method, path, user_id, token, body).await;
    assert!(
        resp.status().is_success(),
        "{} {} failed: {} {:?}",
        method,
        path,
        resp.status(),
        resp.text().await.unwrap_or_default()
    );
    resp
}

/// Same as [signed_request] but without the success assertion, for tests that
/// assert on error responses (e.g. optimistic-concurrency 409s).
async fn signed_request_no_assert(
    base_url: &str,
    method: &str,
    path: &str,
    user_id: &str,
    token: &str,
    body: Value,
) -> reqwest::Response {
    let client = reqwest::Client::new();
    let body_bytes = if body.is_null() || body == json!({}) {
        Vec::new()
    } else {
        serde_json::to_vec(&body).unwrap()
    };

    let timestamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs()
        .to_string();
    let nonce = generate_id();
    let signature = sign_request(user_id, method, path, &timestamp, &nonce, &body_bytes).unwrap();

    let url = format!("{}{}", base_url, path);
    let mut req = client
        .request(method.parse().unwrap(), &url)
        .header("Authorization", format!("Bearer {}", token))
        .header("X-Timestamp", &timestamp)
        .header("X-Nonce", &nonce)
        .header("X-Signature", &signature);

    if !body_bytes.is_empty() {
        req = req
            .header("Content-Type", "application/json")
            .body(body_bytes);
    }

    req.send().await.unwrap()
}
