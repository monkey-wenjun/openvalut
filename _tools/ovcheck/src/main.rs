//! Offline OpenValut Cloud vault-key checker.
//!
//! Reads a vault-cache `.meta` file (the encrypted per-entry row store) and
//! reports, for one master password entered at the prompt:
//!   - how many row payloads decrypt with the derived vault key;
//!   - how many row group paths decrypt;
//!   - whether that matches the whole set (i.e. this password is the one the
//!     rows are currently encrypted under).
//!
//! The password is read with echo disabled and is never printed, logged, or
//! written anywhere. Nothing is sent over the network.

use std::io::{IsTerminal, Read};

use aes_gcm::aead::{Aead, KeyInit};
use aes_gcm::{Aes256Gcm, Key, Nonce};
use argon2::Algorithm::Argon2id;
use argon2::Version::V0x13;
use argon2::{Argon2, Params};
use base64::Engine;
use base64::engine::general_purpose::STANDARD as B64;

#[derive(serde::Deserialize)]
struct Meta {
    rows: Vec<Row>,
    blob: Option<Blob>,
}

#[derive(serde::Deserialize)]
struct Blob {
    nonce: String,
    ciphertext: String,
}

#[derive(serde::Deserialize)]
struct Row {
    group: String,
    nonce: String,
    ciphertext: String,
}

fn derive_key(password: &[u8], salt: &[u8]) -> Result<Vec<u8>, String> {
    let params = Params::new(64 * 1024, 3, 4, Some(32))
        .map_err(|e| format!("bad argon2 params: {e}"))?;
    let argon2 = Argon2::new(Argon2id, V0x13, params);
    let mut out = vec![0u8; 32];
    argon2
        .hash_password_into(password, salt, &mut out)
        .map_err(|e| format!("argon2 failed: {e}"))?;
    Ok(out)
}

fn gcm_decrypt(key: &[u8], nonce_b64: &str, ct_b64: &str) -> Result<Vec<u8>, ()> {
    let nonce_bytes = B64.decode(nonce_b64).map_err(|_| ())?;
    let ct = B64.decode(ct_b64).map_err(|_| ())?;
    if nonce_bytes.len() != 12 {
        return Err(());
    }
    let cipher = Aes256Gcm::new(Key::<Aes256Gcm>::from_slice(key));
    cipher
        .decrypt(Nonce::from_slice(&nonce_bytes), ct.as_slice())
        .map_err(|_| ())
}

fn decrypt_group_path(key: &[u8], stored: &str) -> Result<String, ()> {
    let dot = stored.find('.').ok_or(())?;
    if dot <= 0 {
        return Err(());
    }
    let plain = gcm_decrypt(key, &stored[..dot], &stored[dot + 1..])?;
    String::from_utf8(plain).map_err(|_| ())
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        eprintln!("usage: ovcheck <vault-cache.meta> [extra.meta ...]");
        std::process::exit(2);
    }
    let password = if std::io::stdin().is_terminal() {
        match rpassword::prompt_password("master password: ") {
            Ok(p) => p,
            Err(e) => {
                eprintln!("cannot read password: {e}");
                std::process::exit(2);
            }
        }
    } else {
        let mut line = String::new();
        if std::io::stdin().read_line(&mut line).is_err() {
            eprintln!("cannot read password from stdin");
            std::process::exit(2);
        }
        line.trim_end_matches(['\r', '\n']).to_string()
    };
    if password.trim().is_empty() {
        eprintln!("empty password");
        std::process::exit(2);
    }

    for path in &args[1..] {
        let mut data = String::new();
        match std::fs::File::open(path).and_then(|mut f| f.read_to_string(&mut data)) {
            Ok(_) => {}
            Err(e) => {
                eprintln!("{path}: cannot read: {e}");
                continue;
            }
        }
        let meta: Meta = match serde_json::from_str(&data) {
            Ok(m) => m,
            Err(e) => {
                eprintln!("{path}: bad meta json: {e}");
                continue;
            }
        };
        let total = meta.rows.len();
        let key = match derive_key(password.as_bytes(), path_base_vault_id(path).as_bytes()) {
            Ok(k) => k,
            Err(e) => {
                eprintln!("{path}: {e}");
                continue;
            }
        };
        let mut payload_ok = 0usize;
        let mut group_ok = 0usize;
        for row in &meta.rows {
            if gcm_decrypt(&key, &row.nonce, &row.ciphertext).is_ok() {
                payload_ok += 1;
            }
            if decrypt_group_path(&key, &row.group).is_ok() {
                group_ok += 1;
            }
        }
        let blob_ok = meta
            .blob
            .as_ref()
            .map(|b| gcm_decrypt(&key, &b.nonce, &b.ciphertext).is_ok());
        println!(
            "{path}: payload {payload_ok}/{total} decrypt, group {group_ok}/{total} decrypt{} \
             => {}",
            match blob_ok {
                Some(true) => ", blob decrypts",
                Some(false) => ", blob does NOT decrypt",
                None => "",
            },
            if payload_ok == total && group_ok == total && blob_ok != Some(false) {
                "MATCH (server state is under this password)"
            } else if payload_ok == 0 && group_ok == 0 && blob_ok == Some(false) {
                "no match (server state is under a different password)"
            } else {
                "partial (mixed state; some parts use another key)"
            }
        );
    }
}

/// Derives the vault-id salt from the meta file name when it looks like
/// `<vaultId>.meta`, otherwise falls back to the file stem.
fn path_base_vault_id(path: &str) -> String {
    let name = path
        .rsplit(['/', '\\'])
        .next()
        .unwrap_or(path)
        .to_string();
    if let Some(stem) = name.strip_suffix(".meta") {
        stem.to_string()
    } else {
        name
    }
}
