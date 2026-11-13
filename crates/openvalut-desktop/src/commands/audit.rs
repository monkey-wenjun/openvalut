//! Security audit: weak (zxcvbn), reused, and stale passwords.

use std::collections::HashMap;

use serde::Serialize;
use tauri::State;
use zxcvbn::zxcvbn;

use crate::state::AppState;

/// One problem found by [`audit_run`].
#[derive(Serialize, Clone)]
pub struct AuditIssue {
    pub kind: String,
    pub uuid: String,
    pub title: String,
    pub username: String,
    pub group: String,
    /// zxcvbn entropy score 0-4, only for `weak` issues.
    pub score: Option<u8>,
    /// How many entries share this password, only for `reused` issues.
    pub reuse_count: Option<usize>,
    /// How many entries share this title and username, only for `duplicate` issues.
    pub duplicate_count: Option<usize>,
    /// Days since the entry was last modified, only for `old` issues.
    pub days_since_update: Option<i64>,
}

#[derive(Serialize)]
pub struct AuditReport {
    pub weak: Vec<AuditIssue>,
    pub reused: Vec<AuditIssue>,
    pub old: Vec<AuditIssue>,
    /// Entries stored under the same title and username — the duplicates a
    /// previous version of the app left behind.
    pub duplicates: Vec<AuditIssue>,
    pub entry_count: usize,
}

const WEAK_SCORE_MAX: u8 = 2;
const STALE_DAYS: i64 = 365;

/// Whether this password is a literal the audit can evaluate. Secret
/// references (`ov://`) point at another entry and have no entropy of their own.
fn is_literal_password(password: &str) -> bool {
    !password.is_empty()
        && !password.starts_with("ov://")
        && !password.starts_with("op://")
        && !password.starts_with("{REF:")
}

#[tauri::command]
pub fn audit_run(state: State<'_, AppState>) -> Result<AuditReport, String> {
    let guard = state.vault.read().unwrap();
    let handle = guard.as_ref().ok_or("密码库未解锁")?;
    let vault = handle.vault.lock().unwrap();
    let entries = vault.entries();
    drop(vault);
    drop(guard);
    Ok(build_report(&entries))
}

fn build_report(entries: &[openvalut_core::Entry]) -> AuditReport {
    let mut report = AuditReport {
        weak: Vec::new(),
        reused: Vec::new(),
        old: Vec::new(),
        duplicates: Vec::new(),
        entry_count: entries.len(),
    };

    let mut reuse: HashMap<String, usize> = HashMap::new();
    for entry in entries {
        if is_literal_password(&entry.password) {
            *reuse.entry(entry.password.clone()).or_default() += 1;
        }
    }

    // Same title and username, whatever the password says: those are the rows
    // the user reads as "华泰证券 有 2 条".
    let mut by_identity: HashMap<(String, String), Vec<usize>> = HashMap::new();
    for (index, entry) in entries.iter().enumerate() {
        if entry.title.is_empty() {
            continue;
        }
        by_identity
            .entry((entry.title.to_lowercase(), entry.username.to_lowercase()))
            .or_default()
            .push(index);
    }
    let mut duplicate_groups: Vec<&Vec<usize>> = by_identity.values().filter(|g| g.len() > 1).collect();
    duplicate_groups.sort_by_key(|g| entries[g[0]].title.clone());
    for group in duplicate_groups {
        for index in group {
            let entry = &entries[*index];
            report.duplicates.push(AuditIssue {
                duplicate_count: Some(group.len()),
                ..issue("duplicate", entry)
            });
        }
    }

    for entry in entries {
        if is_literal_password(&entry.password) {
            let estimate = zxcvbn(&entry.password, &[]);
            let score = u8::from(estimate.score());
            if score <= WEAK_SCORE_MAX {
                report.weak.push(AuditIssue {
                    score: Some(score),
                    ..issue("weak", entry)
                });
            }

            let uses = reuse[&entry.password];
            if uses > 1 {
                report.reused.push(AuditIssue {
                    reuse_count: Some(uses),
                    ..issue("reused", entry)
                });
            }
        }

        // Staleness only applies to entries that actually own a password.
        if is_literal_password(&entry.password) {
            if let Some(updated_at) = &entry.updated_at {
                if let Ok(modified) = chrono::NaiveDateTime::parse_from_str(updated_at, "%Y-%m-%d %H:%M:%S") {
                    let days = (chrono::Utc::now().naive_utc() - modified).num_days();
                    if days > STALE_DAYS {
                        report.old.push(AuditIssue {
                            days_since_update: Some(days),
                            ..issue("old", entry)
                        });
                    }
                }
            }
        }
    }

    report
}

