//! Load vault SSH private keys into the system ssh-agent (like `ssh-add`),
//! so SSH/git connections can use them without the private key ever touching
//! the filesystem.
//!
//! The agent wire protocol is small enough to speak directly (RFC draft
//! `draft-miller-ssh-agent`): every message is a big-endian `u32` length
//! followed by a one-byte message type and its payload.

use ssh_key::encoding::{Decode, Encode};
use ssh_key::{Certificate, HashAlg, PrivateKey, PublicKey};
use std::env;
use std::fmt;
use std::io::{Read, Write};

use crate::kdbx;

const SSH_AGENT_FAILURE: u8 = 5;
const SSH_AGENT_SUCCESS: u8 = 6;
const SSH_AGENTC_REQUEST_IDENTITIES: u8 = 11;
const SSH_AGENT_IDENTITIES_ANSWER: u8 = 12;
const SSH_AGENTC_ADD_IDENTITY: u8 = 17;
const SSH_AGENTC_REMOVE_IDENTITY: u8 = 18;
const SSH_AGENTC_REMOVE_ALL_IDENTITIES: u8 = 19;

/// Refuse absurd lengths from a misbehaving agent instead of allocating them.
const MAX_MESSAGE_SIZE: usize = 1024 * 1024;
const MAX_IDENTITY_COUNT: u32 = 1024;

/// Connects to the agent socket. `ssh-agent` speaks over a Unix domain socket;
/// Windows uses a named pipe, which is not implemented here.
#[cfg(unix)]
fn connect_socket(path: &str) -> std::io::Result<Box<dyn ReadWrite>> {
    let stream = std::os::unix::net::UnixStream::connect(path)?;
    Ok(Box::new(stream))
}

#[cfg(not(unix))]
fn connect_socket(_path: &str) -> std::io::Result<Box<dyn ReadWrite>> {
    Err(std::io::Error::new(
        std::io::ErrorKind::Unsupported,
        "ssh-agent 仅支持 Unix 域套接字（Windows 的 named pipe 尚未实现）",
    ))
}

#[derive(Debug)]
pub enum Error {
    Io(std::io::Error),
    Protocol(String),
    RemoteFailure,
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Io(e) => write!(f, "{e}"),
            Self::Protocol(m) => write!(f, "ssh-agent 协议错误：{m}"),
            Self::RemoteFailure => write!(f, "ssh-agent 拒绝了请求"),
        }
    }
}

impl std::error::Error for Error {}

impl From<std::io::Error> for Error {
    fn from(e: std::io::Error) -> Self {
        Self::Io(e)
    }
}

impl From<ssh_key::Error> for Error {
    fn from(e: ssh_key::Error) -> Self {
        Self::Protocol(format!("无法解析密钥：{e}"))
    }
}

impl From<ssh_key::encoding::Error> for Error {
    fn from(e: ssh_key::encoding::Error) -> Self {
        Self::Protocol(format!("无法编解码消息：{e}"))
    }
}

/// One identity as reported by `SSH_AGENT_IDENTITIES_ANSWER`.
enum Identity {
    PublicKey(PublicKey),
    Certificate(Box<Certificate>),
}

/// A connection to the agent listening on `SSH_AUTH_SOCK`.
///
/// The agent is addressed through a Unix domain socket, so only Unix hosts can
/// actually connect; the trait object keeps the wire-protocol code portable and
/// lets non-Unix builds fail at runtime with a clear message instead of failing
/// to compile.
trait ReadWrite: Read + Write {}
impl<T: Read + Write> ReadWrite for T {}

struct Client {
    socket: Box<dyn ReadWrite>,
}

impl Client {
    fn connect() -> Result<Self, String> {
        let sock = env::var("SSH_AUTH_SOCK").map_err(|_| {
            "未设置 SSH_AUTH_SOCK：请先启动 ssh-agent（如 eval \"$(ssh-agent -s)\"）".to_string()
        })?;
        let socket =
            connect_socket(&sock).map_err(|e| format!("无法连接 ssh-agent（{sock}）：{e}"))?;
        Ok(Self { socket })
    }

    fn add_identity(&mut self, key: &PrivateKey) -> Result<(), Error> {
        let mut payload = vec![SSH_AGENTC_ADD_IDENTITY];
        payload.extend_from_slice(&key.key_data().encode_vec()?);
        payload.extend_from_slice(&key.comment().encode_vec()?);
        self.send(&payload)?;
        self.expect_success()
    }

    fn remove_identity(&mut self, key: &PrivateKey) -> Result<(), Error> {
        let mut payload = vec![SSH_AGENTC_REMOVE_IDENTITY];
        // The agent expects `string key_blob`, i.e. the encoded key data wrapped
        // in its own length prefix.
        payload.extend_from_slice(&key.public_key().key_data().encode_vec()?.encode_vec()?);
        self.send(&payload)?;
        self.expect_success()
    }

    fn remove_all_identities(&mut self) -> Result<(), Error> {
        self.send(&[SSH_AGENTC_REMOVE_ALL_IDENTITIES])?;
        self.expect_success()
    }

    fn list_identities(&mut self) -> Result<Vec<Identity>, Error> {
        self.send(&[SSH_AGENTC_REQUEST_IDENTITIES])?;
        let body = self.receive()?;
        let message_type = body
            .first()
            .copied()
            .ok_or_else(|| Error::Protocol("空响应".to_string()))?;
        if message_type == SSH_AGENT_FAILURE {
            return Err(Error::RemoteFailure);
        }
        if message_type != SSH_AGENT_IDENTITIES_ANSWER {
            return Err(Error::Protocol(format!("意外的消息类型 {message_type}")));
        }
        let mut rest = &body[1..];
        let count = u32::decode(&mut rest)?;
        if count > MAX_IDENTITY_COUNT {
            return Err(Error::Protocol("agent 返回的密钥数量异常".to_string()));
        }
        let mut identities = Vec::with_capacity(count as usize);
        for _ in 0..count {
            let blob = Vec::<u8>::decode(&mut rest)?;
            let comment = Vec::<u8>::decode(&mut rest)?;
            identities.push(decode_identity(&blob, &comment)?);
        }
        Ok(identities)
    }

