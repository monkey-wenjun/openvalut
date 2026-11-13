//! KDBX vault abstraction built on the `keepass` crate.
//!
//! This module exposes a language-agnostic view of a KeePass database,
//! hiding the underlying `keepass::Database` API. It supports KDBX 3.x and 4.x
//! open/save/create, standard and custom string fields, and basic group
//! management.

use keepass::config::DatabaseVersion;
use keepass::db::{fields, EntryId, EntryMut, EntryRef, GroupId, GroupRef};
use keepass::DatabaseKey;
use std::io::Cursor;

use crate::error::{Error, Result};

pub use keepass::Database;

pub const FIELD_TITLE: &str = fields::TITLE;
pub const FIELD_USERNAME: &str = fields::USERNAME;
pub const FIELD_PASSWORD: &str = fields::PASSWORD;
pub const FIELD_URL: &str = fields::URL;
pub const FIELD_NOTES: &str = fields::NOTES;
pub const FIELD_OTP: &str = "OTPAuth";
pub const FIELD_SSH_PRIVATE_KEY: &str = "ssh-private-key";
pub const FIELD_MACHINE_ID: &str = "machine-id";
/// Marks an entry as readable by `openvalut-cli list/get` and the local
/// credential server. Exactly `"1"` allows reading; a missing field (or any
/// other value) denies it. Kept in sync with `openvalut-cli::kdbx`.
pub const FIELD_READ_ALLOWED: &str = "openvalut.read-allowed";
pub const COMPUTER_GROUP_NAME: &str = "计算机";
pub const TRASH_GROUP_NAME: &str = "Trash";

/// A key used to unlock or save a vault.
#[derive(Debug, Clone)]
pub struct VaultKey {
    password: Option<String>,
    keyfile: Option<Vec<u8>>,
    transformed_key: Option<[u8; 32]>,
}

impl VaultKey {
    /// Key from a password only.
    pub fn with_password(password: impl Into<String>) -> Self {
        Self {
            password: Some(password.into()),
            keyfile: None,
            transformed_key: None,
        }
    }

    /// Key from a password and optional keyfile bytes.
    pub fn with_password_and_keyfile(password: impl Into<String>, keyfile: Vec<u8>) -> Self {
        Self {
            password: Some(password.into()),
            keyfile: Some(keyfile),
            transformed_key: None,
        }
    }

    /// Key from a pre-computed transformed key (as served by the desktop app
    /// bridge), so a native messaging host can reopen the vault without the
    /// master password. The key must already be transformed with the KDF
    /// parameters stored in the vault header.
    ///
    /// Such a vault is read-only: keepass builds the save key from the
    /// password/keyfile components, so saving with this key alone fails with
    /// "The key contains no components". Callers that need to write must keep
    /// the master password.
    pub fn with_transformed_key(transformed_key: [u8; 32]) -> Self {
        Self {
            password: None,
            keyfile: None,
            transformed_key: Some(transformed_key),
        }
    }

    fn to_keepass_key(&self) -> Result<DatabaseKey> {
        let mut key = DatabaseKey::new();
        if let Some(tk) = &self.transformed_key {
            key = key.with_transformed_key(*tk);
            return Ok(key);
        }
        if let Some(password) = &self.password {
            key = key.with_password(password);
        }
        if let Some(keyfile) = &self.keyfile {
            key = key
                .with_keyfile(&mut Cursor::new(keyfile))
                .map_err(|e| Error::Kdbx(format!("invalid keyfile: {e}")))?;
        }
        Ok(key)
    }
}

/// An opened KDBX vault.
#[derive(Debug, Clone)]
pub struct Vault {
    db: Database,
}

impl Vault {
    /// Open a vault from encrypted bytes.
    pub fn open(bytes: &[u8], key: &VaultKey) -> Result<Self> {
        let k = key.to_keepass_key()?;
        let mut cursor = Cursor::new(bytes);
        let db = Database::open(&mut cursor, k).map_err(|e| Error::Kdbx(e.to_string()))?;
        Ok(Self { db })
    }

    /// Create a new empty vault.
    pub fn create_new(name: impl Into<String>) -> Result<Self> {
        let mut db = Database::new();
        db.config.version = DatabaseVersion::KDB4(1);
        let name = name.into();
        db.meta.database_name = Some(name.clone());
        db.root_mut().name = name;
        Ok(Self { db })
    }

    /// Serialize the vault back to KDBX 4.1 bytes.
    pub fn save(&self, key: &VaultKey) -> Result<Vec<u8>> {
        let k = key.to_keepass_key()?;
        let mut out = Vec::new();
        let mut db = self.db.clone();
        db.config.version = DatabaseVersion::KDB4(1);
        db.save(&mut out, k)
            .map_err(|e| Error::Kdbx(format!("unable to save database: {e}")))?;
        Ok(out)
    }

    /// Serialize using the same credentials that opened the vault.
    ///
    /// This is a convenience for callers that already hold the key.
    pub fn save_with_key(&self, key: &VaultKey) -> Result<Vec<u8>> {
        self.save(key)
    }

