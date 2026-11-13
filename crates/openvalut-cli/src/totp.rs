//! TOTP parsing and code generation, mirroring the app's `otpauth` handling:
//! an `otpauth://` URI, a KeeOTP-style query string, or a bare base32 secret.
use data_encoding::BASE32_NOPAD;
use hmac::{Hmac, Mac};
use sha1::Sha1;
use sha2::{Sha256, Sha512};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TotpAlgorithm {
    Sha1,
    Sha256,
    Sha512,
}

#[derive(Debug, Clone)]
pub struct TotpConfig {
    pub secret: Vec<u8>,
    pub algorithm: TotpAlgorithm,
    pub digits: u32,
    pub period: u64,
}

/// Parses the value of the `OTPAuth` field.
pub fn parse_otp_auth(value: &str) -> Option<TotpConfig> {
    let value = value.trim();
    let uri = value
        .strip_prefix("otpauth://")
        .or_else(|| value.strip_prefix("otpauth:"));
    if let Some(rest) = uri {
        return parse_otpauth_uri(rest);
    }
    if value.contains("key=") {
        return parse_keeotp(value);
    }
    let secret = decode_base32(value)?;
    Some(TotpConfig {
        secret,
        algorithm: TotpAlgorithm::Sha1,
        digits: 6,
        period: 30,
    })
}

fn parse_otpauth_uri(rest: &str) -> Option<TotpConfig> {
    let query = rest.split('?').nth(1)?;
    let params = parse_query(query);
    let secret = decode_base32(params.get("secret")?)?;
    Some(TotpConfig {
        secret,
        algorithm: algorithm_for(params.get("algorithm").map(String::as_str)),
        digits: params
            .get("digits")
            .and_then(|d| d.parse().ok())
            .unwrap_or(6),
        period: params
            .get("period")
            .and_then(|p| p.parse().ok())
            .unwrap_or(30),
    })
}

/// KeeOTP format: `key={base32Key}&size=12&step=33&type=Totp&counter=3`.
fn parse_keeotp(value: &str) -> Option<TotpConfig> {
    let params = parse_query(value);
    let secret = decode_base32(params.get("key")?)?;
    Some(TotpConfig {
        secret,
        algorithm: TotpAlgorithm::Sha1,
        digits: params.get("size").and_then(|d| d.parse().ok()).unwrap_or(6),
        period: params
            .get("step")
            .and_then(|p| p.parse().ok())
            .unwrap_or(30),
    })
}

fn parse_query(query: &str) -> std::collections::HashMap<String, String> {
    query
        .split('&')
        .filter_map(|pair| {
            let (k, v) = pair.split_once('=')?;
            Some((percent_decode(k).to_string(), percent_decode(v).to_string()))
        })
        .collect()
}

fn percent_decode(s: &str) -> String {
    let bytes = s.as_bytes();
    let mut out = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'%' && i + 2 < bytes.len() {
            if let Ok(b) = u8::from_str_radix(&s[i + 1..i + 3], 16) {
                out.push(b);
                i += 3;
                continue;
            }
        }
        out.push(bytes[i]);
        i += 1;
    }
    String::from_utf8_lossy(&out).into_owned()
}

fn algorithm_for(s: Option<&str>) -> TotpAlgorithm {
    match s {
        Some("SHA256") => TotpAlgorithm::Sha256,
        Some("SHA512") => TotpAlgorithm::Sha512,
        _ => TotpAlgorithm::Sha1,
    }
}

/// Lenient base32 decoding: uppercase, drop invalid characters, ignore
/// padding, like the app's base32 helper.
fn decode_base32(s: &str) -> Option<Vec<u8>> {
    let cleaned: String = s
        .chars()
        .filter(|c| c.is_ascii_alphanumeric())
        .map(|c| c.to_ascii_uppercase())
        .collect();
    if cleaned.is_empty() {
        return None;
    }
    BASE32_NOPAD.decode(cleaned.as_bytes()).ok()
}

/// Generates the current TOTP code and remaining seconds for a unix timestamp.
pub fn generate(config: &TotpConfig, now_unix: u64) -> (String, u64) {
    let counter = now_unix / config.period;
    let code = hotp(&config.secret, counter, config.algorithm, config.digits);
    let remaining = config.period - (now_unix % config.period);
    (code, remaining)
}

fn hotp(secret: &[u8], counter: u64, algorithm: TotpAlgorithm, digits: u32) -> String {
    let msg = counter.to_be_bytes();
    let mac: Vec<u8> = match algorithm {
        TotpAlgorithm::Sha1 => {
            let mut m = Hmac::<Sha1>::new_from_slice(secret).expect("hmac accepts any key");
            m.update(&msg);
            m.finalize().into_bytes().to_vec()
        }
        TotpAlgorithm::Sha256 => {
            let mut m = Hmac::<Sha256>::new_from_slice(secret).expect("hmac accepts any key");
            m.update(&msg);
            m.finalize().into_bytes().to_vec()
        }
        TotpAlgorithm::Sha512 => {
            let mut m = Hmac::<Sha512>::new_from_slice(secret).expect("hmac accepts any key");
            m.update(&msg);
            m.finalize().into_bytes().to_vec()
        }
    };
    let offset = (mac[mac.len() - 1] & 0x0f) as usize;
    let bin = ((mac[offset] & 0x7f) as u32) << 24
        | (mac[offset + 1] as u32) << 16
        | (mac[offset + 2] as u32) << 8
        | mac[offset + 3] as u32;
    let code = bin % 10u32.pow(digits);
    format!("{:0width$}", code, width = digits as usize)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_otpauth_uri() {
        let cfg = parse_otp_auth("otpauth://totp/GitHub?secret=JBSWY3DPEHPK3PXP&issuer=GitHub")
            .expect("uri");
        assert_eq!(cfg.secret, b"Hello!\xde\xad\xbe\xef");
        assert_eq!(cfg.digits, 6);
        assert_eq!(cfg.period, 30);
        assert_eq!(cfg.algorithm, TotpAlgorithm::Sha1);
    }

    #[test]
    fn parses_keeotp_and_bare_secret() {
        let cfg = parse_otp_auth("key=JBSWY3DPEHPK3PXP&size=8&step=60").expect("keeotp");
        assert_eq!(cfg.digits, 8);
        assert_eq!(cfg.period, 60);
        let bare = parse_otp_auth("jbswy3dpehpk3pxp").expect("bare");
        assert_eq!(bare.secret, cfg.secret);
    }

    #[test]
    fn computes_known_totp_vector() {
        // RFC 6238 test vector: SHA1, 8 digits, secret "12345678901234567890".
        let cfg = TotpConfig {
            secret: b"12345678901234567890".to_vec(),
            algorithm: TotpAlgorithm::Sha1,
            digits: 8,
            period: 30,
        };
        // T = 59 -> counter 1
        let (code, _) = generate(&cfg, 59);
        assert_eq!(code, "94287082");
    }
}
