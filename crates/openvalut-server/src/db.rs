//! Database layer for the OpenValut server.
//!
//! The schema matches the Go server (`server/internal/db/db.go`) so that the
//! Rust server can be dropped in as a protocol-compatible replacement. The
//! implementation uses sqlx's `Any` driver so the same queries work against
//! both SQLite (dev/tests) and MySQL (production).

use std::str::FromStr;
use std::time::{SystemTime, UNIX_EPOCH};

use sqlx::any::{AnyPoolOptions, AnyRow};
use sqlx::{Any, Pool, Row, Transaction};

use crate::error::ApiError;
use crate::models::{
    AppVersion, Entry, GroupShare, GroupShareEntry, ScanSession, Share, User, Vault,
};

mod entry_sync;
pub use entry_sync::{EntrySyncResult, EntrySyncUpsert};

/// Supported database backends.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DbKind {
    Sqlite,
    Mysql,
    Postgres,
}

impl DbKind {
    pub fn as_str(&self) -> &'static str {
        match self {
            DbKind::Sqlite => "sqlite",
            DbKind::Mysql => "mysql",
            DbKind::Postgres => "postgres",
        }
    }
}

impl FromStr for DbKind {
    type Err = ApiError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "sqlite" => Ok(DbKind::Sqlite),
            "mysql" => Ok(DbKind::Mysql),
            "postgres" | "postgresql" | "pg" => Ok(DbKind::Postgres),
            _ => Err(ApiError::BadRequestMsg(format!("unknown db kind: {s}"))),
        }
    }
}

/// Database handle.
#[derive(Debug, Clone)]
pub struct Db {
    pool: Pool<Any>,
    kind: DbKind,
}

/// sqlite/mysql take `?` placeholders; PostgreSQL wants numbered `$n`.
/// Rewrite `?` to `$1..$N` outside string literals so the same SQL text
/// can be issued against every backend.
pub(super) fn to_pg_placeholders(sql: &str) -> String {
    let mut out = String::with_capacity(sql.len() + 8);
    let mut n = 0usize;
    let mut in_string = false;
    for ch in sql.chars() {
        match ch {
            '\'' => {
                in_string = !in_string;
                out.push('\'');
            }
            '?' if !in_string => {
                n += 1;
                out.push_str(&format!("${n}"));
            }
            _ => out.push(ch),
        }
    }
    out
}

/// Rewritten SQL lives for the rest of the process, one entry per distinct
/// statement text. Statement texts here are either static constants or
/// bounded sets (index DDL, chunked IN lists), so growth is bounded.
pub(super) fn pg_cached(sql: &str) -> &'static str {
    use std::collections::HashMap;
    use std::sync::{LazyLock, Mutex};
    static CACHE: LazyLock<Mutex<HashMap<String, &'static str>>> =
        LazyLock::new(|| Mutex::new(HashMap::new()));
    if let Ok(cache) = CACHE.lock() {
        if let Some(cached) = cache.get(sql) {
            return cached;
        }
    }
    let leaked: &'static str = Box::leak(to_pg_placeholders(sql).into_boxed_str());
    if let Ok(mut cache) = CACHE.lock() {
        cache.insert(sql.to_string(), leaked);
    }
    leaked
}

/// Free-function counterpart of `Db::query` for helpers outside `impl Db`.
pub(super) fn query_for(
    kind: DbKind,
    sql: &str,
) -> sqlx::query::Query<'_, Any, sqlx::any::AnyArguments<'_>> {
    if kind == DbKind::Postgres {
        sqlx::query(pg_cached(sql))
    } else {
        sqlx::query(sql)
    }
}

