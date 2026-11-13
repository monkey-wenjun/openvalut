//! Minimal software WebAuthn authenticator (ES256 / P-256, `none` attestation).
//!
//! Ported from the original Dart authenticator (legacy host removed).
//! Credentials are stored in KDBX entries via KeePassXC-compatible custom
//! fields; the authenticator is stateless.

use base64::Engine;
use openvalut_core::kdbx::Entry;
use p256::ecdsa::{
    signature::{Signer, Verifier},
    Signature as EcdsaSig, SigningKey, VerifyingKey,
};
use p256::elliptic_curve::Generate;
use p256::pkcs8::{DecodePrivateKey, EncodePrivateKey, LineEnding};
use sha2::{Digest, Sha256};

pub const FIELD_CREDENTIAL_ID: &str = "KPEX_PASSKEY_CREDENTIAL_ID";
pub const FIELD_PRIVATE_KEY_PEM: &str = "KPEX_PASSKEY_PRIVATE_KEY_PEM";
pub const FIELD_USER_HANDLE: &str = "KPEX_PASSKEY_USER_HANDLE";
pub const FIELD_RELYING_PARTY: &str = "KPEX_PASSKEY_RELYING_PARTY";
pub const FIELD_USERNAME: &str = "KPEX_PASSKEY_USERNAME";
pub const FIELD_FLAG_BE: &str = "KPEX_PASSKEY_FLAG_BE";
pub const FIELD_FLAG_BS: &str = "KPEX_PASSKEY_FLAG_BS";

pub const LEGACY_USER_ID: &str = "KPEX_PASSKEY_GENERATED_USER_ID";
pub const LEGACY_USERNAME: &str = "KPXC_PASSKEY_USERNAME";

/// A passkey credential as stored in a KDBX entry.
#[derive(Debug, Clone)]
pub struct PasskeyEntry {
    pub credential_id: Vec<u8>,
    pub private_key_pem: String,
    pub relying_party: String,
    pub user_handle: Option<Vec<u8>>,
    pub username: Option<String>,
    pub flag_be: bool,
    pub flag_bs: bool,
}

impl PasskeyEntry {
    pub fn credential_id_b64url(&self) -> String {
        base64_url_encode(&self.credential_id)
    }

    pub fn from_kdbx(entry: &Entry) -> Option<Self> {
        let custom = &entry.custom;
        let cid = get_custom(custom, FIELD_CREDENTIAL_ID)?;
        let pem = get_custom(custom, FIELD_PRIVATE_KEY_PEM)?;
        let rp = get_custom(custom, FIELD_RELYING_PARTY)?;
        let cid_bytes = base64_url_decode(&cid)?;
        let user_handle = get_custom(custom, FIELD_USER_HANDLE)
            .or_else(|| get_custom(custom, LEGACY_USER_ID))
            .and_then(|v| base64_url_decode(&v));
        let username =
            get_custom(custom, FIELD_USERNAME).or_else(|| get_custom(custom, LEGACY_USERNAME));
        Some(Self {
            credential_id: cid_bytes,
            private_key_pem: pem.clone(),
            relying_party: rp.clone(),
            user_handle,
            username,
            flag_be: flag(custom, FIELD_FLAG_BE, true),
            flag_bs: flag(custom, FIELD_FLAG_BS, true),
        })
    }
}

fn get_custom(custom: &[(String, String)], key: &str) -> Option<String> {
    custom
        .iter()
        .find(|(k, _)| k == key)
        .map(|(_, v)| v.clone())
}

fn flag(custom: &[(String, String)], key: &str, default: bool) -> bool {
    match get_custom(custom, key) {
        Some(v) => v == "1" || v.eq_ignore_ascii_case("true"),
        None => default,
    }
}

pub fn base64_url_encode(data: &[u8]) -> String {
    base64::engine::general_purpose::URL_SAFE_NO_PAD.encode(data)
}

pub fn base64_url_decode(data: &str) -> Option<Vec<u8>> {
    let padded = data.to_string() + &"=".repeat((4 - data.len() % 4) % 4);
    base64::engine::general_purpose::URL_SAFE
        .decode(padded.as_bytes())
        .ok()
}

fn sha256(data: &[u8]) -> [u8; 32] {
    let mut h = Sha256::new();
    h.update(data);
    h.finalize().into()
}

