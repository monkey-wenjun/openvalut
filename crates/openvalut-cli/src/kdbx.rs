//! KDBX database access via the `keepass` crate: open, query, create, edit
//! and delete entries, and serialize back to KDBX 4.1 (readable by the
//! openvalut app, which accepts any KDBX 4.x).
use keepass::config::DatabaseVersion;
use keepass::db::fields;
use keepass::db::{EntryId, EntryMut, EntryRef, GroupId, GroupRef};
use keepass::DatabaseKey;
use std::io::Cursor;

pub use keepass::Database;

pub const OTP_FIELD: &str = "OTPAuth";
/// Entry field holding the Access Key ID of an AK/SK credential (matching the app).
pub const ACCESS_KEY_FIELD: &str = "access-key";
/// Entry field holding the matching Secret Access Key (matching the app).
pub const SECRET_KEY_FIELD: &str = "secret-key";
/// Entry field holding an OpenSSH private key (PEM), matching the app.
pub const SSH_PRIVATE_KEY_FIELD: &str = "ssh-private-key";
/// Entry field holding the SSH server host name / alias (matching the app).
pub const SSH_HOST_FIELD: &str = "ssh-host";
/// Entry field holding the SSH server TCP port (matching the app).
pub const SSH_PORT_FIELD: &str = "ssh-port";
/// Hidden entry field marking that CLI / scripts may list and read this
/// entry. Default (field missing) means *deny*: only entries explicitly
/// allowed by the app (or with this field set to "1") are returned by the
/// read interfaces (`list`, socket metadata `get`, secret resolution).
pub const READ_ALLOWED_FIELD: &str = "openvalut.read-allowed";
const READ_ALLOWED_MARK: &str = "1";

#[derive(Debug, Clone)]
pub struct EntryInfo {
    pub id: EntryId,
    pub title: String,
    pub username: String,
    pub group: String,
    pub file: String,
}

#[derive(Debug, Default, Clone)]
pub struct EntryChanges {
    pub title: Option<String>,
    pub username: Option<String>,
    pub password: Option<String>,
    pub url: Option<String>,
    pub notes: Option<String>,
    pub otp: Option<String>,
    pub group: Option<String>,
    pub machine_id: Option<String>,
    pub ssh_private_key: Option<String>,
    pub access_key: Option<String>,
    pub secret_key: Option<String>,
}

/// Opens a KDBX byte buffer with the given password (and optional keyfile).
pub fn load(bytes: &[u8], password: &str, keyfile: Option<&[u8]>) -> Result<Database, String> {
    let key = make_key(password, keyfile)?;
    let mut cursor = Cursor::new(bytes);
    Database::open(&mut cursor, key).map_err(|e| format!("unable to unlock database: {e}"))
}

/// Creates a new, empty database and returns its KDBX 4.1 bytes.
pub fn create_empty(database_name: &str, password: &str) -> Result<Vec<u8>, String> {
    let mut db = Database::new();
    db.config.version = DatabaseVersion::KDB4(1);
    db.meta.database_name = Some(database_name.to_string());
    db.root_mut().name = database_name.to_string();
    save(&db, password, None)
}

/// Serializes the database back to KDBX 4.1 bytes.
pub fn save(db: &Database, password: &str, keyfile: Option<&[u8]>) -> Result<Vec<u8>, String> {
    let key = make_key(password, keyfile)?;
    let mut out = Vec::new();
    let mut db = db.clone();
    // keepass only serializes KDBX 4.1; openvalut reads any KDBX 4.x.
    db.config.version = DatabaseVersion::KDB4(1);
    db.save(&mut out, key)
        .map_err(|e| format!("unable to save database: {e}"))?;
    Ok(out)
}

fn make_key(password: &str, keyfile: Option<&[u8]>) -> Result<DatabaseKey, String> {
    let mut key = DatabaseKey::new().with_password(password);
    if let Some(bytes) = keyfile {
        key = key
            .with_keyfile(&mut Cursor::new(bytes))
            .map_err(|e| format!("unable to read keyfile: {e}"))?;
    }
    Ok(key)
}