impl Db {
    /// sqlx::query but with backend-aware placeholder rewriting.
    fn query<'q>(&self, sql: &'q str) -> sqlx::query::Query<'q, Any, sqlx::any::AnyArguments<'q>> {
        if self.kind == DbKind::Postgres {
            sqlx::query(pg_cached(sql))
        } else {
            sqlx::query(sql)
        }
    }

    /// sqlx::query_scalar but with backend-aware placeholder rewriting.
    fn query_scalar<'q, O>(
        &self,
        sql: &'q str,
    ) -> sqlx::query::QueryScalar<'q, Any, O, sqlx::any::AnyArguments<'q>>
    where
        O: for<'r> sqlx::Decode<'r, Any> + sqlx::Type<Any>,
    {
        if self.kind == DbKind::Postgres {
            sqlx::query_scalar(pg_cached(sql))
        } else {
            sqlx::query_scalar(sql)
        }
    }

    /// sqlx::query_as but with backend-aware placeholder rewriting.
    fn query_as<'q, O>(
        &self,
        sql: &'q str,
    ) -> sqlx::query::QueryAs<'q, Any, O, sqlx::any::AnyArguments<'q>>
    where
        O: for<'r> sqlx::FromRow<'r, sqlx::any::AnyRow>,
    {
        if self.kind == DbKind::Postgres {
            sqlx::query_as(pg_cached(sql))
        } else {
            sqlx::query_as(sql)
        }
    }

    /// Open a database of `kind` at `dsn`, creating the file/schema if needed.
    pub async fn open(kind: DbKind, dsn: &str) -> Result<Self, ApiError> {
        sqlx::any::install_default_drivers();
        let dsn = normalize_dsn(kind, dsn);
        if kind == DbKind::Mysql {
            validate_mysql_transport(&dsn)?;
        }
        let is_memory = dsn.contains(":memory:");
        let options = AnyPoolOptions::new();
        let options = if kind == DbKind::Sqlite && is_memory {
            // In-memory SQLite databases are per-connection unless the pool is
            // limited to a single connection.
            options.max_connections(1)
        } else {
            options.max_connections(5)
        };
        let pool = options
            .connect(&dsn)
            .await
            .map_err(|e| ApiError::InternalMsg(format!("open database: {e}")))?;
        let db = Self { pool, kind };
        db.migrate().await?;
        Ok(db)
    }

    /// Run the schema migration.
    async fn migrate(&self) -> Result<(), ApiError> {
        let blob = match self.kind {
            DbKind::Mysql => "LONGBLOB",
            DbKind::Postgres => "BYTEA",
            DbKind::Sqlite => "BLOB",
        };

        let stmts: Vec<String> = vec![
            "CREATE TABLE IF NOT EXISTS users (
                id CHAR(32) PRIMARY KEY,
                username VARCHAR(64) NOT NULL UNIQUE,
                password_hash VARCHAR(100) NOT NULL,
                public_key VARCHAR(1024) NOT NULL DEFAULT '',
                created_at BIGINT NOT NULL
            )"
            .into(),
            "CREATE TABLE IF NOT EXISTS tokens (
                token_hash CHAR(64) PRIMARY KEY,
                user_id CHAR(32) NOT NULL,
                created_at BIGINT NOT NULL,
                expires_at BIGINT NOT NULL DEFAULT 0
            )"
            .into(),
            "CREATE TABLE IF NOT EXISTS scan_sessions (
                id CHAR(32) PRIMARY KEY,
                status VARCHAR(16) NOT NULL,
                user_id CHAR(32) NOT NULL DEFAULT '',
                public_key TEXT,
                vault_ciphertext TEXT,
                secret_hash CHAR(64) NOT NULL DEFAULT '',
                created_at BIGINT NOT NULL,
                expires_at BIGINT NOT NULL
            )"
            .into(),
            format!(
                "CREATE TABLE IF NOT EXISTS vaults (
                id CHAR(32) PRIMARY KEY,
                user_id CHAR(32) NOT NULL,
                name VARCHAR(1024) NOT NULL,
                nonce {blob} NOT NULL,
                ciphertext {blob} NOT NULL,
                created_at BIGINT NOT NULL,
                updated_at BIGINT NOT NULL
            )"
            ),
            format!(
                "CREATE TABLE IF NOT EXISTS entries (
                uuid CHAR(32) PRIMARY KEY,
                vault_id CHAR(32) NOT NULL,
                group_name VARCHAR(1024) NOT NULL DEFAULT '',
                nonce {blob} NOT NULL,
                ciphertext {blob} NOT NULL,
                updated_at BIGINT NOT NULL,
                created_at BIGINT NOT NULL
            )"
            ),
            format!(
                "CREATE TABLE IF NOT EXISTS shares (
                id CHAR(32) PRIMARY KEY,
                entry_uuid CHAR(32) NOT NULL,
                owner_user_id CHAR(32) NOT NULL,
                recipient_user_id CHAR(32) NOT NULL,
                encrypted_share_key {blob} NOT NULL,
                shared_nonce {blob} NOT NULL,
                shared_ciphertext {blob} NOT NULL,
                created_at BIGINT NOT NULL,
                UNIQUE(entry_uuid, recipient_user_id)
            )"
            ),
            format!(
                "CREATE TABLE IF NOT EXISTS group_shares (
                id CHAR(32) PRIMARY KEY,
                vault_id CHAR(32) NOT NULL,
                owner_user_id CHAR(32) NOT NULL,
                recipient_user_id CHAR(32) NOT NULL,
                encrypted_share_key {blob} NOT NULL,
                name_nonce {blob} NOT NULL,
                name_ciphertext {blob} NOT NULL,
                created_at BIGINT NOT NULL
            )"
            ),
            format!(
                "CREATE TABLE IF NOT EXISTS group_share_entries (
                share_id CHAR(32) NOT NULL,
                entry_uuid CHAR(32) NOT NULL,
                nonce {blob} NOT NULL,
                ciphertext {blob} NOT NULL,
                updated_at BIGINT NOT NULL,
                created_at BIGINT NOT NULL,
                PRIMARY KEY (share_id, entry_uuid)
            )"
            ),
            "CREATE TABLE IF NOT EXISTS app_versions (
                id CHAR(32) PRIMARY KEY,
                platform VARCHAR(16) NOT NULL,
                version_name VARCHAR(32) NOT NULL,
                version_code BIGINT NOT NULL,
                changelog TEXT NOT NULL,
                file_key VARCHAR(255) NOT NULL DEFAULT '',
                download_url VARCHAR(512) NOT NULL DEFAULT '',
                sha256 VARCHAR(64) NOT NULL DEFAULT '',
                file_size BIGINT NOT NULL DEFAULT 0,
                created_at BIGINT NOT NULL,
                UNIQUE(platform, version_code)
            )"
            .into(),
        ];
        for stmt in &stmts {
            self.query(stmt)
                .execute(&self.pool)
                .await
                .map_err(|e| ApiError::InternalMsg(format!("migrate: {e}")))?;
        }

        self.create_index_if_missing("idx_vaults_user", "vaults", "user_id")
            .await?;
        self.create_index_if_missing("idx_entries_vault", "entries", "vault_id")
            .await?;
        self.create_index_if_missing("idx_shares_recipient", "shares", "recipient_user_id")
            .await?;
        self.create_index_if_missing(
            "idx_group_shares_recipient",
            "group_shares",
            "recipient_user_id",
        )
        .await?;
        self.create_index_if_missing("idx_group_shares_owner", "group_shares", "owner_user_id")
            .await?;
        self.create_index_if_missing(
            "idx_group_share_entries_share",
            "group_share_entries",
            "share_id",
        )
        .await?;
        self.create_index_if_missing(
            "idx_group_share_entries_uuid",
            "group_share_entries",
            "entry_uuid",
        )
        .await?;

        self.ensure_column_if_missing(
            "scan_sessions",
            "secret_hash",
            "ALTER TABLE scan_sessions ADD COLUMN secret_hash CHAR(64) NOT NULL DEFAULT ''",
        )
        .await?;

        Ok(())
    }

    /// Adds a column to an existing table when it is missing, so databases
    /// created before the column existed keep working (CREATE TABLE IF NOT
    /// EXISTS does not alter existing tables).
    async fn ensure_column_if_missing(
        &self,
        table: &str,
        column: &str,
        alter_ddl: &str,
    ) -> Result<(), ApiError> {
        let exists = if self.kind == DbKind::Mysql {
            let n: i64 = self
                .query_scalar(
                    "SELECT COUNT(*) FROM information_schema.columns
                 WHERE table_schema = DATABASE() AND table_name = ? AND column_name = ?",
                )
                .bind(table)
                .bind(column)
                .fetch_one(&self.pool)
                .await?;
            n > 0
        } else if self.kind == DbKind::Postgres {
            let n: i64 = self
                .query_scalar(
                    "SELECT COUNT(*) FROM information_schema.columns
                 WHERE table_schema = current_schema() AND table_name = ? AND column_name = ?",
                )
                .bind(table)
                .bind(column)
                .fetch_one(&self.pool)
                .await?;
            n > 0
        } else {
            let n: i64 = self
                .query_scalar(&format!(
                    "SELECT COUNT(*) FROM pragma_table_info('{table}') WHERE name = ?"
                ))
                .bind(column)
                .fetch_one(&self.pool)
                .await?;
            n > 0
        };
        if !exists {
            self.query(alter_ddl)
                .execute(&self.pool)
                .await
                .map_err(|e| ApiError::InternalMsg(format!("migrate add column: {e}")))?;
        }
        Ok(())
    }

    async fn create_index_if_missing(
        &self,
        name: &str,
        table: &str,
        columns: &str,
    ) -> Result<(), ApiError> {
        if self.kind == DbKind::Mysql {
            let n: i64 = self
                .query_scalar(
                    "SELECT COUNT(*) FROM information_schema.statistics
                 WHERE table_schema = DATABASE() AND table_name = ? AND index_name = ?",
                )
                .bind(table)
                .bind(name)
                .fetch_one(&self.pool)
                .await?;
            if n > 0 {
                return Ok(());
            }
            self.query(&format!("CREATE INDEX {name} ON {table}({columns})"))
                .execute(&self.pool)
                .await?;
            return Ok(());
        }
        self.query(&format!(
            "CREATE INDEX IF NOT EXISTS {name} ON {table}({columns})"
        ))
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    // -----------------------------------------------------------------------
    // users
    // -----------------------------------------------------------------------

    pub async fn create_user(&self, user: &User) -> Result<(), ApiError> {
        self.query(
            "INSERT INTO users (id, username, password_hash, public_key, created_at)
             VALUES (?, ?, ?, ?, ?)",
        )
        .bind(&user.id)
        .bind(&user.username)
        .bind(&user.password_hash)
        .bind(&user.public_key)
        .bind(user.created_at)
        .execute(&self.pool)
        .await
        .map_err(|e| {
            if is_unique_violation(&e) {
                ApiError::Conflict
            } else {
                ApiError::InternalMsg(format!("create user: {e}"))
            }
        })?;
        Ok(())
    }

    pub async fn user_by_username(&self, username: &str) -> Result<User, ApiError> {
        let row = self
            .query(
                "SELECT id, username, password_hash, public_key, created_at
             FROM users WHERE username = ?",
            )
            .bind(username)
            .fetch_one(&self.pool)
            .await?;
        Ok(user_from_row(&row))
    }

    pub async fn user_by_id(&self, id: &str) -> Result<User, ApiError> {
        let row = self
            .query(
                "SELECT id, username, password_hash, public_key, created_at
             FROM users WHERE id = ?",
            )
            .bind(id)
            .fetch_one(&self.pool)
            .await?;
        Ok(user_from_row(&row))
    }

    pub async fn set_public_key(&self, user_id: &str, public_key: &str) -> Result<(), ApiError> {
        self.query("UPDATE users SET public_key = ? WHERE id = ?")
            .bind(public_key)
            .bind(user_id)
            .execute(&self.pool)
            .await?;
        Ok(())
    }

    // -----------------------------------------------------------------------
    // tokens
    // -----------------------------------------------------------------------

    pub async fn store_token(
        &self,
        token_hash: &str,
        user_id: &str,
        expires_at: i64,
    ) -> Result<(), ApiError> {
        let now = now_secs();
        self.query("DELETE FROM tokens WHERE expires_at > 0 AND expires_at < ?")
            .bind(now)
            .execute(&self.pool)
            .await?;
        self.query(
            "INSERT INTO tokens (token_hash, user_id, created_at, expires_at)
             VALUES (?, ?, ?, ?)",
        )
        .bind(token_hash)
        .bind(user_id)
        .bind(now)
        .bind(expires_at)
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    pub async fn user_id_by_token(&self, token_hash: &str) -> Result<String, ApiError> {
        let row = self
            .query_as::<(String, i64)>(
                "SELECT user_id, expires_at FROM tokens WHERE token_hash = ?",
            )
            .bind(token_hash)
            .fetch_one(&self.pool)
            .await?;
        if row.1 > 0 && row.1 < now_secs() {
            return Err(ApiError::Unauthorized);
        }
        Ok(row.0)
    }

    // -----------------------------------------------------------------------
    // vaults
    // -----------------------------------------------------------------------

    pub async fn create_vault(&self, vault: &Vault) -> Result<(), ApiError> {
        self.query(
            "INSERT INTO vaults (id, user_id, name, nonce, ciphertext, created_at, updated_at)
             VALUES (?, ?, ?, ?, ?, ?, ?)",
        )
        .bind(&vault.id)
        .bind(&vault.user_id)
        .bind(&vault.name)
        .bind(&vault.nonce)
        .bind(&vault.ciphertext)
        .bind(vault.created_at)
        .bind(vault.updated_at)
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    pub async fn vaults_by_user(&self, user_id: &str) -> Result<Vec<Vault>, ApiError> {
        let rows = self
            .query(
                "SELECT id, user_id, name, nonce, ciphertext, created_at, updated_at
             FROM vaults WHERE user_id = ? ORDER BY updated_at DESC",
            )
            .bind(user_id)
            .fetch_all(&self.pool)
            .await?;
        Ok(rows.iter().map(vault_from_row).collect())
    }

    pub async fn vault_by_id(&self, user_id: &str, id: &str) -> Result<Vault, ApiError> {
        let row = self
            .query(
                "SELECT id, user_id, name, nonce, ciphertext, created_at, updated_at
             FROM vaults WHERE user_id = ? AND id = ?",
            )
            .bind(user_id)
            .bind(id)
            .fetch_one(&self.pool)
            .await?;
        Ok(vault_from_row(&row))
    }

    pub async fn vault_meta(&self, user_id: &str, id: &str) -> Result<Vault, ApiError> {
        self.vault_by_id(user_id, id).await
    }

    pub async fn update_vault_blob(
        &self,
        user_id: &str,
        id: &str,
        nonce: &[u8],
        ciphertext: &[u8],
        base_updated_at: Option<i64>,
    ) -> Result<i64, ApiError> {
        let current = self.vault_by_id(user_id, id).await?; // NotFound when missing
        if let Some(base) = base_updated_at {
            if current.updated_at != base {
                // Another writer saved since this client loaded the vault.
                return Err(ApiError::Conflict);
            }
        }
        // Strictly exceed the current version so the optimistic lock holds
        // even for writes that land within the same second.
        let updated_at = now_secs().max(current.updated_at + 1);
        let result = self
            .query(
                "UPDATE vaults SET nonce = ?, ciphertext = ?, updated_at = ?
             WHERE user_id = ? AND id = ? AND updated_at = ?",
            )
            .bind(nonce)
            .bind(ciphertext)
            .bind(updated_at)
            .bind(user_id)
            .bind(id)
            .bind(current.updated_at)
            .execute(&self.pool)
            .await?;
        if result.rows_affected() == 0 {
            return Err(ApiError::Conflict);
        }
        Ok(updated_at)
    }

    pub async fn delete_vault(&self, user_id: &str, id: &str) -> Result<(), ApiError> {
        let mut tx = self.pool.begin().await?;
        self.query(
            "DELETE FROM group_share_entries WHERE share_id IN
             (SELECT id FROM group_shares WHERE vault_id = ?)",
        )
        .bind(id)
        .execute(&mut *tx)
        .await?;
        self.query("DELETE FROM group_shares WHERE vault_id = ?")
            .bind(id)
            .execute(&mut *tx)
            .await?;
        self.query(
            "DELETE FROM shares WHERE entry_uuid IN
             (SELECT uuid FROM entries WHERE vault_id = ?)",
        )
        .bind(id)
        .execute(&mut *tx)
        .await?;
        self.query("DELETE FROM entries WHERE vault_id = ?")
            .bind(id)
            .execute(&mut *tx)
            .await?;
        let result = self
            .query("DELETE FROM vaults WHERE user_id = ? AND id = ?")
            .bind(user_id)
            .bind(id)
            .execute(&mut *tx)
            .await?;
        if result.rows_affected() == 0 {
            return Err(ApiError::NotFound);
        }
        tx.commit().await?;
        Ok(())
    }

    // -----------------------------------------------------------------------
    // entries
    // -----------------------------------------------------------------------

    pub async fn entry_belongs_to_user(
        &self,
        user_id: &str,
        vault_id: &str,
        entry_uuid: &str,
    ) -> bool {
        let Ok(n) = self
            .query_scalar::<i64>(
                "SELECT COUNT(*) FROM entries e
             JOIN vaults v ON v.id = e.vault_id
             WHERE e.uuid = ? AND e.vault_id = ? AND v.user_id = ?",
            )
            .bind(entry_uuid)
            .bind(vault_id)
            .bind(user_id)
            .fetch_one(&self.pool)
            .await
        else {
            return false;
        };
        n > 0
    }

    pub async fn upsert_entry(
        &self,
        entry: &Entry,
        base_updated_at: Option<i64>,
    ) -> Result<i64, ApiError> {
        // Row-level optimistic concurrency: a new row is fine, but an
        // existing row that moved on since the client last read it must be
        // rejected so two writers cannot clobber each other's entry.
        let current: Option<(String, i64)> = self
            .query_as("SELECT vault_id, updated_at FROM entries WHERE uuid = ?")
            .bind(&entry.uuid)
            .fetch_optional(&self.pool)
            .await?;
        if current
            .as_ref()
            .is_some_and(|(vault_id, _)| vault_id != &entry.vault_id)
        {
            return Err(ApiError::Forbidden);
        }
        if let Some(base) = base_updated_at {
            if let Some((_, cur)) = &current {
                if *cur != base {
                    return Err(ApiError::Conflict);
                }
            }
        }
        // Bump the version strictly above the existing row so a write within
        // the same second still advances the lock, and remember the value so
        // the response can tell the client the new version.
        let updated_at = match current {
            Some((_, cur)) => entry.updated_at.max(cur + 1),
            None => entry.updated_at,
        };
        self.query(self.upsert_entry_sql())
            .bind(&entry.uuid)
            .bind(&entry.vault_id)
            .bind(&entry.group_name)
            .bind(&entry.nonce)
            .bind(&entry.ciphertext)
            .bind(updated_at)
            .bind(entry.created_at)
            .execute(&self.pool)
            .await?;
        let stored_vault_id: String = self
            .query_scalar("SELECT vault_id FROM entries WHERE uuid = ?")
            .bind(&entry.uuid)
            .fetch_one(&self.pool)
            .await?;
        if stored_vault_id != entry.vault_id {
            return Err(ApiError::Forbidden);
        }
        Ok(updated_at)
    }

    fn upsert_entry_sql(&self) -> &'static str {
        if self.kind == DbKind::Mysql {
            "INSERT INTO entries (uuid, vault_id, group_name, nonce, ciphertext, updated_at, created_at)
             VALUES (?, ?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE
               group_name = IF(vault_id = VALUES(vault_id), VALUES(group_name), group_name),
               nonce = IF(vault_id = VALUES(vault_id), VALUES(nonce), nonce),
               ciphertext = IF(vault_id = VALUES(vault_id), VALUES(ciphertext), ciphertext),
               updated_at = IF(vault_id = VALUES(vault_id), VALUES(updated_at), updated_at)"
        } else {
            "INSERT INTO entries (uuid, vault_id, group_name, nonce, ciphertext, updated_at, created_at)
             VALUES (?, ?, ?, ?, ?, ?, ?)
             ON CONFLICT(uuid) DO UPDATE SET
               group_name = excluded.group_name,
               nonce = excluded.nonce,
               ciphertext = excluded.ciphertext,
               updated_at = excluded.updated_at
             WHERE entries.vault_id = excluded.vault_id"
        }
    }

    pub async fn entries_by_vault(
        &self,
        user_id: &str,
        vault_id: &str,
    ) -> Result<Vec<Entry>, ApiError> {
        let rows = self
            .query(
                "SELECT e.uuid, e.vault_id, e.group_name, e.nonce, e.ciphertext,
                    e.updated_at, e.created_at
             FROM entries e JOIN vaults v ON v.id = e.vault_id
             WHERE e.vault_id = ? AND v.user_id = ?
             ORDER BY e.updated_at DESC",
            )
            .bind(vault_id)
            .bind(user_id)
            .fetch_all(&self.pool)
            .await?;
        Ok(rows.iter().map(entry_from_row).collect())
    }

    pub async fn delete_entry(
        &self,
        user_id: &str,
        vault_id: &str,
        entry_uuid: &str,
    ) -> Result<(), ApiError> {
        let mut tx: Transaction<Any> = self.pool.begin().await?;
        self.query(
            "DELETE FROM group_share_entries WHERE entry_uuid = ? AND share_id IN
             (SELECT id FROM group_shares WHERE vault_id = ?)",
        )
        .bind(entry_uuid)
        .bind(vault_id)
        .execute(&mut *tx)
        .await?;
        self.query("DELETE FROM shares WHERE entry_uuid = ?")
            .bind(entry_uuid)
            .execute(&mut *tx)
            .await?;
        let result = self
            .query(
                "DELETE FROM entries WHERE uuid = ? AND vault_id = ?
             AND EXISTS (SELECT 1 FROM vaults v WHERE v.id = entries.vault_id AND v.user_id = ?)",
            )
            .bind(entry_uuid)
            .bind(vault_id)
            .bind(user_id)
            .execute(&mut *tx)
            .await?;
        if result.rows_affected() == 0 {
            return Err(ApiError::NotFound);
        }
        tx.commit().await?;
        Ok(())
    }

    // -----------------------------------------------------------------------
    // shares
    // -----------------------------------------------------------------------

    pub async fn create_share(&self, share: &Share) -> Result<(), ApiError> {
        self.query(self.upsert_share_sql())
            .bind(&share.id)
            .bind(&share.entry_uuid)
            .bind(&share.owner_user_id)
            .bind(&share.recipient_user_id)
            .bind(&share.encrypted_share_key)
            .bind(&share.shared_nonce)
            .bind(&share.shared_ciphertext)
            .bind(share.created_at)
            .execute(&self.pool)
            .await?;
        Ok(())
    }

    fn upsert_share_sql(&self) -> &'static str {
        if self.kind == DbKind::Mysql {
            "INSERT INTO shares (id, entry_uuid, owner_user_id, recipient_user_id,
                                encrypted_share_key, shared_nonce, shared_ciphertext, created_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE
               encrypted_share_key = VALUES(encrypted_share_key),
               shared_nonce = VALUES(shared_nonce),
               shared_ciphertext = VALUES(shared_ciphertext)"
        } else {
            "INSERT INTO shares (id, entry_uuid, owner_user_id, recipient_user_id,
                                encrypted_share_key, shared_nonce, shared_ciphertext, created_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)
             ON CONFLICT(entry_uuid, recipient_user_id) DO UPDATE SET
               encrypted_share_key = excluded.encrypted_share_key,
               shared_nonce = excluded.shared_nonce,
               shared_ciphertext = excluded.shared_ciphertext"
        }
    }

    pub async fn shares_for_recipient(&self, recipient_id: &str) -> Result<Vec<Share>, ApiError> {
        let rows = self
            .query(
                "SELECT s.id, s.entry_uuid, s.owner_user_id, s.recipient_user_id,
                    s.encrypted_share_key, s.shared_nonce, s.shared_ciphertext, s.created_at,
                    o.username, r.username
             FROM shares s
             JOIN users o ON o.id = s.owner_user_id
             JOIN users r ON r.id = s.recipient_user_id
             WHERE s.recipient_user_id = ?
             ORDER BY s.created_at DESC",
            )
            .bind(recipient_id)
            .fetch_all(&self.pool)
            .await?;
        Ok(rows.iter().map(share_from_row).collect())
    }

    pub async fn shares_by_owner(&self, owner_id: &str) -> Result<Vec<Share>, ApiError> {
        let rows = self
            .query(
                "SELECT s.id, s.entry_uuid, s.owner_user_id, s.recipient_user_id,
                    s.encrypted_share_key, s.shared_nonce, s.shared_ciphertext, s.created_at,
                    o.username, r.username
             FROM shares s
             JOIN users o ON o.id = s.owner_user_id
             JOIN users r ON r.id = s.recipient_user_id
             WHERE s.owner_user_id = ?
             ORDER BY s.created_at DESC",
            )
            .bind(owner_id)
            .fetch_all(&self.pool)
            .await?;
        Ok(rows.iter().map(share_from_row).collect())
    }

    pub async fn delete_share(
        &self,
        id: &str,
        owner_id: &str,
        recipient_id: &str,
    ) -> Result<(), ApiError> {
        let result = self
            .query(
                "DELETE FROM shares WHERE id = ? AND (owner_user_id = ? OR recipient_user_id = ?)",
            )
            .bind(id)
            .bind(owner_id)
            .bind(recipient_id)
            .execute(&self.pool)
            .await?;
        if result.rows_affected() == 0 {
            return Err(ApiError::NotFound);
        }
        Ok(())
    }

    // -----------------------------------------------------------------------
    // dynamic group shares
    // -----------------------------------------------------------------------

    /// Creates a group share together with its initial member rows. The
    /// caller has already validated that every [entry_uuids] entry belongs to
    /// the share's vault.
    pub async fn create_group_share(
        &self,
        share: &GroupShare,
        entries: &[GroupShareEntry],
    ) -> Result<(), ApiError> {
        let mut tx: Transaction<Any> = self.pool.begin().await?;
        self.query(
            "INSERT INTO group_shares
             (id, vault_id, owner_user_id, recipient_user_id,
              encrypted_share_key, name_nonce, name_ciphertext, created_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        )
        .bind(&share.id)
        .bind(&share.vault_id)
        .bind(&share.owner_user_id)
        .bind(&share.recipient_user_id)
        .bind(&share.encrypted_share_key)
        .bind(&share.name_nonce)
        .bind(&share.name_ciphertext)
        .bind(share.created_at)
        .execute(&mut *tx)
        .await?;
        for entry in entries {
            self.query(
                "INSERT INTO group_share_entries
                 (share_id, entry_uuid, nonce, ciphertext, updated_at, created_at)
                 VALUES (?, ?, ?, ?, ?, ?)",
            )
            .bind(&entry.share_id)
            .bind(&entry.entry_uuid)
            .bind(&entry.nonce)
            .bind(&entry.ciphertext)
            .bind(entry.updated_at)
            .bind(entry.created_at)
            .execute(&mut *tx)
            .await?;
        }
        tx.commit().await?;
        Ok(())
    }

    /// Validates that every uuid in [entry_uuids] belongs to [vault_id].
    pub async fn entries_exist_for_vault(
        &self,
        vault_id: &str,
        entry_uuids: &[String],
    ) -> Result<bool, ApiError> {
        if entry_uuids.is_empty() {
            return Ok(true);
        }
        let mut seen = std::collections::HashSet::with_capacity(entry_uuids.len());
        let mut existing = std::collections::HashSet::new();
        for uuid_chunk in entry_uuids.chunks(500) {
            for uuid in uuid_chunk {
                seen.insert(uuid.clone());
            }
            let mut query =
                sqlx::QueryBuilder::<Any>::new("SELECT uuid FROM entries WHERE vault_id = ");
            query.push_bind(vault_id.to_string());
            query.push(" AND uuid IN (");
            let mut separated = query.separated(", ");
            for uuid in uuid_chunk {
                separated.push_bind(uuid.clone());
            }
            separated.push_unseparated(")");
            for row in query.build().fetch_all(&self.pool).await? {
                let uuid: String = row.try_get(0)?;
                existing.insert(uuid);
            }
        }
        Ok(seen.is_subset(&existing))
    }

    pub async fn group_shares_for_recipient(
        &self,
        recipient_id: &str,
    ) -> Result<Vec<GroupShare>, ApiError> {
        let rows = self
            .query(
                "SELECT g.id, g.vault_id, g.owner_user_id, g.recipient_user_id,
                    g.encrypted_share_key, g.name_nonce, g.name_ciphertext, g.created_at,
                    o.username AS owner_username, r.username AS recipient_username
             FROM group_shares g
             JOIN users o ON o.id = g.owner_user_id
             JOIN users r ON r.id = g.recipient_user_id
             WHERE g.recipient_user_id = ?
             ORDER BY g.created_at DESC",
            )
            .bind(recipient_id)
            .fetch_all(&self.pool)
            .await?;
        Ok(rows.iter().map(group_share_from_row).collect())
    }

    pub async fn group_shares_by_owner(&self, owner_id: &str) -> Result<Vec<GroupShare>, ApiError> {
        let rows = self
            .query(
                "SELECT g.id, g.vault_id, g.owner_user_id, g.recipient_user_id,
                    g.encrypted_share_key, g.name_nonce, g.name_ciphertext, g.created_at,
                    o.username AS owner_username, r.username AS recipient_username
             FROM group_shares g
             JOIN users o ON o.id = g.owner_user_id
             JOIN users r ON r.id = g.recipient_user_id
             WHERE g.owner_user_id = ?
             ORDER BY g.created_at DESC",
            )
            .bind(owner_id)
            .fetch_all(&self.pool)
            .await?;
        Ok(rows.iter().map(group_share_from_row).collect())
    }

    /// Returns a group share only when [user_id] is the owner or the
    /// recipient.
    pub async fn group_share_by_id_for_user(
        &self,
        id: &str,
        user_id: &str,
    ) -> Result<GroupShare, ApiError> {
        let row = self
            .query(
                "SELECT g.id, g.vault_id, g.owner_user_id, g.recipient_user_id,
                    g.encrypted_share_key, g.name_nonce, g.name_ciphertext, g.created_at,
                    o.username AS owner_username, r.username AS recipient_username
             FROM group_shares g
             JOIN users o ON o.id = g.owner_user_id
             JOIN users r ON r.id = g.recipient_user_id
             WHERE g.id = ? AND (g.owner_user_id = ? OR g.recipient_user_id = ?)",
            )
            .bind(id)
            .bind(user_id)
            .bind(user_id)
            .fetch_optional(&self.pool)
            .await?;
        row.map(|row| group_share_from_row(&row))
            .ok_or(ApiError::NotFound)
    }

    pub async fn group_share_entries(
        &self,
        share_id: &str,
    ) -> Result<Vec<GroupShareEntry>, ApiError> {
        let rows = self
            .query(
                "SELECT share_id, entry_uuid, nonce, ciphertext, updated_at, created_at
             FROM group_share_entries
             WHERE share_id = ?
             ORDER BY updated_at ASC",
            )
            .bind(share_id)
            .fetch_all(&self.pool)
            .await?;
        Ok(rows.iter().map(group_share_entry_from_row).collect())
    }

    pub async fn upsert_group_share_entries(
        &self,
        share_id: &str,
        entries: &[GroupShareEntry],
    ) -> Result<(), ApiError> {
        if entries.is_empty() {
            return Ok(());
        }
        for entry in entries {
            self.query(self.upsert_group_share_entry_sql())
                .bind(&entry.share_id)
                .bind(&entry.entry_uuid)
                .bind(&entry.nonce)
                .bind(&entry.ciphertext)
                .bind(entry.updated_at)
                .bind(entry.created_at)
                .execute(&self.pool)
                .await?;
        }
        let _ = share_id;
        Ok(())
    }

    fn upsert_group_share_entry_sql(&self) -> &'static str {
        if self.kind == DbKind::Mysql {
            "INSERT INTO group_share_entries
             (share_id, entry_uuid, nonce, ciphertext, updated_at, created_at)
             VALUES (?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE
               nonce = VALUES(nonce),
               ciphertext = VALUES(ciphertext),
               updated_at = VALUES(updated_at)"
        } else {
            "INSERT INTO group_share_entries
             (share_id, entry_uuid, nonce, ciphertext, updated_at, created_at)
             VALUES (?, ?, ?, ?, ?, ?)
             ON CONFLICT(share_id, entry_uuid) DO UPDATE SET
               nonce = excluded.nonce,
               ciphertext = excluded.ciphertext,
               updated_at = excluded.updated_at"
        }
    }

    pub async fn remove_group_share_entry(
        &self,
        share_id: &str,
        entry_uuid: &str,
    ) -> Result<(), ApiError> {
        let result = self
            .query("DELETE FROM group_share_entries WHERE share_id = ? AND entry_uuid = ?")
            .bind(share_id)
            .bind(entry_uuid)
            .execute(&self.pool)
            .await?;
        if result.rows_affected() == 0 {
            return Err(ApiError::NotFound);
        }
        Ok(())
    }

    pub async fn delete_group_share(&self, id: &str, user_id: &str) -> Result<(), ApiError> {
        let mut tx: Transaction<Any> = self.pool.begin().await?;
        self.query("DELETE FROM group_share_entries WHERE share_id = ?")
            .bind(id)
            .execute(&mut *tx)
            .await?;
        let result = self
            .query(
                "DELETE FROM group_shares WHERE id = ? AND
             (owner_user_id = ? OR recipient_user_id = ?)",
            )
            .bind(id)
            .bind(user_id)
            .bind(user_id)
            .execute(&mut *tx)
            .await?;
        if result.rows_affected() == 0 {
            return Err(ApiError::NotFound);
        }
        tx.commit().await?;
        Ok(())
    }

    // -----------------------------------------------------------------------
    // app versions
    // -----------------------------------------------------------------------

    pub async fn insert_app_version(&self, version: &AppVersion) -> Result<(), ApiError> {
        self.query(
            "INSERT INTO app_versions
             (id, platform, version_name, version_code, changelog, file_key,
              download_url, sha256, file_size, created_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        )
        .bind(&version.id)
        .bind(&version.platform)
        .bind(&version.version_name)
        .bind(version.version_code)
        .bind(&version.changelog)
        .bind(&version.file_key)
        .bind(&version.download_url)
        .bind(&version.sha256)
        .bind(version.file_size)
        .bind(version.created_at)
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    pub async fn latest_app_version(&self, platform: &str) -> Result<Option<AppVersion>, ApiError> {
        let row = self
            .query(
                "SELECT id, platform, version_name, version_code, changelog,
                    file_key, download_url, sha256, file_size, created_at
             FROM app_versions
             WHERE platform = ?
             ORDER BY version_code DESC
             LIMIT 1",
            )
            .bind(platform)
            .fetch_optional(&self.pool)
            .await?;
        Ok(row.map(|r| app_version_from_row(&r)))
    }

    // -----------------------------------------------------------------------
    // scan login sessions
    // -----------------------------------------------------------------------

    pub async fn create_scan_session(&self, session: &ScanSession) -> Result<(), ApiError> {
        self.query(
            "INSERT INTO scan_sessions (id, status, user_id, public_key, vault_ciphertext, secret_hash, created_at, expires_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        )
        .bind(&session.id)
        .bind(&session.status)
        .bind(&session.user_id)
        .bind(&session.public_key)
        .bind(&session.vault_ciphertext)
        .bind(&session.secret_hash)
        .bind(session.created_at)
        .bind(session.expires_at)
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    pub async fn scan_session_by_id(&self, id: &str) -> Result<ScanSession, ApiError> {
        let row = self.query(
            "SELECT id, status, user_id, public_key, vault_ciphertext, secret_hash, created_at, expires_at
             FROM scan_sessions WHERE id = ?",
        )
        .bind(id)
        .fetch_one(&self.pool)
        .await?;
        Ok(scan_session_from_row(&row))
    }

    pub async fn confirm_scan_session(
        &self,
        id: &str,
        user_id: &str,
        vault_ciphertext: &str,
    ) -> Result<(), ApiError> {
        let result = self
            .query(
                "UPDATE scan_sessions SET status = 'confirmed', user_id = ?, vault_ciphertext = ?
             WHERE id = ? AND status = 'pending'",
            )
            .bind(user_id)
            .bind(vault_ciphertext)
            .bind(id)
            .execute(&self.pool)
            .await?;
        if result.rows_affected() == 0 {
            return Err(ApiError::NotFound);
        }
        Ok(())
    }

    pub async fn delete_scan_session(&self, id: &str) -> Result<(), ApiError> {
        self.query("DELETE FROM scan_sessions WHERE id = ?")
            .bind(id)
            .execute(&self.pool)
            .await?;
        Ok(())
    }
}

fn user_from_row(row: &AnyRow) -> User {
    User {
        id: row.try_get("id").unwrap_or_default(),
        username: row.try_get("username").unwrap_or_default(),
        password_hash: row.try_get("password_hash").unwrap_or_default(),
        public_key: row.try_get("public_key").unwrap_or_default(),
        created_at: row.try_get("created_at").unwrap_or_default(),
    }
}

fn vault_from_row(row: &AnyRow) -> Vault {
    Vault {
        id: row.try_get("id").unwrap_or_default(),
        user_id: row.try_get("user_id").unwrap_or_default(),
        name: row.try_get("name").unwrap_or_default(),
        nonce: row.try_get("nonce").unwrap_or_default(),
        ciphertext: row.try_get("ciphertext").unwrap_or_default(),
        created_at: row.try_get("created_at").unwrap_or_default(),
        updated_at: row.try_get("updated_at").unwrap_or_default(),
    }
}

fn entry_from_row(row: &AnyRow) -> Entry {
    Entry {
        uuid: row.try_get("uuid").unwrap_or_default(),
        vault_id: row.try_get("vault_id").unwrap_or_default(),
        group_name: row.try_get("group_name").unwrap_or_default(),
        nonce: row.try_get("nonce").unwrap_or_default(),
        ciphertext: row.try_get("ciphertext").unwrap_or_default(),
        updated_at: row.try_get("updated_at").unwrap_or_default(),
        created_at: row.try_get("created_at").unwrap_or_default(),
    }
}

fn share_from_row(row: &AnyRow) -> Share {
    Share {
        id: row.try_get("id").unwrap_or_default(),
        entry_uuid: row.try_get("entry_uuid").unwrap_or_default(),
        owner_user_id: row.try_get("owner_user_id").unwrap_or_default(),
        recipient_user_id: row.try_get("recipient_user_id").unwrap_or_default(),
        owner_username: row.try_get::<String, _>("username").unwrap_or_default(),
        recipient_username: row.try_get::<String, _>(9).unwrap_or_default(),
        encrypted_share_key: row.try_get("encrypted_share_key").unwrap_or_default(),
        shared_nonce: row.try_get("shared_nonce").unwrap_or_default(),
        shared_ciphertext: row.try_get("shared_ciphertext").unwrap_or_default(),
        created_at: row.try_get("created_at").unwrap_or_default(),
    }
}

fn group_share_from_row(row: &AnyRow) -> GroupShare {
    GroupShare {
        id: row.try_get("id").unwrap_or_default(),
        vault_id: row.try_get("vault_id").unwrap_or_default(),
        owner_user_id: row.try_get("owner_user_id").unwrap_or_default(),
        recipient_user_id: row.try_get("recipient_user_id").unwrap_or_default(),
        owner_username: row.try_get("owner_username").unwrap_or_default(),
        recipient_username: row.try_get("recipient_username").unwrap_or_default(),
        encrypted_share_key: row.try_get("encrypted_share_key").unwrap_or_default(),
        name_nonce: row.try_get("name_nonce").unwrap_or_default(),
        name_ciphertext: row.try_get("name_ciphertext").unwrap_or_default(),
        created_at: row.try_get("created_at").unwrap_or_default(),
    }
}

fn group_share_entry_from_row(row: &AnyRow) -> GroupShareEntry {
    GroupShareEntry {
        share_id: row.try_get("share_id").unwrap_or_default(),
        entry_uuid: row.try_get("entry_uuid").unwrap_or_default(),
        nonce: row.try_get("nonce").unwrap_or_default(),
        ciphertext: row.try_get("ciphertext").unwrap_or_default(),
        updated_at: row.try_get("updated_at").unwrap_or_default(),
        created_at: row.try_get("created_at").unwrap_or_default(),
    }
}

fn app_version_from_row(row: &AnyRow) -> AppVersion {
    AppVersion {
        id: row.try_get("id").unwrap_or_default(),
        platform: row.try_get("platform").unwrap_or_default(),
        version_name: row.try_get("version_name").unwrap_or_default(),
        version_code: row.try_get("version_code").unwrap_or_default(),
        changelog: row.try_get("changelog").unwrap_or_default(),
        file_key: row.try_get("file_key").unwrap_or_default(),
        download_url: row.try_get("download_url").unwrap_or_default(),
        sha256: row.try_get("sha256").unwrap_or_default(),
        file_size: row.try_get("file_size").unwrap_or_default(),
        created_at: row.try_get("created_at").unwrap_or_default(),
    }
}

fn scan_session_from_row(row: &AnyRow) -> ScanSession {
    ScanSession {
        id: row.try_get("id").unwrap_or_default(),
        status: row.try_get("status").unwrap_or_default(),
        user_id: row.try_get("user_id").unwrap_or_default(),
        public_key: row.try_get("public_key").unwrap_or_default(),
        vault_ciphertext: row.try_get("vault_ciphertext").unwrap_or_default(),
        secret_hash: row.try_get("secret_hash").unwrap_or_default(),
        created_at: row.try_get("created_at").unwrap_or_default(),
        expires_at: row.try_get("expires_at").unwrap_or_default(),
    }
}

fn is_unique_violation(e: &sqlx::Error) -> bool {
    if let sqlx::Error::Database(db) = e {
        let msg = db.message().to_lowercase();
        return msg.contains("unique") || msg.contains("duplicate");
    }
    false
}

fn normalize_dsn(kind: DbKind, dsn: &str) -> String {
    match kind {
        DbKind::Sqlite => {
            let dsn = if dsn.starts_with("sqlite:") {
                dsn.to_string()
            } else {
                format!("sqlite:{dsn}")
            };
            // sqlx's SQLite driver does not create new files by default. Ensure
            // file-based databases are opened read/write/create while leaving
            // in-memory and explicitly configured databases untouched.
            if dsn.contains(":memory:") || dsn.contains("mode=") {
                dsn
            } else if dsn.contains('?') {
                format!("{dsn}&mode=rwc")
            } else {
                format!("{dsn}?mode=rwc")
            }
        }
        DbKind::Postgres => {
            // Accept `postgres://` URLs as-is; anything else is a config error.
            let dsn = dsn.trim();
            if dsn.starts_with("postgres://") || dsn.starts_with("postgresql://") {
                dsn.to_string()
            } else {
                format!("postgres://{dsn}")
            }
        }
        DbKind::Mysql => {
            // sqlx does not understand Go's `parseTime` pseudo-option.
            let stripped = dsn
                .replace("?parseTime=true", "")
                .replace("&parseTime=true", "");
            let stripped = if stripped.ends_with('?') {
                &stripped[..stripped.len() - 1]
            } else {
                &stripped[..]
            };
            if stripped.starts_with("mysql://") {
                stripped.to_string()
            } else {
                // Accept the Go driver style `user:pass@tcp(host:port)/db` and
                // normalise it to the URL form sqlx expects.
                let normalized = stripped.replace("@tcp(", "@").replace(")", "");
                format!("mysql://{normalized}")
            }
        }
    }
}

fn validate_mysql_transport(dsn: &str) -> Result<(), ApiError> {
    let parsed =
        url::Url::parse(dsn).map_err(|_| ApiError::BadRequestMsg("invalid MySQL DSN".into()))?;
    let host = parsed.host_str().unwrap_or_default();
    let local = host.eq_ignore_ascii_case("localhost")
        || host
            .parse::<std::net::IpAddr>()
            .is_ok_and(|address| address.is_loopback());
    let secure = parsed.query_pairs().any(|(key, value)| {
        key.eq_ignore_ascii_case("ssl-mode")
            && matches!(
                value.to_ascii_lowercase().as_str(),
                "required" | "verify-ca" | "verify-identity"
            )
    });
    if local || secure {
        Ok(())
    } else {
        Err(ApiError::BadRequestMsg(
            "remote MySQL requires ssl-mode=required or stronger".into(),
        ))
    }
}

fn now_secs() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs() as i64
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn mysql_dsn_go_style_is_normalized() {
        let dsn = "ov:secret@tcp(127.0.0.1:3306)/openvalut?parseTime=true";
        let out = normalize_dsn(DbKind::Mysql, dsn);
        // Go's `parseTime` option is dropped and the DSN becomes an sqlx URL.
        assert_eq!(out, "mysql://ov:secret@127.0.0.1:3306/openvalut");
    }

    #[test]
    fn mysql_dsn_url_is_kept() {
        let dsn = "mysql://ov:secret@127.0.0.1:3306/openvalut";
        assert_eq!(normalize_dsn(DbKind::Mysql, dsn), dsn);
    }

    #[test]
    fn remote_mysql_requires_tls() {
        assert!(validate_mysql_transport(
            "mysql://openvalut:secret@db.example.com/openvalut?ssl-mode=verify-identity"
        )
        .is_ok());
        assert!(
            validate_mysql_transport("mysql://openvalut:secret@db.example.com/openvalut").is_err()
        );
        assert!(validate_mysql_transport("mysql://openvalut:secret@127.0.0.1/openvalut").is_ok());
    }

    #[test]
    fn sqlite_dsn_is_prefixed_and_created() {
        assert_eq!(
            normalize_dsn(DbKind::Sqlite, "x.db"),
            "sqlite:x.db?mode=rwc"
        );
        assert_eq!(
            normalize_dsn(DbKind::Sqlite, "sqlite::memory:"),
            "sqlite::memory:"
        );
        assert_eq!(
            normalize_dsn(DbKind::Sqlite, "/tmp/foo.db"),
            "sqlite:/tmp/foo.db?mode=rwc"
        );
        assert_eq!(
            normalize_dsn(DbKind::Sqlite, "sqlite:bar.db?mode=ro"),
            "sqlite:bar.db?mode=ro"
        );
    }

    #[test]
    fn postgres_dsn_is_normalized() {
        assert_eq!(
            normalize_dsn(
                DbKind::Postgres,
                "postgres://ov:secret@127.0.0.1:5432/onpass"
            ),
            "postgres://ov:secret@127.0.0.1:5432/onpass"
        );
        assert_eq!(
            normalize_dsn(
                DbKind::Postgres,
                "postgresql://ov:secret@127.0.0.1:5432/onpass"
            ),
            "postgresql://ov:secret@127.0.0.1:5432/onpass"
        );
        assert_eq!(
            normalize_dsn(DbKind::Postgres, "127.0.0.1:5432/onpass"),
            "postgres://127.0.0.1:5432/onpass"
        );
    }

    #[test]
    fn pg_placeholders_are_numbered() {
        assert_eq!(to_pg_placeholders("SELECT 1"), "SELECT 1");
        assert_eq!(
            to_pg_placeholders("SELECT * FROM t WHERE a = ?"),
            "SELECT * FROM t WHERE a = $1"
        );
        assert_eq!(
            to_pg_placeholders("INSERT INTO t (a, b) VALUES (?, ?)"),
            "INSERT INTO t (a, b) VALUES ($1, $2)"
        );
        // placeholders inside string literals must be untouched
        assert_eq!(
            to_pg_placeholders("SELECT * FROM t WHERE note = 'what?' AND a = ?"),
            "SELECT * FROM t WHERE note = 'what?' AND a = $1"
        );
        // escaped quote pair toggles back out of the string
        assert_eq!(
            to_pg_placeholders("SELECT * FROM t WHERE note = 'it''s ok?' AND a = ?"),
            "SELECT * FROM t WHERE note = 'it''s ok?' AND a = $1"
        );
    }

    #[test]
    fn pg_cached_is_stable_per_statement() {
        let sql = "SELECT * FROM t WHERE a = ? AND b = ?";
        let first = pg_cached(sql);
        let second = pg_cached(sql);
        assert!(std::ptr::eq(first, second));
        assert_eq!(first, "SELECT * FROM t WHERE a = $1 AND b = $2");
        // a different statement gets its own cache entry
        let other = pg_cached("SELECT * FROM u WHERE c = ?");
        assert_eq!(other, "SELECT * FROM u WHERE c = $1");
    }
}