/// A fresh P-256 key pair (PKCS#8 PEM + uncompressed point).
pub struct KeyPair {
    pub private_key_pem: String,
    pub public_key_bytes: Vec<u8>,
}

pub fn generate_key_pair() -> KeyPair {
    let sk = SigningKey::generate();
    let pem = sk
        .to_pkcs8_pem(LineEnding::LF)
        .expect("pkcs8 encoding of P-256 key")
        .to_string();
    let public_key_bytes = sk.verifying_key().to_sec1_point(false).as_bytes().to_vec();
    KeyPair {
        private_key_pem: pem,
        public_key_bytes,
    }
}

pub fn sign_sha256(private_key_pem: &str, data: &[u8]) -> Vec<u8> {
    let sk = SigningKey::from_pkcs8_pem(private_key_pem).expect("valid pkcs8 private key");
    let sig: EcdsaSig = sk.sign(data);
    sig.to_bytes().to_vec()
}

/// Verifies an ES256 signature over `data` with an uncompressed point.
#[allow(dead_code)]
pub fn verify_sha256(public_key_bytes: &[u8], data: &[u8], sig: &[u8]) -> bool {
    let Ok(vk) = VerifyingKey::from_sec1_bytes(public_key_bytes) else {
        return false;
    };
    let sig = EcdsaSig::from_slice(sig).ok();
    let Some(sig) = sig else { return false };
    vk.verify(data, &sig).is_ok()
}

// ---------------------------------------------------------------------------
// CBOR (subset) encoder sufficient for WebAuthn `none` attestation objects.
// ---------------------------------------------------------------------------

pub enum Cbor {
    Int(i64),
    Str(String),
    Bytes(Vec<u8>),
    Bool(bool),
    Null,
    Array(Vec<Cbor>),
    Map(Vec<(Cbor, Cbor)>),
}

impl Cbor {
    pub fn encode(&self, out: &mut Vec<u8>) {
        match self {
            Cbor::Int(v) => write_int(out, *v),
            Cbor::Str(s) => {
                write_head(out, 0x60, s.len());
                out.extend_from_slice(s.as_bytes());
            }
            Cbor::Bytes(b) => {
                write_head(out, 0x40, b.len());
                out.extend_from_slice(b);
            }
            Cbor::Bool(true) => out.push(0xF5),
            Cbor::Bool(false) => out.push(0xF4),
            Cbor::Null => out.push(0xF6),
            Cbor::Array(items) => {
                write_head(out, 0x80, items.len());
                for i in items {
                    i.encode(out);
                }
            }
            Cbor::Map(entries) => {
                write_head(out, 0xA0, entries.len());
                for (k, v) in entries {
                    k.encode(out);
                    v.encode(out);
                }
            }
        }
    }

    pub fn to_bytes(&self) -> Vec<u8> {
        let mut out = Vec::new();
        self.encode(&mut out);
        out
    }
}

fn write_int(out: &mut Vec<u8>, value: i64) {
    if value < 0 {
        write_head(out, 0x20, (-1 - value) as usize);
    } else {
        write_head(out, 0x00, value as usize);
    }
}

fn write_head(out: &mut Vec<u8>, major: u8, value: usize) {
    if value < 24 {
        out.push(major | value as u8);
    } else if value < 256 {
        out.push(major | 24);
        out.push(value as u8);
    } else if value < 65536 {
        out.push(major | 25);
        out.extend_from_slice(&(value as u16).to_be_bytes());
    } else {
        out.push(major | 26);
        out.extend_from_slice(&(value as u32).to_be_bytes());
    }
}

// ---------------------------------------------------------------------------
// Authenticator
// ---------------------------------------------------------------------------

/// Data returned by `navigator.credentials.create()`.
pub struct AttestationResponse {
    pub attestation_object: Vec<u8>,
    pub client_data_json: Vec<u8>,
    pub raw_id: Vec<u8>,
}

impl AttestationResponse {
    pub fn to_json(&self) -> serde_json::Value {
        serde_json::json!({
            "id": base64_url_encode(&self.raw_id),
            "rawId": base64_url_encode(&self.raw_id),
            "response": {
                "clientDataJSON": base64_url_encode(&self.client_data_json),
                "attestationObject": base64_url_encode(&self.attestation_object),
                "transports": ["internal"],
            },
            "type": "public-key",
            "authenticatorAttachment": "platform",
        })
    }
}