    /// Serialize the vault and return the transformed key matching the new
    /// bytes. Each save rotates the KDF seed, so the returned key is the only
    /// one that can reopen the returned bytes without the master password.
    pub fn save_with_transformed_key(&self, key: &VaultKey) -> Result<(Vec<u8>, Option<[u8; 32]>)> {
        let k = key.to_keepass_key()?;
        let mut out = Vec::new();
        let mut db = self.db.clone();
        db.config.version = DatabaseVersion::KDB4(1);
        let tk = db
            .save_with_transformed_key(&mut out, k)
            .map_err(|e| Error::Kdbx(format!("unable to save database: {e}")))?;
        Ok((out, tk))
    }

    /// Database name from metadata.
    pub fn name(&self) -> Option<&str> {
        self.db.meta.database_name.as_deref()
    }

    /// The KDF-transformed key this vault was opened with (32 bytes), used
    /// by the native messaging host to reopen the vault without the master
    /// password. `None` for freshly created (never re-opened) vaults.
    pub fn transformed_key(&self) -> Option<[u8; 32]> {
        self.db.transformed_key
    }

    /// Wrap an already-built [Database] (e.g. reconstructed from cloud rows).
    pub fn from_database(db: Database) -> Self {
        Self { db }
    }

    /// Read-only access to the wrapped keepass database.
    pub fn database(&self) -> &Database {
        &self.db
    }

    /// Set the database name.
    pub fn set_name(&mut self, name: impl Into<String>) {
        let name = name.into();
        self.db.meta.database_name = Some(name.clone());
        self.db.root_mut().name = name;
    }

    /// List all entries recursively, excluding entries inside the recycle bin.
    pub fn entries(&self) -> Vec<Entry> {
        let mut out = Vec::new();
        let recycle_bin_uuid = self.recycle_bin_id().map(|id| id.uuid());
        collect_entries(&self.db.root(), recycle_bin_uuid, &[], &mut out);
        dedupe_by_uuid(&mut out);
        out
    }

    /// Find an entry by title or username (case-insensitive substring).
    pub fn find_entry(&self, query: &str) -> Option<Entry> {
        let query = query.trim().to_lowercase();
        if query.is_empty() {
            return self.entries().into_iter().next();
        }
        let entries = self.entries();
        entries
            .iter()
            .find(|e| e.title.to_lowercase() == query || e.username.to_lowercase() == query)
            .cloned()
            .or_else(|| {
                entries.into_iter().find(|e| {
                    e.title.to_lowercase().contains(&query)
                        || e.username.to_lowercase().contains(&query)
                })
            })
    }

    /// Find the entry for the current machine in the dedicated computer group.
    pub fn find_computer_entry(&self, machine_id: &str) -> Option<Entry> {
        self.entries().into_iter().find(|e| {
            e.group == COMPUTER_GROUP_NAME
                && self.entry_value(&e.uuid, FIELD_MACHINE_ID).as_deref() == Some(machine_id)
        })
    }

    /// Get a single field value for an entry by UUID.
    pub fn entry_value(&self, uuid: &str, key: &str) -> Option<String> {
        let id = parse_uuid(uuid)?;
        self.db
            .entry(id)
            .and_then(|e| e.get(key).map(|v| v.to_string()))
    }

    /// Add a new entry, creating parent groups as needed.
    pub fn add_entry(&mut self, request: &CreateEntryRequest) -> Result<String> {
        let group_id = self.resolve_or_create_group(request.group.as_deref())?;
        let mut group = self
            .db
            .group_mut(group_id)
            .ok_or_else(|| Error::GroupNotFound)?;
        let mut entry = group.add_entry();
        apply_changes(&mut entry, request)?;
        Ok(format!("{}", entry.id()))
    }

    /// Update an existing entry by UUID.
    pub fn update_entry(&mut self, uuid: &str, request: &UpdateEntryRequest) -> Result<()> {
        let id = parse_uuid(uuid).ok_or_else(|| Error::InvalidArgument("invalid uuid".into()))?;
        {
            let mut entry = self.db.entry_mut(id).ok_or_else(|| Error::EntryNotFound)?;
            apply_update_changes(&mut entry, request)?;
        }
        if let Some(group_name) = &request.group {
            let target = self.resolve_or_create_group(Some(group_name))?;
            let mut entry = self.db.entry_mut(id).ok_or_else(|| Error::EntryNotFound)?;
            entry.move_to(target).map_err(|_| Error::GroupNotFound)?;
        }
        Ok(())
    }

    /// Delete an entry by UUID.
    pub fn delete_entry(&mut self, uuid: &str) -> Result<()> {
        let id = parse_uuid(uuid).ok_or_else(|| Error::InvalidArgument("invalid uuid".into()))?;
        let entry = self.db.entry_mut(id).ok_or_else(|| Error::EntryNotFound)?;
        entry.remove();
        Ok(())
    }

    /// Append or overwrite custom string fields on an entry, honoring a
    /// per-field protected flag. Used by the desktop bridge, whose clients
    /// (e.g. passkey registration) mark secret values as protected.
    pub fn set_entry_custom_fields(
        &mut self,
        uuid: &str,
        fields: &[(String, String, bool)],
    ) -> Result<()> {
        let id = parse_uuid(uuid).ok_or_else(|| Error::InvalidArgument("invalid uuid".into()))?;
        let mut entry = self.db.entry_mut(id).ok_or_else(|| Error::EntryNotFound)?;
        for (key, value, protected) in fields {
            if *protected {
                entry.set_protected(key, value);
            } else {
                entry.set_unprotected(key, value);
            }
        }
        Ok(())
    }