fn issue(kind: &str, entry: &openvalut_core::Entry) -> AuditIssue {
    AuditIssue {
        kind: kind.into(),
        uuid: entry.uuid.clone(),
        title: entry.title.clone(),
        username: entry.username.clone(),
        group: entry.group.clone(),
        score: None,
        reuse_count: None,
        duplicate_count: None,
        days_since_update: None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn entry(title: &str, password: &str, updated_at: Option<&str>) -> openvalut_core::Entry {
        openvalut_core::Entry {
            uuid: format!("uuid-{title}"),
            title: title.into(),
            username: "user".into(),
            password: password.into(),
            url: String::new(),
            notes: String::new(),
            group: String::new(),
            custom: Vec::new(),
            updated_at: updated_at.map(str::to_string),
        }
    }

    fn named(title: &str, username: &str, password: &str) -> openvalut_core::Entry {
        openvalut_core::Entry {
            uuid: format!("uuid-{title}-{password}"),
            title: title.into(),
            username: username.into(),
            password: password.into(),
            url: String::new(),
            notes: String::new(),
            group: "证券".into(),
            custom: Vec::new(),
            updated_at: None,
        }
    }

    #[test]
    fn report_flags_weak_reused_and_stale() {
        let stale = (chrono::Utc::now().naive_utc() - chrono::Duration::days(400))
            .format("%Y-%m-%d %H:%M:%S")
            .to_string();
        let fresh = (chrono::Utc::now().naive_utc() - chrono::Duration::days(10))
            .format("%Y-%m-%d %H:%M:%S")
            .to_string();

        let entries = vec![
            entry("Bank", "correct horse battery staple", Some(&fresh)),
            entry("Forum", "123456", Some(&fresh)),
            entry("Old Site", "S0me-Str0ng-P@ss!", Some(&stale)),
            // Same password as "Old Site" → reused, but strong → not weak.
            entry("Mirror", "S0me-Str0ng-P@ss!", Some(&fresh)),
            // Secret references are skipped entirely.
            entry("Ref", "ov:///Bank/Password", Some(&stale)),
            entry("Empty", "", Some(&stale)),
            // Same title and username, different passwords → duplicates.
            named("华泰证券", "trader", "Xk9-mV2/mQ7zL4pW5"),
            named("华泰证券", "trader", "Bq4*Wp8#Rt2!Yn6^Zs3"),
            // Same title, different account → not a duplicate.
            named("华泰证券", "advisor", "Gf7&Jm3@Ux9#Qs5!Ke2"),
        ];

        let report = build_report(&entries);
        assert_eq!(report.entry_count, 9);
        assert_eq!(report.weak.len(), 1);
        assert_eq!(report.weak[0].uuid, "uuid-Forum");
        assert_eq!(report.reused.len(), 2);
        assert!(report.reused.iter().all(|i| i.reuse_count == Some(2)));
        assert_eq!(report.old.len(), 1);
        assert_eq!(report.old[0].uuid, "uuid-Old Site");
        assert!(report.old[0].days_since_update.unwrap() > 365);
        assert_eq!(report.duplicates.len(), 2);
        assert!(report.duplicates.iter().all(|i| i.duplicate_count == Some(2)));
        assert_eq!(report.duplicates[0].username, "trader");
    }
}
