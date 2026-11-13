use std::collections::{HashMap, HashSet};

use sqlx::{Any, Row, Transaction};

use super::{query_for, Db, DbKind};
use crate::error::ApiError;
use crate::models::Entry;

// Stay below SQLite's conservative 999-variable limit. MySQL also benefits
// from bounded statement sizes for large sync requests.
const MAX_BIND_PARAMS: usize = 900;
const ENTRY_COLUMN_COUNT: usize = 7;

pub struct EntrySyncUpsert {
    pub entry: Entry,
    pub base_updated_at: i64,
}

pub struct EntrySyncResult {
    pub upserted: Vec<(String, i64)>,
    pub conflicts: Vec<String>,
}

impl Db {
    pub async fn sync_entries(
        &self,
        user_id: &str,
        vault_id: &str,
        upserts: Vec<EntrySyncUpsert>,
        deletes: &[String],
    ) -> Result<EntrySyncResult, ApiError> {
        let mut tx: Transaction<Any> = self.pool.begin().await?;
        let owns_vault: i64 = self
            .query_scalar("SELECT COUNT(*) FROM vaults WHERE id = ? AND user_id = ?")
            .bind(vault_id)
            .bind(user_id)
            .fetch_one(&mut *tx)
            .await?;
        if owns_vault == 0 {
            return Err(ApiError::NotFound);
        }

        let existing = load_existing_entries(&mut tx, self.kind, &upserts, deletes).await?;
        let mut accepted = Vec::<(Entry, i64)>::new();
        let mut conflicts = Vec::new();
        for row in upserts {
            if row.entry.vault_id != vault_id {
                return Err(ApiError::Forbidden);
            }
            match existing.get(&row.entry.uuid) {
                Some((stored_vault_id, _)) if stored_vault_id != vault_id => {
                    return Err(ApiError::Forbidden);
                }
                Some((_, updated_at)) if *updated_at != row.base_updated_at => {
                    conflicts.push(row.entry.uuid);
                }
                Some((_, updated_at)) => {
                    let next_updated_at = row.entry.updated_at.max(*updated_at + 1);
                    accepted.push((row.entry, next_updated_at));
                }
                None => {
                    let updated_at = row.entry.updated_at;
                    accepted.push((row.entry, updated_at));
                }
            }
        }

        insert_entries(&mut tx, self.kind, &accepted).await?;
        delete_entries(&mut tx, self.kind, vault_id, deletes, &accepted, &existing).await?;
        // The row store is the source of truth, so the vault's updated_at must
        // move forward too: clients detect "changed on the server" through the
        // vault meta (there is no blob write anymore to bump it).
        let now = super::now_secs();
        let vault_current: i64 = self
            .query_scalar("SELECT updated_at FROM vaults WHERE id = ?")
            .bind(vault_id)
            .fetch_one(&mut *tx)
            .await?;
        let next_vault_updated = now.max(vault_current + 1);
        self.query("UPDATE vaults SET updated_at = ? WHERE id = ?")
            .bind(next_vault_updated)
            .bind(vault_id)
            .execute(&mut *tx)
            .await?;
        tx.commit().await?;

        Ok(EntrySyncResult {
            upserted: accepted
                .into_iter()
                .map(|(entry, updated_at)| (entry.uuid, updated_at))
                .collect(),
            conflicts,
        })
    }
}

async fn load_existing_entries(
    tx: &mut Transaction<'_, Any>,
    kind: DbKind,
    upserts: &[EntrySyncUpsert],
    deletes: &[String],
) -> Result<HashMap<String, (String, i64)>, ApiError> {
    let mut requested_uuids = Vec::with_capacity(upserts.len() + deletes.len());
    requested_uuids.extend(upserts.iter().map(|row| row.entry.uuid.clone()));
    requested_uuids.extend(deletes.iter().cloned());
    requested_uuids.sort_unstable();
    requested_uuids.dedup();

    let mut existing = HashMap::new();
    if requested_uuids.is_empty() {
        return Ok(existing);
    }
    for uuid_chunk in requested_uuids.chunks(MAX_BIND_PARAMS) {
        let placeholders = vec!["?"; uuid_chunk.len()].join(", ");
        let sql = format!(
            "SELECT uuid, vault_id, updated_at FROM entries WHERE uuid IN ({placeholders})"
        );
        let mut query = query_for(kind, &sql);
        for uuid in uuid_chunk {
            query = query.bind(uuid.clone());
        }
        for row in query.fetch_all(&mut **tx).await? {
            existing.insert(
                row.try_get("uuid")?,
                (row.try_get("vault_id")?, row.try_get("updated_at")?),
            );
        }
    }
    Ok(existing)
}

