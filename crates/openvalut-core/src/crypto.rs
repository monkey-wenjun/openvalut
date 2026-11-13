//! Cryptographic primitives used across OpenValut.
//!
//! All parameters are kept identical to the Go server and Dart client:
//!
//! * Argon2id: 64 MiB memory, 3 iterations, 4 lanes, 32-byte output, version 0x13.
//! * AES-256-GCM: random 12-byte nonce, 128-bit tag.
//! * X25519 envelope: `ephemeral_pub(32) || nonce(12) || ciphertext`, HKDF info
//!   `"openvalut-envelope-v1"`.
//! * Share key wrap: same primitives with HKDF info `"openvalut-share-v1"`.
//! * Request signature: HMAC-SHA256 over `METHOD\nPATH\nTIMESTAMP\nNONCE\nSHA256(body_hex)`.

use aes_gcm::{
    aead::{Aead, KeyInit, OsRng},
    Aes256Gcm, Nonce,
};
use argon2::{Argon2, Params, Version};
use hkdf::Hkdf;
use hmac::{Hmac, Mac};
use rand::RngCore;
use sha2::{Digest, Sha256};
use x25519_dalek::{PublicKey, StaticSecret};

use crate::error::{Error, Result};

pub const ARGON2_MEMORY_KIB: u32 = 64 * 1024; // 64 MiB
pub const ARGON2_ITERATIONS: u32 = 3;
pub const ARGON2_PARALLELISM: u32 = 4;
pub const ARGON2_OUTPUT_LEN: usize = 32;
pub const NONCE_LEN: usize = 12;
pub const X25519_PUBLIC_KEY_LEN: usize = 32;

const ENVELOPE_INFO: &[u8] = b"openvalut-envelope-v1";
const SHARE_INFO: &[u8] = b"openvalut-share-v1";

/// Derive a 32-byte key from `password` and `salt` using Argon2id.
///
/// Parameters match the Go/Dart implementations exactly.
pub fn derive_key_argon2id(password: &str, salt: &[u8]) -> Result<[u8; 32]> {
    let mut output = [0u8; 32];
    argon2_hash(
        password.as_bytes(),
        salt,
        argon2::Algorithm::Argon2id,
        Version::V0x13,
        ARGON2_MEMORY_KIB,
        ARGON2_ITERATIONS,
        ARGON2_PARALLELISM,
        &mut output,
    )?;
    Ok(output)
}

/// Flexible Argon2 hash suitable for KDBX key derivation.
///
/// `password` and `salt` may be arbitrary byte strings. `memory_kib` is the
/// memory cost in KiB, `iterations` the time cost, `parallelism` the number
/// of lanes, and `out` the output buffer.
#[allow(clippy::too_many_arguments)]
pub fn argon2_hash(
    password: &[u8],
    salt: &[u8],
    algorithm: argon2::Algorithm,
    version: Version,
    memory_kib: u32,
    iterations: u32,
    parallelism: u32,
    out: &mut [u8],
) -> Result<()> {
    let params = Params::new(memory_kib, iterations, parallelism, Some(out.len()))
        .map_err(|e| Error::Crypto(format!("invalid argon2 params: {e}")))?;

    let argon2 = Argon2::new(algorithm, version, params);
    argon2
        .hash_password_into(password, salt, out)
        .map_err(|e| Error::Crypto(format!("argon2 hash failed: {e}")))?;
    Ok(())
}

/// Encrypt `plaintext` with AES-256-GCM using a random 12-byte nonce.
///
/// Returns `(nonce, ciphertext)`.
pub fn aes_gcm_encrypt(key: &[u8; 32], plaintext: &[u8]) -> Result<(Vec<u8>, Vec<u8>)> {
    let cipher = Aes256Gcm::new_from_slice(key)
        .map_err(|e| Error::Crypto(format!("invalid aes key: {e}")))?;

    let mut nonce_bytes = [0u8; NONCE_LEN];
    OsRng.fill_bytes(&mut nonce_bytes);
    let nonce = Nonce::from_slice(&nonce_bytes);

    let ciphertext = cipher
        .encrypt(nonce, plaintext)
        .map_err(|e| Error::Crypto(format!("aes-gcm encrypt failed: {e}")))?;

    Ok((nonce_bytes.to_vec(), ciphertext))
}

/// Decrypt AES-256-GCM ciphertext.
pub fn aes_gcm_decrypt(key: &[u8; 32], nonce: &[u8], ciphertext: &[u8]) -> Result<Vec<u8>> {
    let cipher = Aes256Gcm::new_from_slice(key)
        .map_err(|e| Error::Crypto(format!("invalid aes key: {e}")))?;

    let nonce = Nonce::from_slice(nonce);
    cipher
        .decrypt(nonce, ciphertext)
        .map_err(|e| Error::Crypto(format!("aes-gcm decrypt failed: {e}")))
}

