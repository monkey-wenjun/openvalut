//! Load vault SSH private keys into the system ssh-agent (like `ssh-add`),
//! so SSH/git connections can use them without the private key ever touching
//! the filesystem.

use ssh_agent_client_rs::{Client, Identity};
use ssh_key::{HashAlg, PrivateKey};
use std::env;
use std::path::Path;

use crate::kdbx;

/// Loads the entry's SSH private key into the connected ssh-agent.
pub fn add(db: &kdbx::Database, query: &str) -> i32 {
    let key = match private_key_from_entry(db, query) {
        Ok(key) => key,
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };
    let mut client = match connect() {
        Ok(c) => c,
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };
    if let Err(e) = client.add_identity(&key) {
        eprintln!("error: 无法加载密钥到 ssh-agent：{e}");
        return 1;
    }
    println!("added {}", describe(&key));
    0
}

/// Best-effort auto-load: after a vault is unlocked, load every entry that
/// looks like an SSH server profile (has `ssh-host` or `ssh-port`) into the
/// connected ssh-agent. Never fails the surrounding command when the agent is
/// unavailable or a single key cannot be parsed.
pub fn add_server_keys(db: &kdbx::Database) -> i32 {
    if env::var_os("SSH_AUTH_SOCK").is_none() {
        return 0;
    }
    let mut client = match connect() {
        Ok(c) => c,
        Err(e) => {
            eprintln!("warning: 无法自动加载 SSH 服务器密钥：{e}");
            return 0;
        }
    };
    let mut added = 0;
    for info in kdbx::list_entries(db) {
        if kdbx::is_entry_in_recycle_bin(db, &info.id) {
            continue;
        }
        let Some(entry) = db.entry(info.id) else {
            continue;
        };
        let host = entry.get(kdbx::SSH_HOST_FIELD).map(str::trim).unwrap_or("");
        let port = entry.get(kdbx::SSH_PORT_FIELD).map(str::trim).unwrap_or("");
        if host.is_empty() && port.is_empty() {
            continue;
        }
        let pem = match entry.get(kdbx::SSH_PRIVATE_KEY_FIELD) {
            Some(p) if !p.trim().is_empty() => p,
            _ => continue,
        };
        let key = match PrivateKey::from_openssh(pem) {
            Ok(k) => k,
            Err(e) => {
                eprintln!("warning: 无法解析条目 {} 的 SSH 私钥：{e}", info.title);
                continue;
            }
        };
        if let Err(e) = client.add_identity(&key) {
            eprintln!("warning: 无法加载条目 {} 到 ssh-agent：{e}", info.title);
            continue;
        }
        added += 1;
        let target = if host.is_empty() {
            info.title.clone()
        } else {
            format!("{host}:{}", if port.is_empty() { "22" } else { port })
        };
        println!("已加载 SSH 服务器密钥 {target} 到 ssh-agent");
    }
    if added > 0 {
        println!("已自动加载 {added} 把服务器 SSH 密钥到 ssh-agent");
    }
    0
}

/// Removes the entry's key from the ssh-agent (matched by its public part).
pub fn remove(db: &kdbx::Database, query: &str) -> i32 {
    let key = match private_key_from_entry(db, query) {
        Ok(key) => key,
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };
    let mut client = match connect() {
        Ok(c) => c,
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };
    if let Err(e) = client.remove_identity(&key) {
        eprintln!("error: 无法从 ssh-agent 移除密钥：{e}");
        return 1;
    }
    println!("removed {}", describe(&key));
    0
}

/// Lists the identities currently loaded in the ssh-agent.
pub fn list() -> i32 {
    let mut client = match connect() {
        Ok(c) => c,
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };
    let identities = match client.list_all_identities() {
        Ok(v) => v,
        Err(e) => {
            eprintln!("error: 无法列出 ssh-agent 中的密钥：{e}");
            return 1;
        }
    };
    for identity in &identities {
        match identity {
            Identity::PublicKey(pk) => {
                let pk = pk.as_ref();
                println!("{}\t{}", pk.fingerprint(HashAlg::Sha256), pk.comment());
            }
            Identity::Certificate(cert) => {
                let cert = cert.as_ref();
                println!("certificate\t{}\t{}", cert.algorithm(), cert.comment());
            }
        }
    }
    if identities.is_empty() {
        println!("(ssh-agent 中没有已加载的密钥)");
    }
    0
}