    /// Whether an entry is currently marked as readable by the CLI/credential
    /// server (the `openvalut.read-allowed` field equals `"1"`).
    pub fn entry_read_allowed(&self, uuid: &str) -> bool {
        self.entry_value(uuid, FIELD_READ_ALLOWED).as_deref() == Some("1")
    }

    /// Toggle CLI/script read access for an entry. Setting `allowed` writes
    /// `openvalut.read-allowed = "1"`; clearing it removes the field entirely,
    /// matching the deny-by-default convention used by `openvalut-cli`.
    pub fn set_entry_read_allowed(&mut self, uuid: &str, allowed: bool) -> Result<()> {
        let id = parse_uuid(uuid).ok_or_else(|| Error::InvalidArgument("invalid uuid".into()))?;
        let mut entry = self.db.entry_mut(id).ok_or_else(|| Error::EntryNotFound)?;
        if allowed {
            entry.set_unprotected(FIELD_READ_ALLOWED, "1");
        } else {
            entry.fields.remove(FIELD_READ_ALLOWED);
        }
        Ok(())
    }

    /// Recycle-bin UUID, if one is configured.
    pub fn recycle_bin_uuid(&self) -> Option<String> {
        self.recycle_bin_id().map(|id| format!("{}", id))
    }

    /// The recycle bin: the group recorded in the header, or one adopted by name
    /// (see [`Vault::name_adopted_bin`]).
    fn recycle_bin_id(&self) -> Option<GroupId> {
        self.db
            .recycle_bin()
            .map(|g| g.id())
            .or_else(|| self.name_adopted_bin())
    }

    /// A top-level group carrying the recycle bin's name while the file's
    /// `RecycleBinUUID` meta stays empty. The old Flutter build moved deleted
    /// items into exactly such a group; read literally, the bin shows up as an
    /// ordinary sidebar group *and* every deleted entry reappears in the list as
    /// a live duplicate of itself.
    fn name_adopted_bin(&self) -> Option<GroupId> {
        let name = TRASH_GROUP_NAME.to_lowercase();
        self.db
            .root()
            .groups()
            .find(|g| g.name.to_lowercase() == name)
            .map(|g| g.id())
    }

    /// Move an entry to the recycle bin, creating and wiring the bin group on
    /// first use. Trashed entries disappear from [`Vault::entries`] and are
    /// listed by [`Vault::trashed_entries`] until restored or deleted.
    pub fn trash_entry(&mut self, uuid: &str) -> Result<()> {
        let id = parse_uuid(uuid).ok_or_else(|| Error::InvalidArgument("invalid uuid".into()))?;
        let trash_id = self.ensure_recycle_bin()?;
        let mut entry = self.db.entry_mut(id).ok_or_else(|| Error::EntryNotFound)?;
        entry.move_to(trash_id).map_err(|_| Error::GroupNotFound)?;
        Ok(())
    }

    /// Restore an entry from the recycle bin back to the vault root.
    pub fn restore_entry(&mut self, uuid: &str) -> Result<()> {
        let id = parse_uuid(uuid).ok_or_else(|| Error::InvalidArgument("invalid uuid".into()))?;
        let root = self.db.root().id();
        let mut entry = self.db.entry_mut(id).ok_or_else(|| Error::EntryNotFound)?;
        entry.move_to(root).map_err(|_| Error::GroupNotFound)?;
        Ok(())
    }

    /// Entries currently inside the recycle bin.
    pub fn trashed_entries(&self) -> Vec<Entry> {
        let mut out = Vec::new();
        if let Some(id) = self.recycle_bin_id() {
            if let Some(bin) = self.db.group(id) {
                collect_all_entries(&bin, &mut out);
            }
        }
        dedupe_by_uuid(&mut out);
        out
    }

    /// The recycle bin group, created and registered in the header on first use.
    fn ensure_recycle_bin(&mut self) -> Result<GroupId> {
        if let Some(bin) = self.db.recycle_bin() {
            return Ok(bin.id());
        }
        // Adopt the Flutter-era group rather than creating a second bin beside it.
        let id = match self.name_adopted_bin() {
            Some(id) => id,
            None => self.resolve_or_create_group(Some(TRASH_GROUP_NAME))?,
        };
        if let Some(g) = self.db.group(id) {
            self.db.meta.recyclebin_uuid = Some(g.id().uuid());
        }
        Ok(id)
    }

    /// Every group in the vault except the root and the recycle bin, in
    /// depth-first order. Empty groups are included: the sidebar has to show the
    /// tree as the file holds it, including groups that 自动整理 created but
    /// never filled.
    pub fn groups(&self) -> Vec<Group> {
        let mut out = Vec::new();
        let recycle_bin_uuid = self.recycle_bin_id().map(|id| id.uuid());
        collect_groups(&self.db.root(), recycle_bin_uuid, &[], &mut out);
        dedupe_groups(&mut out);
        out
    }

    /// Create a group (and any missing parents) from a `/`-separated path and
    /// return its UUID.
    pub fn create_group(&mut self, path: &str) -> Result<String> {
        let parts: Vec<&str> = path
            .split('/')
            .map(|p| p.trim())
            .filter(|p| !p.is_empty())
            .collect();
        if parts.is_empty() {
            return Err(Error::InvalidArgument("group name is required".into()));
        }
        let id = self.resolve_or_create_group(Some(&parts.join("/")))?;
        Ok(format!("{}", id))
    }

