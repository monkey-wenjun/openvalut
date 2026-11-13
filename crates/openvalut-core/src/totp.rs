//! TOTP generation compatible with KeePass / KeePassXC.
//!
//! Supports:
//!
//! * `otpauth://totp/...?secret=...`
//! * KeeOTP query strings (`key=...&step=...&size=...`)
//! * Bare base32 secrets

use data_encoding::BASE32;
use hmac::{Hmac, Mac};
use sha1::Sha1;
use sha2::{Sha256, Sha512};
use std::time::{SystemTime, UNIX_EPOCH};

use crate::error::{Error, Result};

type HmacSha1 = Hmac<Sha1>;
type HmacSha256 = Hmac<Sha256>;
type HmacSha512 = Hmac<Sha512>;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Algorithm {
    #[default]
    Sha1,
    Sha256,
    Sha512,
}

impl Algorithm {
    fn from_str(s: &str) -> Option<Self> {
        match s.to_uppercase().as_str() {
            "SHA1" => Some(Algorithm::Sha1),
            "SHA256" => Some(Algorithm::Sha256),
            "SHA512" => Some(Algorithm::Sha512),
            _ => None,
        }
    }
}

/// Parsed TOTP configuration.
#[derive(Debug, Clone)]
pub struct OtpAuth {
    pub label: String,
    pub secret: Vec<u8>,
    pub algorithm: Algorithm,
    pub digits: u32,
    pub period: u64,
}

impl Default for OtpAuth {
    fn default() -> Self {
        Self {
            label: String::new(),
            secret: Vec::new(),
            algorithm: Algorithm::default(),
            digits: 6,
            period: 30,
        }
    }
}

/// Parse a TOTP configuration from various common formats.
pub fn parse_otp_auth(value: &str) -> Result<OtpAuth> {
    let value = value.trim();
    if value.is_empty() {
        return Err(Error::InvalidArgument("empty otp value".into()));
    }

    if let Some(rest) = value.strip_prefix("otpauth://totp/") {
        return parse_otpauth_uri(rest);
    }

    if value.contains('=') {
        return parse_keepsotp_query(value);
    }

    // Bare base32 secret.
    let secret = decode_base32_secret(value)?;
    Ok(OtpAuth {
        secret,
        ..Default::default()
    })
}

fn parse_otpauth_uri(rest: &str) -> Result<OtpAuth> {
    let url = format!("otpauth://totp/{}", rest);
    let parsed = url::Url::parse(&url)
        .map_err(|e| Error::InvalidArgument(format!("bad otpauth uri: {e}")))?;

    let label = url_decode(parsed.path().trim_start_matches('/').to_string());
    let query: std::collections::HashMap<String, String> = parsed
        .query_pairs()
        .map(|(k, v)| (k.into_owned(), v.into_owned()))
        .collect();

    let secret = query
        .get("secret")
        .ok_or_else(|| Error::InvalidArgument("otpauth uri missing secret".into()))?;

    Ok(OtpAuth {
        label,
        secret: decode_base32_secret(secret)?,
        algorithm: query
            .get("algorithm")
            .and_then(|a| Algorithm::from_str(a))
            .unwrap_or_default(),
        digits: query
            .get("digits")
            .and_then(|d| d.parse().ok())
            .unwrap_or(6),
        period: query
            .get("period")
            .and_then(|p| p.parse().ok())
            .unwrap_or(30),
    })
}

fn parse_keepsotp_query(value: &str) -> Result<OtpAuth> {
    let mut secret: Option<String> = None;
    let mut step = 30u64;
    let mut size = 6u32;

    for part in value.split('&') {
        let mut kv = part.splitn(2, '=');
        let key = kv.next().unwrap_or("");
        let val = kv.next().unwrap_or("");
        match key {
            "key" | "secret" => secret = Some(val.to_string()),
            "step" | "period" => step = val.parse().unwrap_or(30),
            "size" | "digits" => size = val.parse().unwrap_or(6),
            _ => {}
        }
    }

    let secret = secret.ok_or_else(|| Error::InvalidArgument("keeotp query missing key".into()))?;
    Ok(OtpAuth {
        secret: decode_base32_secret(&secret)?,
        digits: size,
        period: step,
        ..Default::default()
    })
}

fn decode_base32_secret(secret: &str) -> Result<Vec<u8>> {
    let cleaned: String = secret
        .chars()
        .filter(|c| c.is_ascii_alphanumeric())
        .collect();
    BASE32
        .decode(cleaned.to_uppercase().as_bytes())
        .map_err(|e| Error::InvalidArgument(format!("invalid base32 secret: {e}")))
}

fn url_decode(s: String) -> String {
    percent_encoding::percent_decode_str(&s)
        .decode_utf8_lossy()
        .into_owned()
}

/// Generate a TOTP code for the given configuration.
///
/// Returns `(code, remaining_seconds, period)`.
pub fn generate_totp(auth: &OtpAuth, now: Option<u64>) -> Result<(String, u64, u64)> {
    let now = now.unwrap_or_else(|| {
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs()
    });

    let counter = now / auth.period;
    let remaining = auth.period - (now % auth.period);

    let code = match auth.algorithm {
        Algorithm::Sha1 => hotp::<HmacSha1>(&auth.secret, counter, auth.digits)?,
        Algorithm::Sha256 => hotp::<HmacSha256>(&auth.secret, counter, auth.digits)?,
        Algorithm::Sha512 => hotp::<HmacSha512>(&auth.secret, counter, auth.digits)?,
    };

    Ok((code, remaining, auth.period))
}

fn hotp<M: Mac + KeyInit>(secret: &[u8], counter: u64, digits: u32) -> Result<String> {
    let mut mac = <M as Mac>::new_from_slice(secret)
        .map_err(|e| Error::Crypto(format!("invalid hmac key: {e}")))?;
    mac.update(&counter.to_be_bytes());
    let result = mac.finalize().into_bytes();
    let hash = result.as_slice();

    let offset = (hash[hash.len() - 1] & 0x0f) as usize;
    let binary = ((hash[offset] as u32 & 0x7f) << 24)
        | ((hash[offset + 1] as u32) << 16)
        | ((hash[offset + 2] as u32) << 8)
        | (hash[offset + 3] as u32);

    let code = binary % 10u32.pow(digits);
    Ok(format!("{:0width$}", code, width = digits as usize))
}

use hmac::digest::KeyInit;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_otpauth_uri() {
        let auth = parse_otp_auth("otpauth://totp/GitHub:alice?secret=JBSWY3DPEHPK3PXP&algorithm=SHA256&digits=8&period=60").unwrap();
        assert_eq!(auth.label, "GitHub:alice");
        assert_eq!(auth.algorithm, Algorithm::Sha256);
        assert_eq!(auth.digits, 8);
        assert_eq!(auth.period, 60);
        assert!(!auth.secret.is_empty());
    }

    #[test]
    fn test_parse_bare_secret() {
        let auth = parse_otp_auth("JBSWY3DPEHPK3PXP").unwrap();
        assert_eq!(auth.digits, 6);
        assert_eq!(auth.period, 30);
        assert_eq!(auth.algorithm, Algorithm::Sha1);
    }

    #[test]
    fn test_rfc6238_vector_sha1() {
        // Known RFC 6238 test vector for SHA1 at 1234567890.
        let auth = OtpAuth {
            secret: decode_base32_secret("GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ").unwrap(),
            algorithm: Algorithm::Sha1,
            digits: 8,
            period: 30,
            ..Default::default()
        };
        let (code, _, _) = generate_totp(&auth, Some(1234567890)).unwrap();
        assert_eq!(code, "89005924");
    }
}