/// Data returned by `navigator.credentials.get()`.
pub struct AssertionResponse {
    pub authenticator_data: Vec<u8>,
    pub client_data_json: Vec<u8>,
    pub signature: Vec<u8>,
    pub raw_id: Vec<u8>,
    pub user_handle: Option<Vec<u8>>,
}

impl AssertionResponse {
    pub fn to_json(&self) -> serde_json::Value {
        let mut response = serde_json::Map::new();
        response.insert(
            "clientDataJSON".into(),
            serde_json::Value::String(base64_url_encode(&self.client_data_json)),
        );
        response.insert(
            "authenticatorData".into(),
            serde_json::Value::String(base64_url_encode(&self.authenticator_data)),
        );
        response.insert(
            "signature".into(),
            serde_json::Value::String(base64_url_encode(&self.signature)),
        );
        if let Some(uh) = &self.user_handle {
            response.insert(
                "userHandle".into(),
                serde_json::Value::String(base64_url_encode(uh)),
            );
        }
        serde_json::json!({
            "id": base64_url_encode(&self.raw_id),
            "rawId": base64_url_encode(&self.raw_id),
            "response": serde_json::Value::Object(response),
            "type": "public-key",
            "authenticatorAttachment": "platform",
        })
    }
}

pub struct CreateResult {
    pub entry: PasskeyEntry,
    pub response: AttestationResponse,
}

/// Registration options (`publicKey` of `creationOptions`).
pub struct CreationOptions {
    pub rp_id: String,
    pub rp_name: String,
    pub user_id: Vec<u8>,
    pub user_name: String,
    pub user_display_name: String,
    pub challenge: Vec<u8>,
}

/// Assertion options (`publicKey` of `requestOptions`).
pub struct RequestOptions {
    pub challenge: Vec<u8>,
    pub rp_id: Option<String>,
    pub allow_credential_ids: Vec<Vec<u8>>,
}

pub fn create(options: &CreationOptions) -> CreateResult {
    let credential_id = random_bytes(32);
    let key_pair = generate_key_pair();
    let client_data_json = client_data_json(&options.challenge, &options.rp_id, "webauthn.create");
    let auth_data = build_auth_data(
        &options.rp_id,
        Some(&credential_id),
        Some(&key_pair.public_key_bytes),
        0,
        true,
        true,
    );
    let attestation_object = none_attestation_object(&auth_data);
    let entry = PasskeyEntry {
        credential_id,
        private_key_pem: key_pair.private_key_pem,
        relying_party: options.rp_id.clone(),
        user_handle: Some(options.user_id.clone()),
        username: Some(options.user_name.clone()),
        flag_be: true,
        flag_bs: true,
    };
    let response = AttestationResponse {
        attestation_object,
        client_data_json,
        raw_id: entry.credential_id.clone(),
    };
    CreateResult { entry, response }
}

pub fn get(entry: &PasskeyEntry, options: &RequestOptions) -> AssertionResponse {
    let rp_id = options
        .rp_id
        .clone()
        .unwrap_or_else(|| entry.relying_party.clone());
    let client_data_json = client_data_json(&options.challenge, &rp_id, "webauthn.get");
    let client_data_hash = sha256(&client_data_json);
    let authenticator_data = build_auth_data(&rp_id, None, None, 0, true, entry.flag_bs);
    let mut signature_data = authenticator_data.clone();
    signature_data.extend_from_slice(&client_data_hash);
    let signature = sign_sha256(&entry.private_key_pem, &signature_data);
    AssertionResponse {
        authenticator_data,
        client_data_json,
        signature,
        raw_id: entry.credential_id.clone(),
        user_handle: entry.user_handle.clone(),
    }
}

fn random_bytes(n: usize) -> Vec<u8> {
    use rand::RngCore;
    let mut out = vec![0u8; n];
    rand::rngs::OsRng.fill_bytes(&mut out);
    out
}

fn client_data_json(challenge: &[u8], rp_id: &str, typ: &str) -> Vec<u8> {
    let origin = format!("https://{rp_id}");
    let mut keys = vec!["challenge", "crossOrigin", "origin", "type"];
    keys.sort_unstable();
    let mut parts = Vec::with_capacity(keys.len());
    for k in keys {
        let v = match k {
            "challenge" => format!("\"{}\"", base64_url_encode(challenge)),
            "crossOrigin" => "false".to_string(),
            "origin" => format!("\"{origin}\""),
            "type" => format!("\"{typ}\""),
            _ => unreachable!(),
        };
        parts.push(format!("\"{k}\":{v}"));
    }
    let joined = parts.join(",");
    format!("{{{joined}}}").into_bytes()
}

