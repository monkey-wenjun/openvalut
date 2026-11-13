//! Row-storage codec: map between keepass entries and OpenValut Cloud rows.
//!
//! Each cloud row stores one encrypted entry. The plaintext is a JSON map
//! `{ fields, protected, icon }` mirroring the app's `row_entry_codec.dart`,
//! and the group path is stored encrypted as `base64(nonce).base64(ct)`.

use std::collections::{HashMap, HashSet};

use keepass::db::{EntryId, EntryMut, GroupId, GroupRef};
use keepass::Database;
use serde_json::{json, Value};
use uuid::Uuid;

use crate::cloud;

/// A decoded server row (payload decrypted, group decrypted).
#[derive(Debug, Clone)]
pub struct DecodedRow {
    pub group_path: String,
    pub fields: HashMap<String, String>,
    pub protected: Vec<String>,
    pub icon: Option<usize>,
    pub updated_at: i64,
}

/// Reconstructs a keepass [Database] from the vault's rows. Also returns the
/// decoded rows so a later save can diff against the last-synced state.
pub fn database_from_rows(
    name: &str,
    rows: &[cloud::CloudRow],
    key: &[u8; 32],
) -> Result<(Database, HashMap<String, DecodedRow>), String> {
    let mut db = Database::new();
    db.meta.database_name = Some(name.to_string());
    db.root_mut().name = name.to_string();
    let mut groups: HashMap<String, GroupId> = HashMap::new();
    groups.insert(String::new(), db.root().id());
    let mut synced = HashMap::with_capacity(rows.len());
    for row in rows {
        let group_path = cloud::decrypt_group(key, &row.group).unwrap_or_default();
        let payload = cloud::decrypt_row(key, &row.nonce, &row.ciphertext)?;
        let payload_value: Value =
            serde_json::from_slice(&payload).map_err(|e| format!("invalid row payload: {e}"))?;
        let (fields_map, protected, icon) = decode_payload(&payload_value);
        let group_id = ensure_group(&mut db, &mut groups, &group_path)?;
        let entry_id = EntryId::from_uuid(
            Uuid::parse_str(&row.uuid)
                .map_err(|e| format!("invalid row uuid {}: {e}", row.uuid))?,
        );
        let mut group = db
            .group_mut(group_id)
            .ok_or_else(|| "group vanished".to_string())?;
        let entry = group
            .add_entry_with_id(entry_id)
            .map_err(|e| format!("duplicate row uuid {}: {e}", row.uuid))?;
        apply_payload(entry, &fields_map, &protected, icon);
        synced.insert(
            row.uuid.clone(),
            DecodedRow {
                group_path,
                fields: fields_map,
                protected,
                icon,
                updated_at: row.updated_at,
            },
        );
    }
    Ok((db, synced))
}

/// Computes the upserts/deletes needed to bring the server in sync with `db`.
pub fn diff_entries(
    db: &Database,
    key: &[u8; 32],
    synced: &HashMap<String, DecodedRow>,
) -> Result<(Vec<cloud::RowUpsert>, Vec<String>), String> {
    let mut upserts = Vec::new();
    let mut seen = HashSet::new();
    let paths = group_paths(db);
    for entry in db.iter_all_entries() {
        let uuid = entry.id().uuid().simple().to_string();
        seen.insert(uuid.clone());
        let group_path = paths.get(&entry.parent().id()).cloned().unwrap_or_default();
        let (fields_map, protected, icon) = collect_fields(&entry);
        let payload = encode_payload(&fields_map, &protected, icon);
        let prev = synced.get(&uuid);
        let unchanged = prev.is_some_and(|p| {
            p.group_path == group_path
                && p.fields == fields_map
                && p.protected == protected
                && p.icon == icon
        });
        if unchanged {
            continue;
        }
        let group = cloud::encrypt_group(key, &group_path)?;
        let (nonce, ciphertext) = cloud::encrypt_row(key, &payload)?;
        upserts.push(cloud::RowUpsert {
            uuid: uuid.clone(),
            group,
            nonce,
            ciphertext,
            base_updated_at: prev.map_or(0, |p| p.updated_at),
        });
    }
    let deletes: Vec<String> = synced
        .keys()
        .filter(|u| !seen.contains(*u))
        .cloned()
        .collect();
    Ok((upserts, deletes))
}

/// Encodes an entry's string fields + protected flags + icon as the row JSON.
fn encode_payload(
    fields: &HashMap<String, String>,
    protected: &[String],
    icon: Option<usize>,
) -> Vec<u8> {
    let v = json!({
        "fields": fields,
        "protected": protected,
        "icon": icon,
    });
    serde_json::to_vec(&v).unwrap_or_default()
}

/// Decodes a row payload JSON map.
fn decode_payload(v: &Value) -> (HashMap<String, String>, Vec<String>, Option<usize>) {
    let fields = v
        .get("fields")
        .and_then(Value::as_object)
        .map(|o| {
            o.iter()
                .map(|(k, val)| (k.clone(), val.as_str().unwrap_or("").to_string()))
                .collect()
        })
        .unwrap_or_default();
    let protected = v
        .get("protected")
        .and_then(Value::as_array)
        .map(|a| {
            let mut p: Vec<String> = a
                .iter()
                .filter_map(|x| x.as_str().map(String::from))
                .collect();
            p.sort();
            p
        })
        .unwrap_or_default();
    let icon = v.get("icon").and_then(Value::as_u64).map(|i| i as usize);
    (fields, protected, icon)
}