/// All entries of the database with their group path and database name.
pub fn list_entries(db: &Database) -> Vec<EntryInfo> {
    let file = db.meta.database_name.clone().unwrap_or_default();
    let mut out = Vec::new();
    collect_entries(&db.root(), &[], &file, &mut out);
    out
}

/// Whether the entry may be listed/read by CLI and scripts. The hidden
/// `openvalut.read-allowed` field must be exactly "1"; anything else
/// (including a missing field) is denied.
pub fn entry_read_allowed(entry: &EntryRef<'_>) -> bool {
    entry.get(READ_ALLOWED_FIELD).is_some_and(|v| v == READ_ALLOWED_MARK)
}

/// Whether the entry sits inside the vault's recycle bin (mirrors the app:
/// deleted entries are never offered to read interfaces).
pub fn is_entry_in_recycle_bin(db: &Database, entry_id: &EntryId) -> bool {
    let Some(entry) = db.entry(*entry_id) else {
        return false;
    };
    is_in_recycle_bin(db, &entry)
}

fn is_in_recycle_bin(db: &Database, entry: &EntryRef<'_>) -> bool {
    let Some(recycle_uuid) = db.meta.recyclebin_uuid else {
        return false;
    };
    let mut group = db.group(entry.parent().id());
    while let Some(g) = group {
        if g.id().uuid() == recycle_uuid {
            return true;
        }
        group = g.parent().and_then(|parent| db.group(parent.id()));
    }
    false
}

/// Entries the read interfaces may expose: `list_entries` filtered to the
/// allow-list. Default is deny-all, so a vault with no allowed groups/entries
/// shows an empty list.
pub fn list_readable_entries(db: &Database) -> Vec<EntryInfo> {
    list_entries(db)
        .into_iter()
        .filter(|info| {
            db.entry(info.id)
                .is_some_and(|entry| {
                    entry_read_allowed(&entry)
                        && !is_in_recycle_bin(db, &entry)
                })
        })
        .collect()
}

fn collect_entries(group: &GroupRef<'_>, path: &[String], file: &str, out: &mut Vec<EntryInfo>) {
    for entry in group.entries() {
        out.push(EntryInfo {
            id: entry.id(),
            title: entry.get(fields::TITLE).unwrap_or_default().to_string(),
            username: entry.get(fields::USERNAME).unwrap_or_default().to_string(),
            group: path.join("/"),
            file: file.to_string(),
        });
    }
    let mut child_path = path.to_vec();
    for child in group.groups() {
        child_path.push(child.name.clone());
        collect_entries(&child, &child_path, file, out);
        child_path.pop();
    }
}

/// Matches an entry by title or username: exact match wins, then the first
/// case-insensitive substring, mirroring the app's credential server.
pub fn find_entry(db: &Database, query: &str) -> Option<EntryInfo> {
    let query = query.trim().to_lowercase();
    if query.is_empty() {
        return list_entries(db).into_iter().next();
    }
    let entries = list_entries(db);
    for e in &entries {
        if e.title.to_lowercase() == query || e.username.to_lowercase() == query {
            return Some(e.clone());
        }
    }
    entries.into_iter().find(|e| {
        e.title.to_lowercase().contains(&query) || e.username.to_lowercase().contains(&query)
    })
}

pub fn entry_value(entry: &EntryRef<'_>, key: &str) -> Option<String> {
    entry.get(key).map(ToString::to_string)
}

pub const COMPUTER_GROUP_NAME: &str = "计算机";
pub const MACHINE_ID_FIELD: &str = "machine-id";

/// Finds the entry for the current machine in the dedicated computer group.
pub fn find_computer_entry(db: &Database, machine_id: &str) -> Option<EntryInfo> {
    let entries = list_entries(db);
    entries.into_iter().find(|e| {
        e.group == COMPUTER_GROUP_NAME && {
            db.entry(e.id)
                .and_then(|entry| entry_value(&entry, MACHINE_ID_FIELD))
                .as_deref()
                == Some(machine_id)
        }
    })
}

/// Adds a new entry (in [group] when given, otherwise the root group) and
/// returns its id.
pub fn add_entry(db: &mut Database, changes: &EntryChanges) -> Result<EntryId, String> {
    let group_id = resolve_or_create_group(db, changes.group.as_deref())?;
    let mut group = db.group_mut(group_id).expect("group exists");
    let mut entry = group.add_entry();
    apply_changes(&mut entry, changes)?;
    Ok(entry.id())
}