/// X25519 envelope encryption.
///
/// Output layout: `ephemeral_pub(32) || nonce(12) || aes_gcm_ciphertext`.
pub fn envelope_encrypt(recipient_public_key: &[u8; 32], plaintext: &[u8]) -> Result<Vec<u8>> {
    let recipient = PublicKey::from(*recipient_public_key);
    let ephemeral = StaticSecret::random_from_rng(OsRng);
    let ephemeral_public = PublicKey::from(&ephemeral);

    let shared = ephemeral.diffie_hellman(&recipient);
    let hkdf = Hkdf::<Sha256>::new(None, shared.as_bytes());
    let mut key = [0u8; 32];
    hkdf.expand(ENVELOPE_INFO, &mut key)
        .map_err(|e| Error::Crypto(format!("hkdf expand failed: {e}")))?;

    let (nonce, ciphertext) = aes_gcm_encrypt(&key, plaintext)?;

    let mut out = Vec::with_capacity(X25519_PUBLIC_KEY_LEN + NONCE_LEN + ciphertext.len());
    out.extend_from_slice(ephemeral_public.as_bytes());
    out.extend_from_slice(&nonce);
    out.extend_from_slice(&ciphertext);
    Ok(out)
}

/// X25519 envelope decryption.
pub fn envelope_decrypt(private_key: &[u8; 32], blob: &[u8]) -> Result<Vec<u8>> {
    if blob.len() < X25519_PUBLIC_KEY_LEN + NONCE_LEN {
        return Err(Error::Crypto("envelope too short".to_string()));
    }

    let secret = StaticSecret::from(*private_key);

    let mut ephemeral_pub = [0u8; X25519_PUBLIC_KEY_LEN];
    ephemeral_pub.copy_from_slice(&blob[..X25519_PUBLIC_KEY_LEN]);
    let ephemeral = PublicKey::from(ephemeral_pub);

    let nonce = &blob[X25519_PUBLIC_KEY_LEN..X25519_PUBLIC_KEY_LEN + NONCE_LEN];
    let ciphertext = &blob[X25519_PUBLIC_KEY_LEN + NONCE_LEN..];

    let shared = secret.diffie_hellman(&ephemeral);
    let hkdf = Hkdf::<Sha256>::new(None, shared.as_bytes());
    let mut key = [0u8; 32];
    hkdf.expand(ENVELOPE_INFO, &mut key)
        .map_err(|e| Error::Crypto(format!("hkdf expand failed: {e}")))?;

    aes_gcm_decrypt(&key, nonce, ciphertext)
}

/// Wrap a random `share_key` for a recipient using X25519 + HKDF + AES-GCM.
///
/// Output layout is identical to `envelope_encrypt`.
pub fn wrap_share_key(recipient_public_key: &[u8; 32], share_key: &[u8; 32]) -> Result<Vec<u8>> {
    let recipient = PublicKey::from(*recipient_public_key);
    let ephemeral = StaticSecret::random_from_rng(OsRng);
    let ephemeral_public = PublicKey::from(&ephemeral);

    let shared = ephemeral.diffie_hellman(&recipient);
    let hkdf = Hkdf::<Sha256>::new(None, shared.as_bytes());
    let mut key = [0u8; 32];
    hkdf.expand(SHARE_INFO, &mut key)
        .map_err(|e| Error::Crypto(format!("hkdf expand failed: {e}")))?;

    let (nonce, ciphertext) = aes_gcm_encrypt(&key, share_key)?;

    let mut out = Vec::with_capacity(X25519_PUBLIC_KEY_LEN + NONCE_LEN + ciphertext.len());
    out.extend_from_slice(ephemeral_public.as_bytes());
    out.extend_from_slice(&nonce);
    out.extend_from_slice(&ciphertext);
    Ok(out)
}

/// Unwrap a share key.
pub fn unwrap_share_key(private_key: &[u8; 32], blob: &[u8]) -> Result<[u8; 32]> {
    if blob.len() < X25519_PUBLIC_KEY_LEN + NONCE_LEN {
        return Err(Error::Crypto("wrapped share key too short".to_string()));
    }

    let secret = StaticSecret::from(*private_key);

    let mut ephemeral_pub = [0u8; X25519_PUBLIC_KEY_LEN];
    ephemeral_pub.copy_from_slice(&blob[..X25519_PUBLIC_KEY_LEN]);
    let ephemeral = PublicKey::from(ephemeral_pub);

    let nonce = &blob[X25519_PUBLIC_KEY_LEN..X25519_PUBLIC_KEY_LEN + NONCE_LEN];
    let ciphertext = &blob[X25519_PUBLIC_KEY_LEN + NONCE_LEN..];

    let shared = secret.diffie_hellman(&ephemeral);
    let hkdf = Hkdf::<Sha256>::new(None, shared.as_bytes());
    let mut key = [0u8; 32];
    hkdf.expand(SHARE_INFO, &mut key)
        .map_err(|e| Error::Crypto(format!("hkdf expand failed: {e}")))?;

    let plain = aes_gcm_decrypt(&key, nonce, ciphertext)?;
    if plain.len() != 32 {
        return Err(Error::Crypto(
            "unwrapped share key length mismatch".to_string(),
        ));
    }
    let mut out = [0u8; 32];
    out.copy_from_slice(&plain);
    Ok(out)
}