/// Collects an entry's string fields and their protected flags.
fn collect_fields(
    entry: &keepass::db::EntryRef<'_>,
) -> (HashMap<String, String>, Vec<String>, Option<usize>) {
    let mut fields = HashMap::new();
    let mut protected = Vec::new();
    for (k, value) in &entry.fields {
        fields.insert(k.clone(), value.as_str().to_string());
        if value.is_protected() {
            protected.push(k.clone());
        }
    }
    protected.sort();
    let icon = match entry.icon() {
        Some(keepass::db::Icon::BuiltIn(i)) => Some(*i),
        _ => None,
    };
    (fields, protected, icon)
}

/// Applies a decoded payload onto a freshly-created entry.
fn apply_payload(
    mut entry: EntryMut<'_>,
    fields: &HashMap<String, String>,
    protected: &[String],
    icon: Option<usize>,
) {
    for (k, val) in fields {
        if protected.iter().any(|p| p == k) {
            entry.set_protected(k.as_str(), val.as_str());
        } else {
            entry.set_unprotected(k.as_str(), val.as_str());
        }
    }
    match icon {
        Some(i) => entry.set_icon_builtin(i),
        None => entry.set_icon_none(),
    }
}

/// Resolves or creates the group chain for a path ("a/b/c"); "" is the root.
fn ensure_group(
    db: &mut Database,
    groups: &mut HashMap<String, GroupId>,
    path: &str,
) -> Result<GroupId, String> {
    if let Some(id) = groups.get(path) {
        return Ok(*id);
    }
    let mut cur = db.root().id();
    let mut cur_path = String::new();
    for part in path.split('/').filter(|p| !p.is_empty()) {
        if !cur_path.is_empty() {
            cur_path.push('/');
        }
        cur_path.push_str(part);
        if let Some(id) = groups.get(&cur_path) {
            cur = *id;
            continue;
        }
        let mut parent = db
            .group_mut(cur)
            .ok_or_else(|| "group vanished".to_string())?;
        let mut child = parent.add_group();
        child.name = part.to_string();
        let id = child.id();
        groups.insert(cur_path.clone(), id);
        cur = id;
    }
    Ok(cur)
}

/// Map of every group id to its slash-separated path ("" for the root).
fn group_paths(db: &Database) -> HashMap<GroupId, String> {
    let mut out = HashMap::new();
    out.insert(db.root().id(), String::new());
    fn walk(group: GroupRef<'_>, prefix: &str, out: &mut HashMap<GroupId, String>) {
        for child in group.groups() {
            let path = if prefix.is_empty() {
                child.name.clone()
            } else {
                format!("{prefix}/{}", child.name)
            };
            out.insert(child.id(), path.clone());
            walk(child, &path, out);
        }
    }
    walk(db.root(), "", &mut out);
    out
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::kdbx;

    fn key() -> [u8; 32] {
        cloud::derive_key("pw", "0123456789abcdef0123456789abcdef").unwrap()
    }

    fn sample_row(key: &[u8; 32], uuid: &str, group: &str, title: &str) -> cloud::CloudRow {
        let payload = json!({
            "fields": {"Title": title, "UserName": "alice", "Password": "s3cret", "OTPAuth": "otpauth://totp/X?secret=ABC"},
            "protected": ["OTPAuth", "Password"],
            "icon": 1,
        });
        let (nonce, ct) = cloud::encrypt_row(key, &serde_json::to_vec(&payload).unwrap()).unwrap();
        cloud::CloudRow {
            uuid: uuid.to_string(),
            group: cloud::encrypt_group(key, group).unwrap(),
            nonce,
            ciphertext: ct,
            updated_at: 42,
        }
    }

    #[test]
    fn rows_round_trip_is_faithful() {
        let k = key();
        let rows = vec![
            sample_row(&k, "00000000000000000000000000000001", "网站", "GitHub"),
            sample_row(&k, "00000000000000000000000000000002", "网站/邮箱", "Mail"),
            sample_row(&k, "00000000000000000000000000000003", "", "Root Entry"),
        ];
        let (db, synced) = database_from_rows("Test", &rows, &k).unwrap();
        assert_eq!(synced.len(), 3);

        // A faithful reconstruction must produce no upserts/deletes.
        let (upserts, deletes) = diff_entries(&db, &k, &synced).unwrap();
        assert!(upserts.is_empty(), "unexpected upserts: {upserts:#?}");
        assert!(deletes.is_empty());

        // The entries are readable with the expected titles and groups.
        let mut titles = kdbx::list_entries(&db)
            .into_iter()
            .map(|e| (e.title, e.group))
            .collect::<Vec<_>>();
        titles.sort();
        assert_eq!(
            titles,
            vec![
                ("GitHub".to_string(), "网站".to_string()),
                ("Mail".to_string(), "网站/邮箱".to_string()),
                ("Root Entry".to_string(), String::new()),
            ]
        );

        // Adding a new entry yields exactly one upsert.
        let mut db2 = db.clone();
        let _ = kdbx::add_entry(
            &mut db2,
            &kdbx::EntryChanges {
                title: Some("New".into()),
                username: Some("bob".into()),
                group: Some("网站".into()),
                ..Default::default()
            },
        );
        let (upserts, deletes) = diff_entries(&db2, &k, &synced).unwrap();
        assert_eq!(upserts.len(), 1, "one new entry upserted: {upserts:#?}");
        assert_eq!(upserts[0].base_updated_at, 0);
        assert!(deletes.is_empty());
    }
}