/// Removes all identities from the ssh-agent.
pub fn remove_all() -> i32 {
    let mut client = match connect() {
        Ok(c) => c,
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };
    match client.remove_all_identities() {
        Ok(()) => {}
        // OpenSSH's agent replies failure when there is nothing to remove;
        // an empty agent is still a successful "removed all".
        Err(ssh_agent_client_rs::Error::RemoteFailure) => {}
        Err(e) => {
            eprintln!("error: 无法清空 ssh-agent：{e}");
            return 1;
        }
    }
    println!("removed all identities");
    0
}

fn private_key_from_entry(db: &kdbx::Database, query: &str) -> Result<PrivateKey, String> {
    let entry = kdbx::find_entry(db, query).ok_or_else(|| format!("未找到条目：{query}"))?;
    let entry_ref = db.entry(entry.id).expect("entry exists");
    let pem = kdbx::entry_value(&entry_ref, kdbx::SSH_PRIVATE_KEY_FIELD)
        .filter(|v| !v.trim().is_empty())
        .ok_or_else(|| format!("条目 {query} 没有 {} 字段", kdbx::SSH_PRIVATE_KEY_FIELD))?;
    PrivateKey::from_openssh(pem).map_err(|e| format!("无法解析 SSH 私钥：{e}"))
}

/// One-line description of a key: algorithm, fingerprint and comment.
fn describe(key: &PrivateKey) -> String {
    let public = key.public_key();
    let comment = public.comment();
    let mut out = format!(
        "{} {}",
        public.algorithm(),
        public.fingerprint(HashAlg::Sha256)
    );
    if !comment.is_empty() {
        out.push(' ');
        out.push_str(comment);
    }
    out
}

fn connect() -> Result<Client, String> {
    let sock = env::var("SSH_AUTH_SOCK").map_err(|_| {
        "未设置 SSH_AUTH_SOCK：请先启动 ssh-agent（如 eval \"$(ssh-agent -s)\"）".to_string()
    })?;
    Client::connect(Path::new(&sock)).map_err(|e| format!("无法连接 ssh-agent（{sock}）：{e}"))
}

#[cfg(test)]
mod tests {
    use super::*;
    use ssh_key::rand_core::OsRng;
    use ssh_key::{Algorithm, LineEnding};

    #[test]
    fn should_extract_openssh_private_key_from_entry() {
        let key = PrivateKey::random(&mut OsRng, Algorithm::Ed25519).expect("random key");
        let pem = key.to_openssh(LineEnding::LF).expect("openssh pem");

        let mut db = keepass::Database::new();
        {
            let mut root = db.root_mut();
            let mut entry = root.add_entry();
            entry.set_unprotected(keepass::db::fields::TITLE, "my ssh key");
            entry.set_protected(kdbx::SSH_PRIVATE_KEY_FIELD, pem.as_str());
        }

        let parsed = private_key_from_entry(&db, "my ssh key").expect("parse from entry");
        assert_eq!(
            parsed.public_key().fingerprint(HashAlg::Sha256),
            key.public_key().fingerprint(HashAlg::Sha256)
        );
    }

    #[test]
    fn should_report_missing_ssh_key_field() {
        let mut db = keepass::Database::new();
        {
            let mut root = db.root_mut();
            let mut entry = root.add_entry();
            entry.set_unprotected(keepass::db::fields::TITLE, "plain login");
        }

        let err = private_key_from_entry(&db, "plain login").expect_err("no ssh key");
        assert!(err.contains(kdbx::SSH_PRIVATE_KEY_FIELD), "{err}");
    }
}