async fn insert_entries(
    tx: &mut Transaction<'_, Any>,
    kind: DbKind,
    accepted: &[(Entry, i64)],
) -> Result<(), ApiError> {
    if accepted.is_empty() {
        return Ok(());
    }
    for entry_chunk in accepted.chunks(MAX_BIND_PARAMS / ENTRY_COLUMN_COUNT) {
        let row_ph = ["?"; ENTRY_COLUMN_COUNT].join(", ");
        let placeholders = vec![row_ph.as_str(); entry_chunk.len()].join("),(");
        let mut sql = format!(
            "INSERT INTO entries \
             (uuid, vault_id, group_name, nonce, ciphertext, updated_at, created_at) \
             VALUES ({placeholders})"
        );
        if kind == DbKind::Mysql {
            sql.push_str(
                " ON DUPLICATE KEY UPDATE \
                 group_name = IF(vault_id = VALUES(vault_id), VALUES(group_name), group_name), \
                 nonce = IF(vault_id = VALUES(vault_id), VALUES(nonce), nonce), \
                 ciphertext = IF(vault_id = VALUES(vault_id), VALUES(ciphertext), ciphertext), \
                 updated_at = IF(vault_id = VALUES(vault_id), VALUES(updated_at), updated_at)",
            );
        } else {
            sql.push_str(
                " ON CONFLICT(uuid) DO UPDATE SET \
                 group_name = excluded.group_name, \
                 nonce = excluded.nonce, \
                 ciphertext = excluded.ciphertext, \
                 updated_at = excluded.updated_at \
                 WHERE entries.vault_id = excluded.vault_id",
            );
        }
        let mut query = query_for(kind, &sql);
        for (entry, updated_at) in entry_chunk {
            query = query
                .bind(entry.uuid.clone())
                .bind(entry.vault_id.clone())
                .bind(entry.group_name.clone())
                .bind(entry.nonce.clone())
                .bind(entry.ciphertext.clone())
                .bind(*updated_at)
                .bind(entry.created_at);
        }
        query.execute(&mut **tx).await?;
    }
    Ok(())
}

async fn delete_entries(
    tx: &mut Transaction<'_, Any>,
    kind: DbKind,
    vault_id: &str,
    deletes: &[String],
    accepted: &[(Entry, i64)],
    existing: &HashMap<String, (String, i64)>,
) -> Result<(), ApiError> {
    let accepted_uuids: HashSet<&str> = accepted
        .iter()
        .map(|(entry, _)| entry.uuid.as_str())
        .collect();
    for uuid in deletes {
        match existing.get(uuid) {
            Some((stored_vault_id, _)) if stored_vault_id == vault_id => {}
            None if accepted_uuids.contains(uuid.as_str()) => {}
            _ => return Err(ApiError::NotFound),
        }
    }
    if deletes.is_empty() {
        return Ok(());
    }

    for uuid_chunk in deletes.chunks(MAX_BIND_PARAMS - 1) {
        let placeholders = vec!["?"; uuid_chunk.len()].join(", ");
        let stmts = [
            format!("DELETE FROM group_share_entries WHERE entry_uuid IN ({placeholders})"),
            format!("DELETE FROM shares WHERE entry_uuid IN ({placeholders})"),
            format!("DELETE FROM entries WHERE vault_id = ? AND uuid IN ({placeholders})"),
        ];
        for (i, sql) in stmts.iter().enumerate() {
            let mut query = query_for(kind, sql);
            if i == 2 {
                query = query.bind(vault_id);
            }
            for uuid in uuid_chunk {
                query = query.bind(uuid.clone());
            }
            query.execute(&mut **tx).await?;
        }
    }
    Ok(())
}