    fn send(&mut self, payload: &[u8]) -> Result<(), Error> {
        let len =
            u32::try_from(payload.len()).map_err(|_| Error::Protocol("消息过长".to_string()))?;
        self.socket.write_all(&len.to_be_bytes())?;
        self.socket.write_all(payload)?;
        self.socket.flush()?;
        Ok(())
    }

    /// Reads one message and returns its type byte plus payload.
    fn receive(&mut self) -> Result<Vec<u8>, Error> {
        let mut len = [0u8; 4];
        self.socket.read_exact(&mut len)?;
        let len = u32::from_be_bytes(len) as usize;
        if len == 0 || len > MAX_MESSAGE_SIZE {
            return Err(Error::Protocol(format!("消息长度异常：{len}")));
        }
        let mut body = vec![0u8; len];
        self.socket.read_exact(&mut body)?;
        Ok(body)
    }

    fn expect_success(&mut self) -> Result<(), Error> {
        match self.receive()?.first().copied() {
            Some(SSH_AGENT_SUCCESS) => Ok(()),
            Some(SSH_AGENT_FAILURE) => Err(Error::RemoteFailure),
            Some(other) => Err(Error::Protocol(format!("意外的消息类型 {other}"))),
            None => Err(Error::Protocol("空响应".to_string())),
        }
    }
}

fn decode_identity(blob: &[u8], comment: &[u8]) -> Result<Identity, Error> {
    let is_certificate = key_type(blob)?.contains("-cert-");
    if is_certificate {
        let mut cert = Certificate::from_bytes(blob)?;
        cert.set_comment(comment.to_vec());
        Ok(Identity::Certificate(Box::new(cert)))
    } else {
        let mut key = PublicKey::from_bytes(blob)?;
        key.set_comment(comment.to_vec());
        Ok(Identity::PublicKey(key))
    }
}

fn key_type(blob: &[u8]) -> Result<String, Error> {
    let mut rest = blob;
    let bytes = Vec::<u8>::decode(&mut rest)?;
    String::from_utf8(bytes).map_err(|e| Error::Protocol(format!("密钥类型不是 UTF-8：{e}")))
}

/// Loads the entry's SSH private key into the connected ssh-agent.
pub fn add(db: &kdbx::Database, query: &str) -> i32 {
    let key = match private_key_from_entry(db, query) {
        Ok(key) => key,
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };
    let mut client = match Client::connect() {
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
    let mut client = match Client::connect() {
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
    let mut client = match Client::connect() {
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
    let mut client = match Client::connect() {
        Ok(c) => c,
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };
    let identities = match client.list_identities() {
        Ok(v) => v,
        Err(e) => {
            eprintln!("error: 无法列出 ssh-agent 中的密钥：{e}");
            return 1;
        }
    };
    for identity in &identities {
        match identity {
            Identity::PublicKey(pk) => {
                println!("{}\t{}", pk.fingerprint(HashAlg::Sha256), pk.comment());
            }
            Identity::Certificate(cert) => {
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
    let mut client = match Client::connect() {
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
        Err(Error::RemoteFailure) => {}
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
        out.push_str(comment.as_str_lossy());
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;
    use ssh_key::rand_core::UnwrapErr;
    use ssh_key::{Algorithm, LineEnding};

    #[test]
    fn should_extract_openssh_private_key_from_entry() {
        let mut rng = UnwrapErr(getrandom::SysRng);
        let key = PrivateKey::random(&mut rng, Algorithm::Ed25519).expect("random key");
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

    #[test]
    fn should_encode_add_identity_payload() {
        let mut rng = UnwrapErr(getrandom::SysRng);
        let key = PrivateKey::random(&mut rng, Algorithm::Ed25519).expect("random key");
        let mut payload = vec![SSH_AGENTC_ADD_IDENTITY];
        payload.extend_from_slice(&key.key_data().encode_vec().unwrap());
        payload.extend_from_slice(&key.comment().encode_vec().unwrap());

        // The agent parses `string key_type` first; it must match the key.
        let mut rest = &payload[1..];
        let key_type = String::from_utf8(Vec::<u8>::decode(&mut rest).unwrap()).unwrap();
        assert_eq!(key_type, "ssh-ed25519");
    }

    #[test]
    fn should_encode_remove_identity_with_public_blob_only() {
        let mut rng = UnwrapErr(getrandom::SysRng);
        let key = PrivateKey::random(&mut rng, Algorithm::Ed25519).expect("random key");
        let public_blob = key.public_key().key_data().encode_vec().unwrap();

        // The agent expects `string key_blob`, so the payload is the type byte
        // followed by the length-prefixed public key.
        let mut payload = vec![SSH_AGENTC_REMOVE_IDENTITY];
        payload.extend_from_slice(&public_blob.encode_vec().unwrap());

        assert_eq!(payload[0], SSH_AGENTC_REMOVE_IDENTITY);
        let mut rest = &payload[1..];
        assert_eq!(Vec::<u8>::decode(&mut rest).unwrap(), public_blob);
        assert!(rest.is_empty());

        // Only the public half is sent: Ed25519 private keys carry 32 bytes of
        // seed after the public key, so the blob must end right after it.
        assert_eq!(public_blob.len(), 4 + 11 + 4 + 32);
    }
}