    /// Rename a group. Contained entries follow automatically, because entry
    /// paths are rebuilt from group names on every read.
    pub fn rename_group(&mut self, uuid: &str, new_name: &str) -> Result<()> {
        let name = new_name.trim();
        if name.is_empty() || name.contains('/') {
            return Err(Error::InvalidArgument("invalid group name".into()));
        }
        let id = self.resolve_group(uuid)?;
        let mut group = self.db.group_mut(id).ok_or(Error::GroupNotFound)?;
        group.name = name.to_string();
        Ok(())
    }

    /// Move a group — with everything inside it — to the recycle bin, so the
    /// branch can be restored rather than having been erased.
    pub fn trash_group(&mut self, uuid: &str) -> Result<()> {
        let id = self.resolve_group(uuid)?;
        if self.recycle_bin_id() == Some(id) {
            return Err(Error::InvalidArgument("回收站本身不能移入回收站".into()));
        }
        let bin = self.ensure_recycle_bin()?;
        let mut group = self.db.group_mut(id).ok_or(Error::GroupNotFound)?;
        group.move_to(bin).map_err(|_| Error::GroupNotFound)?;
        Ok(())
    }

    /// Move every entry sharing a title and username into the recycle bin except
    /// the most recently modified one — what an earlier version of the app left
    /// behind as visible duplicates. Case-insensitive, matching the audit report's
    /// identity rule. Returns how many entries were moved.
    pub fn trash_duplicate_entries(&mut self, title: &str, username: &str) -> Result<usize> {
        let want = (title.to_lowercase(), username.to_lowercase());
        let victims: Vec<String> = {
            let entries = self.entries();
            let mut group: Vec<&Entry> = entries
                .iter()
                .filter(|e| (e.title.to_lowercase(), e.username.to_lowercase()) == want)
                .collect();
            if group.len() < 2 {
                return Ok(0);
            }
            // Last-modified strings are "YYYY-MM-DD HH:MM:SS", so they order
            // correctly as text; an entry without a timestamp loses to one with.
            group.sort_by(|a, b| b.updated_at.cmp(&a.updated_at));
            group.iter().skip(1).map(|e| e.uuid.clone()).collect()
        };
        for uuid in &victims {
            self.trash_entry(uuid)?;
        }
        Ok(victims.len())
    }

    /// Apply the CLI/script read mark to every entry in a group and its
    /// subgroups. Returns how many entries were touched.
    pub fn set_group_read_allowed(&mut self, uuid: &str, allowed: bool) -> Result<usize> {
        let id = self.resolve_group(uuid)?;
        let mut uuids = Vec::new();
        {
            let group = self.db.group(id).ok_or(Error::GroupNotFound)?;
            collect_entry_uuids(&group, &mut uuids);
        }
        for entry_uuid in &uuids {
            self.set_entry_read_allowed(entry_uuid, allowed)?;
        }
        Ok(uuids.len())
    }

    fn resolve_group(&self, uuid: &str) -> Result<GroupId> {
        let id = uuid::Uuid::parse_str(uuid.trim())
            .map(GroupId::from)
            .map_err(|_| Error::InvalidArgument("invalid group uuid".into()))?;
        if self.db.group(id).is_none() {
            return Err(Error::GroupNotFound);
        }
        Ok(id)
    }

    fn resolve_or_create_group(&mut self, group_name: Option<&str>) -> Result<GroupId> {
        let name = group_name.unwrap_or("");
        if name.is_empty() {
            return Ok(self.db.root().id());
        }
        let path: Vec<&str> = name.split('/').filter(|p| !p.is_empty()).collect();
        if let Some(group) = self.db.root().group_by_path(&path) {
            return Ok(group.id());
        }
        let mut current_id = self.db.root().id();
        for part in &path {
            let next_id = self
                .db
                .group(current_id)
                .and_then(|g| g.group_by_name(part).map(|child| child.id()));
            current_id = if let Some(id) = next_id {
                id
            } else {
                let mut parent = self
                    .db
                    .group_mut(current_id)
                    .ok_or_else(|| Error::GroupNotFound)?;
                let mut child = parent.add_group();
                child.name = (*part).to_string();
                child.id()
            };
        }
        Ok(current_id)
    }
}

fn collect_entries(
    group: &GroupRef<'_>,
    recycle_bin_uuid: Option<uuid::Uuid>,
    path: &[String],
    out: &mut Vec<Entry>,
) {
    if recycle_bin_uuid == Some(group.id().uuid()) {
        return;
    }
    for entry in group.entries() {
        out.push(Entry::from_keepass(entry, path));
    }
    let mut child_path = path.to_vec();
    for child in group.groups() {
        child_path.push(child.name.clone());
        collect_entries(&child, recycle_bin_uuid, &child_path, out);
        child_path.pop();
    }
}

fn collect_all_entries(group: &GroupRef<'_>, out: &mut Vec<Entry>) {
    for entry in group.entries() {
        out.push(Entry::from_keepass(entry, &[]));
    }
    for child in group.groups() {
        collect_all_entries(&child, out);
    }
}