/// Edits an existing entry; fields set to `Some` are written, `None` fields
/// are left untouched.
pub fn edit_entry(db: &mut Database, id: EntryId, changes: &EntryChanges) -> Result<(), String> {
    let mut entry = db
        .entry_mut(id)
        .ok_or_else(|| "entry no longer exists".to_string())?;
    apply_changes(&mut entry, changes)?;
    if let Some(group_name) = &changes.group {
        let target = resolve_or_create_group(db, Some(group_name))?;
        let mut entry = db
            .entry_mut(id)
            .ok_or_else(|| "entry no longer exists".to_string())?;
        entry
            .move_to(target)
            .map_err(|_| "target group vanished".to_string())?;
    }
    Ok(())
}

pub fn delete_entry(db: &mut Database, id: EntryId) -> Result<(), String> {
    let entry = db
        .entry_mut(id)
        .ok_or_else(|| "entry no longer exists".to_string())?;
    entry.remove();
    Ok(())
}

/// Permanently deletes every entry whose title is empty — the blank/untitled
/// entries a buggy auto-save used to create. Returns how many were removed.
pub fn delete_empty_title_entries(db: &mut Database) -> Result<usize, String> {
    let mut ids = Vec::new();
    collect_empty_title_ids(&db.root(), &mut ids);
    for id in &ids {
        let entry = db
            .entry_mut(*id)
            .ok_or_else(|| "entry no longer exists".to_string())?;
        entry.remove();
    }
    Ok(ids.len())
}

fn collect_empty_title_ids(group: &GroupRef<'_>, out: &mut Vec<EntryId>) {
    for entry in group.entries() {
        let title = entry.get(fields::TITLE).unwrap_or_default().to_string();
        if title.trim().is_empty() {
            out.push(entry.id());
        }
    }
    for child in group.groups() {
        collect_empty_title_ids(&child, out);
    }
}

fn apply_changes(entry: &mut EntryMut<'_>, changes: &EntryChanges) -> Result<(), String> {
    if let Some(title) = &changes.title {
        entry.set_unprotected(fields::TITLE, title);
    }
    if let Some(username) = &changes.username {
        entry.set_unprotected(fields::USERNAME, username);
    }
    if let Some(password) = &changes.password {
        entry.set_protected(fields::PASSWORD, password);
    }
    if let Some(url) = &changes.url {
        entry.set_unprotected(fields::URL, url);
    }
    if let Some(notes) = &changes.notes {
        entry.set_unprotected(fields::NOTES, notes);
    }
    if let Some(otp) = &changes.otp {
        entry.set_protected(OTP_FIELD, otp);
    }
    if let Some(machine_id) = &changes.machine_id {
        entry.set_unprotected(MACHINE_ID_FIELD, machine_id);
    }
    if let Some(pem) = &changes.ssh_private_key {
        entry.set_protected(SSH_PRIVATE_KEY_FIELD, pem);
    }
    if let Some(access_key) = &changes.access_key {
        entry.set_unprotected(ACCESS_KEY_FIELD, access_key);
    }
    if let Some(secret_key) = &changes.secret_key {
        entry.set_protected(SECRET_KEY_FIELD, secret_key);
    }
    Ok(())
}