fn build_auth_data(
    rp_id: &str,
    credential_id: Option<&[u8]>,
    public_key: Option<&[u8]>,
    sign_count: u32,
    _uv: bool,
    flag_bs: bool,
) -> Vec<u8> {
    let rp_id_hash = sha256(rp_id.as_bytes());
    let mut flags = 0x01u8; // UP
    flags |= 0x04; // UV
    if flag_bs {
        flags |= 0x10; // BS
    }
    let has_cred = credential_id.is_some() && public_key.is_some();
    if has_cred {
        flags |= 0x08; // BE
        flags |= 0x40; // AT
    }
    let mut out = Vec::with_capacity(32 + 1 + 4);
    out.extend_from_slice(&rp_id_hash);
    out.push(flags);
    out.extend_from_slice(&sign_count.to_be_bytes());
    if let (Some(cid), Some(pk)) = (credential_id, public_key) {
        out.extend_from_slice(&[0u8; 16]); // AAGUID zero
        out.extend_from_slice(&(cid.len() as u16).to_be_bytes());
        out.extend_from_slice(cid);
        out.extend_from_slice(&cose_key(pk));
    }
    out
}

fn cose_key(uncompressed: &[u8]) -> Vec<u8> {
    if uncompressed.len() != 65 || uncompressed[0] != 0x04 {
        panic!("invalid P-256 public key");
    }
    let x = uncompressed[1..33].to_vec();
    let y = uncompressed[33..65].to_vec();
    Cbor::Map(vec![
        (Cbor::Int(1), Cbor::Int(2)),  // kty: EC
        (Cbor::Int(3), Cbor::Int(-7)), // alg: ES256
        (Cbor::Int(-1), Cbor::Int(1)), // crv: P-256
        (Cbor::Int(-2), Cbor::Bytes(x)),
        (Cbor::Int(-3), Cbor::Bytes(y)),
    ])
    .to_bytes()
}

fn none_attestation_object(auth_data: &[u8]) -> Vec<u8> {
    Cbor::Map(vec![
        (Cbor::Str("fmt".into()), Cbor::Str("none".into())),
        (Cbor::Str("attStmt".into()), Cbor::Map(Vec::new())),
        (
            Cbor::Str("authData".into()),
            Cbor::Bytes(auth_data.to_vec()),
        ),
    ])
    .to_bytes()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rfc6979_ecdsa_sign_verify_round_trip() {
        let kp = generate_key_pair();
        let data = b"hello webauthn";
        let sig = sign_sha256(&kp.private_key_pem, data);
        assert_eq!(sig.len(), 64);
        assert!(verify_sha256(&kp.public_key_bytes, data, &sig));
        assert!(!verify_sha256(&kp.public_key_bytes, b"tampered", &sig));
    }

    #[test]
    fn create_builds_none_attestation_and_pkcs8() {
        let options = CreationOptions {
            rp_id: "example.com".into(),
            rp_name: "Example".into(),
            user_id: vec![1u8; 8],
            user_name: "alice".into(),
            user_display_name: "Alice".into(),
            challenge: vec![2u8; 32],
        };
        let result = create(&options);
        let obj = result.response.attestation_object;
        assert!(obj.windows(4).any(|w| w == b"none"));
        let pem = result.entry.private_key_pem.trim();
        assert!(pem.starts_with("-----BEGIN ") && pem.ends_with("-----"));
        assert_eq!(result.entry.credential_id.len(), 32);
    }

    #[test]
    fn create_then_get_produces_assertion() {
        let options = CreationOptions {
            rp_id: "example.com".into(),
            rp_name: "Example".into(),
            user_id: vec![9u8; 8],
            user_name: "bob".into(),
            user_display_name: "Bob".into(),
            challenge: vec![3u8; 32],
        };
        let result = create(&options);
        let entry = result.entry;
        let request = RequestOptions {
            challenge: vec![4u8; 32],
            rp_id: Some("example.com".into()),
            allow_credential_ids: vec![entry.credential_id.clone()],
        };
        let assertion = get(&entry, &request);
        assert_eq!(assertion.signature.len(), 64);
        assert_eq!(assertion.authenticator_data.len(), 37); // sha256(32) + flags(1) + signCount(4)
        assert!(!assertion.client_data_json.is_empty());
    }
}