fn collect_groups(
    group: &GroupRef<'_>,
    recycle_bin_uuid: Option<uuid::Uuid>,
    path: &[String],
    out: &mut Vec<Group>,
) {
    for child in group.groups() {
        if recycle_bin_uuid == Some(child.id().uuid()) {
            continue;
        }
        let mut child_path = path.to_vec();
        child_path.push(child.name.clone());
        out.push(Group {
            uuid: format!("{}", child.id()),
            name: child.name.clone(),
            path: child_path.join("/"),
            entry_count: child.entries().count(),
        });
        collect_groups(&child, recycle_bin_uuid, &child_path, out);
    }
}

fn collect_entry_uuids(group: &GroupRef<'_>, out: &mut Vec<String>) {
    for entry in group.entries() {
        out.push(format!("{}", entry.id()));
    }
    for child in group.groups() {
        collect_entry_uuids(&child, out);
    }
}

/// A group that is listed in two parents' child sets gets walked twice, and the
/// entries below it would then show up twice in every listing. Keep the first
/// sighting of each UUID.
fn dedupe_by_uuid(entries: &mut Vec<Entry>) {
    let mut seen = std::collections::HashSet::new();
    entries.retain(|e| seen.insert(e.uuid.clone()));
}

fn dedupe_groups(groups: &mut Vec<Group>) {
    let mut seen = std::collections::HashSet::new();
    groups.retain(|g| seen.insert(g.uuid.clone()));
}

fn parse_uuid(s: &str) -> Option<EntryId> {
    uuid::Uuid::parse_str(s).ok().map(EntryId::from)
}

/// A vault group exposed to callers. `path` uses the same `/`-separated form as
/// [`Entry::group`], so the two can be compared directly.
#[derive(Debug, Clone)]
pub struct Group {
    pub uuid: String,
    pub name: String,
    pub path: String,
    /// Entries stored directly in this group; subgroups are not counted.
    pub entry_count: usize,
}

/// A vault entry exposed to callers.
#[derive(Debug, Clone, Default)]
pub struct Entry {
    pub uuid: String,
    pub title: String,
    pub username: String,
    pub password: String,
    pub url: String,
    pub notes: String,
    pub group: String,
    pub custom: Vec<(String, String)>,
    /// Last-modified time as `YYYY-MM-DD HH:MM:SS`, when recorded in the file.
    pub updated_at: Option<String>,
}

impl Entry {
    fn from_keepass(entry: EntryRef<'_>, path: &[String]) -> Self {
        let custom: Vec<(String, String)> = entry
            .fields
            .iter()
            .filter_map(|(k, v)| {
                let key = k.to_string();
                if is_standard_field(&key) {
                    None
                } else {
                    // `v.to_string()` redacts protected values to
                    // "[redacted]"; the host needs the real value (passkeys,
                    // custom URLs), so read through `get()` which exposes it.
                    Some((key, v.get().to_string()))
                }
            })
            .collect();

        Self {
            uuid: format!("{}", entry.id()),
            title: entry.get(fields::TITLE).unwrap_or_default().to_string(),
            username: entry.get(fields::USERNAME).unwrap_or_default().to_string(),
            password: entry.get(fields::PASSWORD).unwrap_or_default().to_string(),
            url: entry.get(fields::URL).unwrap_or_default().to_string(),
            notes: entry.get(fields::NOTES).unwrap_or_default().to_string(),
            group: path.join("/"),
            custom,
            updated_at: entry.times.last_modification.map(|t| t.to_string()),
        }
    }
}

fn is_standard_field(key: &str) -> bool {
    matches!(
        key,
        fields::TITLE | fields::USERNAME | fields::PASSWORD | fields::URL | fields::NOTES
    )
}

/// Request to create a new entry.
#[derive(Debug, Clone, Default)]
pub struct CreateEntryRequest {
    pub title: String,
    pub username: String,
    pub password: String,
    pub url: String,
    pub notes: String,
    pub otp: Option<String>,
    pub ssh_private_key: Option<String>,
    pub machine_id: Option<String>,
    pub group: Option<String>,
    pub custom: Vec<(String, String)>,
}

/// Request to update an existing entry.
#[derive(Debug, Clone, Default)]
pub struct UpdateEntryRequest {
    pub title: Option<String>,
    pub username: Option<String>,
    pub password: Option<String>,
    pub url: Option<String>,
    pub notes: Option<String>,
    pub otp: Option<String>,
    pub ssh_private_key: Option<String>,
    pub machine_id: Option<String>,
    pub group: Option<String>,
    pub custom: Vec<(String, String)>,
    /// Custom-field keys to delete. `custom` only ever adds or overwrites, so
    /// without this a removed field would come back on the next save.
    pub remove_custom: Vec<String>,
}

fn apply_changes(entry: &mut EntryMut<'_>, request: &CreateEntryRequest) -> Result<()> {
    entry.set_unprotected(fields::TITLE, &request.title);
    entry.set_unprotected(fields::USERNAME, &request.username);
    entry.set_protected(fields::PASSWORD, &request.password);
    entry.set_unprotected(fields::URL, &request.url);
    entry.set_unprotected(fields::NOTES, &request.notes);
    if let Some(otp) = &request.otp {
        entry.set_protected(FIELD_OTP, otp);
    }
    if let Some(pem) = &request.ssh_private_key {
        entry.set_protected(FIELD_SSH_PRIVATE_KEY, pem);
    }
    if let Some(machine_id) = &request.machine_id {
        entry.set_unprotected(FIELD_MACHINE_ID, machine_id);
    }
    for (k, v) in &request.custom {
        entry.set_unprotected(k, v);
    }
    Ok(())
}