fn resolve_or_create_group(db: &mut Database, group_name: Option<&str>) -> Result<GroupId, String> {
    let name = group_name.unwrap_or("");
    if name.is_empty() {
        return Ok(db.root().id());
    }
    let path: Vec<&str> = name.split('/').filter(|p| !p.is_empty()).collect();
    let existing = db.root().group_by_path(&path).map(|g| g.id());
    if let Some(id) = existing {
        return Ok(id);
    }
    // Create missing groups along the path.
    let mut current_id = db.root().id();
    for part in &path {
        let existing = db
            .group(current_id)
            .and_then(|g| g.group_by_name(part).map(|child| child.id()));
        if let Some(id) = existing {
            current_id = id;
        } else {
            let mut parent = db.group_mut(current_id).expect("group exists");
            let mut child = parent.add_group();
            child.name = (*part).to_string();
            current_id = child.id();
        }
    }
    Ok(current_id)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn create_load_add_edit_delete_round_trip() {
        let bytes = create_empty("Test", "pw").expect("create");
        let mut db = load(&bytes, "pw", None).expect("load");
        assert!(list_entries(&db).is_empty());

        let id = add_entry(
            &mut db,
            &EntryChanges {
                title: Some("GitHub".into()),
                username: Some("alice".into()),
                password: Some("s3cret".into()),
                url: Some("https://github.com".into()),
                ..Default::default()
            },
        )
        .expect("add");
        let saved = save(&db, "pw", None).expect("save");
        let mut db2 = load(&saved, "pw", None).expect("reload");
        let info = find_entry(&db2, "github").expect("find");
        assert_eq!(info.title, "GitHub");
        assert_eq!(info.username, "alice");

        edit_entry(
            &mut db2,
            id,
            &EntryChanges {
                password: Some("newpass".into()),
                group: Some("Work".into()),
                ..Default::default()
            },
        )
        .expect("edit");
        let saved2 = save(&db2, "pw", None).expect("save2");
        let db3 = load(&saved2, "pw", None).expect("reload2");
        let info = find_entry(&db3, "github").expect("find2");
        assert_eq!(info.group, "Work");
        let entry = db3.entry(info.id).expect("entry");
        assert_eq!(entry_value(&entry, "Password").as_deref(), Some("newpass"));

        let mut db4 = load(&saved2, "pw", None).expect("reload3");
        delete_entry(&mut db4, info.id).expect("delete");
        assert!(list_entries(&db4).is_empty());
    }

    #[test]
    fn wrong_password_is_rejected() {
        let bytes = create_empty("Test", "pw").expect("create");
        assert!(load(&bytes, "wrong", None).is_err());
    }

    #[test]
    fn ak_sk_fields_round_trip_through_save() {
        let bytes = create_empty("Test", "pw").expect("create");
        let mut db = load(&bytes, "pw", None).expect("load");
        let id = add_entry(
            &mut db,
            &EntryChanges {
                title: Some("Ark".into()),
                access_key: Some("AKLTabcdef".into()),
                secret_key: Some("c2VjcmV0".into()),
                ..Default::default()
            },
        )
        .expect("add");

        let saved = save(&db, "pw", None).expect("save");
        let db2 = load(&saved, "pw", None).expect("reload");
        let entry = db2.entry(id).expect("entry");
        assert_eq!(
            entry_value(&entry, ACCESS_KEY_FIELD).as_deref(),
            Some("AKLTabcdef")
        );
        assert_eq!(
            entry_value(&entry, SECRET_KEY_FIELD).as_deref(),
            Some("c2VjcmV0")
        );
    }

    #[test]
    fn read_interfaces_are_deny_by_default() {
        let bytes = create_empty("Test", "pw").expect("create");
        let mut db = load(&bytes, "pw", None).expect("load");
        let id = add_entry(
            &mut db,
            &EntryChanges {
                title: Some("GitHub".into()),
                username: Some("alice".into()),
                ..Default::default()
            },
        )
        .expect("add");

        // No explicit allow -> invisible to read interfaces.
        assert!(list_readable_entries(&db).is_empty());

        db.entry_mut(id)
            .expect("entry exists")
            .set_unprotected(READ_ALLOWED_FIELD, "1");
        let readable = list_readable_entries(&db);
        assert_eq!(readable.len(), 1);
        assert_eq!(readable[0].title, "GitHub");

        // Persisted: after save/reload the flag is still enforced.
        let saved = save(&db, "pw", None).expect("save");
        let reloaded = load(&saved, "pw", None).expect("reload");
        assert_eq!(list_readable_entries(&reloaded).len(), 1);

        // Clearing the flag denies again.
        let mut reloaded_mut = load(&saved, "pw", None).expect("reload2");
        reloaded_mut
            .entry_mut(id)
            .expect("entry exists")
            .fields
            .remove(READ_ALLOWED_FIELD);
        assert!(list_readable_entries(&reloaded_mut).is_empty());
    }
}