/// Sign an HTTP request using the user's 32-char UUID as the HMAC key.
///
/// The signed base string is:
/// `METHOD\nPATH\nTIMESTAMP\nNONCE\nHEX(SHA256(body))`
pub fn sign_request(
    user_id: &str,
    method: &str,
    path: &str,
    timestamp: &str,
    nonce: &str,
    body: &[u8],
) -> Result<String> {
    let body_hash = hex::encode(Sha256::digest(body));
    let base = format!(
        "{}\n{}\n{}\n{}\n{}",
        method, path, timestamp, nonce, body_hash
    );

    type HmacSha256 = Hmac<Sha256>;
    let mut mac = <HmacSha256 as Mac>::new_from_slice(user_id.as_bytes())
        .map_err(|e| Error::Crypto(format!("hmac key error: {e}")))?;
    mac.update(base.as_bytes());
    let result = mac.finalize();
    Ok(hex::encode(result.into_bytes()))
}

/// Verify a request signature.
pub fn verify_request_signature(
    user_id: &str,
    method: &str,
    path: &str,
    timestamp: &str,
    nonce: &str,
    body: &[u8],
    signature: &str,
) -> Result<()> {
    let expected = sign_request(user_id, method, path, timestamp, nonce, body)?;
    if expected.eq_ignore_ascii_case(signature) {
        Ok(())
    } else {
        Err(Error::Crypto("signature mismatch".to_string()))
    }
}

/// Generate a new random 16-byte ID and encode it as 32 lowercase hex chars.
pub fn generate_id() -> String {
    let mut bytes = [0u8; 16];
    OsRng.fill_bytes(&mut bytes);
    hex::encode(bytes)
}

/// Generate a new random X25519 key pair.
pub fn generate_x25519_keypair() -> ([u8; 32], [u8; 32]) {
    let secret = StaticSecret::random_from_rng(OsRng);
    let public = PublicKey::from(&secret);
    (secret.to_bytes(), *public.as_bytes())
}

/// Derive the X25519 public key for a 32-byte secret key.
///
/// Used by the server to recreate its transport-envelope identity from a
/// persisted private key between restarts (matching the Go `-key-file`).
pub fn x25519_public_from_secret(secret: &[u8; 32]) -> [u8; 32] {
    let public = PublicKey::from(&StaticSecret::from(*secret));
    *public.as_bytes()
}

/// Fill `dest` with cryptographically secure random bytes.
pub fn secure_random_bytes(dest: &mut [u8]) {
    OsRng.fill_bytes(dest);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_argon2id_derivation() {
        let key = derive_key_argon2id("master password", b"vault-id-salt").unwrap();
        assert_eq!(key.len(), 32);
        // Deterministic for same inputs.
        let key2 = derive_key_argon2id("master password", b"vault-id-salt").unwrap();
        assert_eq!(key, key2);
    }

    #[test]
    fn test_aes_gcm_round_trip() {
        let key = [42u8; 32];
        let plaintext = b"hello openvalut";
        let (nonce, ciphertext) = aes_gcm_encrypt(&key, plaintext).unwrap();
        assert_eq!(nonce.len(), NONCE_LEN);
        let decrypted = aes_gcm_decrypt(&key, &nonce, &ciphertext).unwrap();
        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn test_envelope_round_trip() {
        let (recipient_secret, recipient_public) = generate_x25519_keypair();
        let plaintext = b"secret payload";
        let blob = envelope_encrypt(&recipient_public, plaintext).unwrap();
        let decrypted = envelope_decrypt(&recipient_secret, &blob).unwrap();
        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn test_share_key_wrap_round_trip() {
        let (recipient_secret, recipient_public) = generate_x25519_keypair();
        let share_key = [7u8; 32];
        let blob = wrap_share_key(&recipient_public, &share_key).unwrap();
        let unwrapped = unwrap_share_key(&recipient_secret, &blob).unwrap();
        assert_eq!(unwrapped, share_key);
    }

    #[test]
    fn test_sign_request() {
        let sig = sign_request(
            "0123456789abcdef0123456789abcdef",
            "POST",
            "/api/vaults",
            "1234567890",
            "nonce123",
            b"{}",
        )
        .unwrap();
        assert_eq!(sig.len(), 64);
    }

    #[test]
    fn test_generate_id() {
        let id = generate_id();
        assert_eq!(id.len(), 32);
        assert!(id.chars().all(|c| c.is_ascii_hexdigit()));
    }
}