fn apply_update_changes(entry: &mut EntryMut<'_>, request: &UpdateEntryRequest) -> Result<()> {
    if let Some(title) = &request.title {
        entry.set_unprotected(fields::TITLE, title);
    }
    if let Some(username) = &request.username {
        entry.set_unprotected(fields::USERNAME, username);
    }
    if let Some(password) = &request.password {
        entry.set_protected(fields::PASSWORD, password);
    }
    if let Some(url) = &request.url {
        entry.set_unprotected(fields::URL, url);
    }
    if let Some(notes) = &request.notes {
        entry.set_unprotected(fields::NOTES, notes);
    }
    if let Some(otp) = &request.otp {
        entry.set_protected(FIELD_OTP, otp);
    }
    if let Some(pem) = &request.ssh_private_key {
        entry.set_protected(FIELD_SSH_PRIVATE_KEY, pem);
    }
    if let Some(machine_id) = &request.machine_id {
        entry.set_unprotected(FIELD_MACHINE_ID, machine_id);
    }
    for (k, v) in &request.custom {
        entry.set_unprotected(k, v);
    }
    for k in &request.remove_custom {
        entry.fields.remove(k.as_str());
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn create_load_save_round_trip() {
        let key = VaultKey::with_password("pw");
        let vault = Vault::create_new("Test").unwrap();
        let bytes = vault.save(&key).unwrap();
        let loaded = Vault::open(&bytes, &key).unwrap();
        assert_eq!(loaded.name(), Some("Test"));
        assert!(loaded.entries().is_empty());
    }

    #[test]
    fn save_with_transformed_key_reopens() {
        let key = VaultKey::with_password("pw");
        let mut vault = Vault::create_new("Test").unwrap();
        vault
            .add_entry(&CreateEntryRequest {
                title: "GitHub".into(),
                ..Default::default()
            })
            .unwrap();

        let (bytes, tk) = vault.save_with_transformed_key(&key).unwrap();
        let tk = tk.expect("save returns a transformed key");

        // The bytes reopen with the transformed key alone (no master password).
        let loaded = Vault::open(&bytes, &VaultKey::with_transformed_key(tk)).unwrap();
        assert_eq!(loaded.entries().len(), 1);

        // And the transformed key stays in sync across further saves.
        let (bytes2, tk2) = loaded.save_with_transformed_key(&key).unwrap();
        let tk2 = tk2.unwrap();
        assert_ne!(tk, tk2, "KDF seed rotation must change the transformed key");
        assert!(Vault::open(&bytes2, &VaultKey::with_transformed_key(tk2)).is_ok());
        assert!(
            Vault::open(&bytes2, &VaultKey::with_transformed_key(tk)).is_err(),
            "stale transformed key must be rejected"
        );
    }

    #[test]
    fn transformed_key_only_vault_cannot_save() {
        // Unlocking with a transformed key alone works, but the resulting vault
        // is read-only: keepass has no password/keyfile component left to build
        // a save key from. This is why remembered unlock keeps the master
        // password rather than the transformed key.
        let key = VaultKey::with_password("pw");
        let vault = Vault::create_new("Test").unwrap();
        let (bytes, tk) = vault.save_with_transformed_key(&key).unwrap();
        let opened = Vault::open(&bytes, &VaultKey::with_transformed_key(tk.unwrap())).unwrap();

        let remembered = VaultKey::with_transformed_key(opened.transformed_key().unwrap());
        let err = opened.save(&remembered).unwrap_err().to_string();
        assert!(err.contains("no components"), "unexpected error: {err}");
    }

    #[test]
    fn wrong_password_rejected() {
        let key = VaultKey::with_password("pw");
        let vault = Vault::create_new("Test").unwrap();
        let bytes = vault.save(&key).unwrap();
        let wrong_key = VaultKey::with_password("wrong");
        assert!(Vault::open(&bytes, &wrong_key).is_err());
    }

    #[test]
    fn add_edit_delete_entry() {
        let key = VaultKey::with_password("pw");
        let mut vault = Vault::create_new("Test").unwrap();

        let uuid = vault
            .add_entry(&CreateEntryRequest {
                title: "GitHub".into(),
                username: "alice".into(),
                password: "s3cret".into(),
                url: "https://github.com".into(),
                otp: Some("otpauth://totp/GitHub?secret=JBSWY3DPEHPK3PXP".into()),
                group: Some("Work".into()),
                ..Default::default()
            })
            .unwrap();

        let saved = vault.save(&key).unwrap();
        let mut vault = Vault::open(&saved, &key).unwrap();
        let entry = vault.find_entry("github").unwrap();
        assert_eq!(entry.title, "GitHub");
        assert_eq!(entry.username, "alice");
        assert_eq!(entry.group, "Work");
        assert!(entry.custom.iter().any(|(k, _)| k == FIELD_OTP));

        vault
            .update_entry(
                &uuid,
                &UpdateEntryRequest {
                    password: Some("newpass".into()),
                    ..Default::default()
                },
            )
            .unwrap();

        let saved = vault.save(&key).unwrap();
        let vault = Vault::open(&saved, &key).unwrap();
        assert_eq!(
            vault.entry_value(&uuid, FIELD_PASSWORD).as_deref(),
            Some("newpass")
        );

        let mut vault = Vault::open(&saved, &key).unwrap();
        vault.delete_entry(&uuid).unwrap();
        assert!(vault.entries().is_empty());
    }

    #[test]
    fn cli_read_allowed_toggle_round_trip() {
        let key = VaultKey::with_password("pw");
        let mut vault = Vault::create_new("Test").unwrap();
        let uuid = vault
            .add_entry(&CreateEntryRequest {
                title: "API".into(),
                ..Default::default()
            })
            .unwrap();

        // deny-by-default: a fresh entry is not readable.
        assert!(!vault.entry_read_allowed(&uuid));

        vault.set_entry_read_allowed(&uuid, true).unwrap();
        assert!(vault.entry_read_allowed(&uuid));
        let saved = vault.save(&key).unwrap();
        let mut vault = Vault::open(&saved, &key).unwrap();
        assert!(vault.entry_read_allowed(&uuid));

        // clearing removes the field, so the entry is denied again.
        vault.set_entry_read_allowed(&uuid, false).unwrap();
        assert!(!vault.entry_read_allowed(&uuid));
        assert_eq!(vault.entry_value(&uuid, FIELD_READ_ALLOWED), None);
    }

    #[test]
    fn entries_excludes_recycle_bin() {
        let _key = VaultKey::with_password("pw");
        let mut vault = Vault::create_new("Test").unwrap();

        // Create a normal entry and a "trash" group with an entry inside it.
        let normal_uuid = vault
            .add_entry(&CreateEntryRequest {
                title: "Keep".into(),
                username: "alice".into(),
                group: Some("Work".into()),
                ..Default::default()
            })
            .unwrap();

        let trash_uuid = vault
            .add_entry(&CreateEntryRequest {
                title: "Trashed".into(),
                username: "bob".into(),
                group: Some("Recycle Bin".into()),
                ..Default::default()
            })
            .unwrap();

        // Mark the Recycle Bin group as the recycle bin.
        let recycle_bin_id = vault
            .db
            .root()
            .group_by_path(&["Recycle Bin"])
            .map(|g| g.id().uuid());
        vault.db.meta.recyclebin_uuid = recycle_bin_id;

        // Normal listing hides the recycled entry but keeps the normal one.
        assert_eq!(vault.entries().len(), 1);
        assert!(vault.entries().iter().any(|e| e.uuid == normal_uuid));
        assert!(!vault.entries().iter().any(|e| e.uuid == trash_uuid));

        // Direct lookup by UUID still works (the entry is only hidden from listings).
        assert_eq!(
            vault.entry_value(&trash_uuid, FIELD_TITLE).as_deref(),
            Some("Trashed")
        );

        // find_entry also respects the recycle-bin filter.
        assert!(vault.find_entry("Trashed").is_none());
        assert!(vault.find_entry("Keep").is_some());
    }

    /// A vault written by the old Flutter build has a top-level "Trash" group but
    /// no `RecycleBinUUID` in the header. Read literally, that shows the bin as an
    /// ordinary sidebar group *and* every deleted entry again as a live duplicate,
    /// so the name has to be adopted as the bin.
    #[test]
    fn trash_group_without_meta_is_adopted_as_recycle_bin() {
        let _key = VaultKey::with_password("pw");
        let mut vault = Vault::create_new("Test").unwrap();
        let live = vault
            .add_entry(&CreateEntryRequest {
                title: "华泰证券".into(),
                username: "alice".into(),
                ..Default::default()
            })
            .unwrap();
        let gone = vault
            .add_entry(&CreateEntryRequest {
                title: "华泰证券".into(),
                username: "alice".into(),
                group: Some(TRASH_GROUP_NAME.into()),
                ..Default::default()
            })
            .unwrap();
        assert!(vault.db.meta.recyclebin_uuid.is_none());

        assert_eq!(vault.entries().len(), 1);
        assert!(vault.entries().iter().any(|e| e.uuid == live));
        assert_eq!(vault.trashed_entries().len(), 1);
        assert_eq!(vault.trashed_entries()[0].uuid, gone);
        assert!(!vault.groups().iter().any(|g| g.name == TRASH_GROUP_NAME));
        // The adopted bin is still in the tree, so a caller that knows its UUID
        // could try to move it into itself.
        let trash_uuid = vault
            .db
            .root()
            .group_by_path(&[TRASH_GROUP_NAME])
            .map(|g| format!("{}", g.id().uuid()))
            .unwrap();
        assert!(vault.trash_group(&trash_uuid).is_err());

        // Using the bin records it, so a later open does not have to guess again.
        vault.trash_entry(&live).unwrap();
        assert!(vault.db.meta.recyclebin_uuid.is_some());
        assert_eq!(vault.trashed_entries().len(), 2);
    }

    #[test]
    fn trash_duplicate_entries_keeps_one_behind() {
        let mut vault = Vault::create_new("Test").unwrap();
        for password in ["a", "b", "c"] {
            vault
                .add_entry(&CreateEntryRequest {
                    title: "华泰证券".into(),
                    username: "88001234".into(),
                    password: password.into(),
                    ..Default::default()
                })
                .unwrap();
        }
        vault
            .add_entry(&CreateEntryRequest {
                title: "华泰证券".into(),
                username: "99005678".into(),
                ..Default::default()
            })
            .unwrap();

        assert_eq!(
            vault
                .trash_duplicate_entries("华泰证券", "88001234")
                .unwrap(),
            2
        );
        // One of the three survives, the other account is untouched, and what
        // was removed is recoverable rather than gone.
        assert_eq!(vault.entries().len(), 2);
        assert_eq!(vault.trashed_entries().len(), 2);
        // Nothing left to clean the second time.
        assert_eq!(
            vault
                .trash_duplicate_entries("华泰证券", "88001234")
                .unwrap(),
            0
        );
    }

    #[test]
    fn update_entry_can_drop_a_custom_field() {
        let mut vault = Vault::create_new("Test").unwrap();
        let uuid = vault
            .add_entry(&CreateEntryRequest {
                title: "site".into(),
                custom: vec![
                    ("serial".into(), "123".into()),
                    ("room".into(), "A101".into()),
                ],
                ..Default::default()
            })
            .unwrap();

        vault
            .update_entry(
                &uuid,
                &UpdateEntryRequest {
                    custom: vec![("room".into(), "B202".into())],
                    remove_custom: vec!["serial".into()],
                    ..Default::default()
                },
            )
            .unwrap();

        // Dropping one field must not take the rest of the custom set with it,
        // and `custom` stays add-or-overwrite so a quick "add field" from the
        // detail panel cannot wipe what is already there.
        assert_eq!(vault.entry_value(&uuid, "serial"), None);
        assert_eq!(
            vault.entry_value(&uuid, "room").as_deref(),
            Some("B202"),
            "merge semantics must overwrite an existing key"
        );
    }

    #[test]
    fn groups_lists_the_real_tree_including_empty_groups() {
        let mut vault = Vault::create_new("Test").unwrap();
        vault
            .add_entry(&CreateEntryRequest {
                title: "GitHub".into(),
                group: Some("工作/邮箱".into()),
                ..Default::default()
            })
            .unwrap();
        vault.create_group("银行卡").unwrap();

        let groups: Vec<(String, usize)> = vault
            .groups()
            .into_iter()
            .map(|g| (g.path, g.entry_count))
            .collect();
        assert_eq!(
            groups,
            vec![
                ("工作".to_string(), 0),
                ("工作/邮箱".to_string(), 1),
                ("银行卡".to_string(), 0),
            ],
            "empty groups must be listed like the file holds them"
        );
    }

    #[test]
    fn rename_group_repaths_entries_without_touching_them() {
        let mut vault = Vault::create_new("Test").unwrap();
        let uuid = vault
            .add_entry(&CreateEntryRequest {
                title: "GitHub".into(),
                group: Some("工作/邮箱".into()),
                ..Default::default()
            })
            .unwrap();
        let work = vault.groups().remove(0).uuid;

        vault.rename_group(&work, "公司").unwrap();
        assert_eq!(vault.find_entry("GitHub").unwrap().group, "公司/邮箱");
        assert_eq!(
            vault
                .groups()
                .into_iter()
                .map(|g| g.path)
                .collect::<Vec<_>>(),
            vec!["公司".to_string(), "公司/邮箱".to_string()]
        );
        assert_eq!(
            vault.entry_value(&uuid, FIELD_TITLE).as_deref(),
            Some("GitHub")
        );

        assert!(vault.rename_group(&work, "").is_err());
        assert!(vault.rename_group(&work, "a/b").is_err());
    }

    #[test]
    fn trash_group_hides_the_branch_but_keeps_the_entries() {
        let mut vault = Vault::create_new("Test").unwrap();
        vault
            .add_entry(&CreateEntryRequest {
                title: "GitHub".into(),
                group: Some("工作/邮箱".into()),
                ..Default::default()
            })
            .unwrap();
        let nested = vault.groups().remove(1).uuid;

        vault.trash_group(&nested).unwrap();
        assert!(vault.entries().is_empty());
        assert_eq!(
            vault
                .groups()
                .into_iter()
                .map(|g| g.path)
                .collect::<Vec<_>>(),
            vec!["工作".to_string()],
            "a group under the recycle bin must leave the tree"
        );
        assert_eq!(vault.trashed_entries().len(), 1);
        assert_eq!(vault.trashed_entries()[0].title, "GitHub");
    }

    #[test]
    fn set_group_read_allowed_covers_subgroups() {
        let mut vault = Vault::create_new("Test").unwrap();
        let top = vault
            .add_entry(&CreateEntryRequest {
                title: "Top".into(),
                group: Some("银行".into()),
                ..Default::default()
            })
            .unwrap();
        let child = vault
            .add_entry(&CreateEntryRequest {
                title: "Child".into(),
                group: Some("银行/储蓄".into()),
                ..Default::default()
            })
            .unwrap();
        let bank = vault.groups().remove(0).uuid;

        assert_eq!(vault.set_group_read_allowed(&bank, true).unwrap(), 2);
        assert!(vault.entry_read_allowed(&top));
        assert!(vault.entry_read_allowed(&child));

        assert_eq!(vault.set_group_read_allowed(&bank, false).unwrap(), 2);
        assert!(!vault.entry_read_allowed(&top));
        assert!(!vault.entry_read_allowed(&child));
    }
}
