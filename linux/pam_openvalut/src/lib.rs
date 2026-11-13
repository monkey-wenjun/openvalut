// Experimental PAM module for OpenValut TOTP verification on Linux.
//
// WARNING: PAM modules can lock you out of your system if misconfigured.
// Always keep a root shell open while testing, and configure a backup
// authentication method before enabling this in system-auth or sudo.
//
// This module expects the TOTP secret for the current machine to be stored in
//     ~/.openvalut/totp/<machine-id>.enc
// encrypted with a key derived from /etc/machine-id. The OpenValut app writes
// this file when the user sets up TOTP for the current computer.
//
// The intended PAM stack is:
//     auth required pam_unix.so ...
//     auth required pam_openvalut.so
//
// The module prompts for a TOTP code after pam_unix has verified the password.

use pamsm::{Pam, PamError, PamFlags, PamLibExt, PamMsgStyle, PamServiceModule};

const TOTP_DIR: &str = ".openvalut/totp";
const MACHINE_ID_PATH: &str = "/etc/machine-id";

fn machine_id() -> Option<String> {
    std::fs::read_to_string(MACHINE_ID_PATH)
        .ok()
        .map(|s| s.trim().to_string())
}

/// Resolves the home directory for a username from the passwd database.
///
/// `dirs::home_dir()` follows `$HOME`, which `sudo` rewrites to the target
/// user (usually `/root`) even before authentication completes. During a
/// `sudo` PAM conversation we must therefore look up the *invoking* user's
/// real home directory from `/etc/passwd` so the module reads the TOTP file
/// that belongs to the person running `sudo`.
fn user_home(user: &str) -> Option<std::path::PathBuf> {
    if user.is_empty() {
        return None;
    }
    let c_user = std::ffi::CString::new(user).ok()?;
    unsafe {
        let mut pwd: libc::passwd = std::mem::zeroed();
        let mut buf = vec![0u8; 4096];
        let mut result: *mut libc::passwd = std::ptr::null_mut();
        let rc = libc::getpwnam_r(
            c_user.as_ptr(),
            &mut pwd,
            buf.as_mut_ptr() as *mut libc::c_char,
            buf.len(),
            &mut result,
        );
        if rc != 0 || result.is_null() || pwd.pw_dir.is_null() {
            return None;
        }
        let home = std::ffi::CStr::from_ptr(pwd.pw_dir).to_str().ok()?;
        Some(std::path::PathBuf::from(home))
    }
}

fn totp_path(user: &str) -> Option<std::path::PathBuf> {
    let mid = machine_id()?;
    let home = user_home(user).or_else(dirs::home_dir)?;
    Some(home.join(TOTP_DIR).join(format!("{}.enc", mid)))
}

fn derive_key(machine_id: &str) -> [u8; 32] {
    use ring::digest;
    let salt = b"openvalut-pam-totp-v1";
    let mut ctx = digest::Context::new(&digest::SHA256);
    ctx.update(machine_id.as_bytes());
    ctx.update(salt);
    let mut out = [0u8; 32];
    out.copy_from_slice(ctx.finish().as_ref());
    out
}

fn decrypt_secret(ciphertext: &[u8], key: &[u8; 32]) -> Option<String> {
    use ring::aead::{Aad, AES_256_GCM, Nonce, UnboundKey};
    use ring::aead::LessSafeKey;
    if ciphertext.len() < 12 {
        return None;
    }
    let (nonce, sealed) = ciphertext.split_at(12);
    let nonce = Nonce::try_assume_unique_for_key(nonce).ok()?;
    let unbound = UnboundKey::new(&AES_256_GCM, key).ok()?;
    let key = LessSafeKey::new(unbound);
    let mut in_out = sealed.to_vec();
    let plaintext = key.open_in_place(nonce, Aad::empty(), &mut in_out).ok()?;
    String::from_utf8(plaintext.to_vec()).ok()
}

fn decode_base32(s: &str) -> Option<Vec<u8>> {
    const ALPHABET: &str = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
    let cleaned: String = s
        .chars()
        .filter(|c| c.is_ascii_alphanumeric())
        .map(|c| c.to_ascii_uppercase())
        .collect();
    if cleaned.is_empty() {
        return None;
    }
    let mut bits = String::with_capacity(cleaned.len() * 5);
    for c in cleaned.chars() {
        let idx = ALPHABET.find(c)? as u8;
        bits.push_str(&format!("{:05b}", idx));
    }
    let mut bytes = Vec::with_capacity(bits.len() / 8);
    for chunk in bits.as_bytes().chunks(8) {
        let s = std::str::from_utf8(chunk).ok()?;
        bytes.push(u8::from_str_radix(s, 2).ok()?);
    }
    Some(bytes)
}

fn hotp(secret: &[u8], counter: u64, digits: u32) -> String {
    use ring::hmac;
    let key = hmac::Key::new(hmac::HMAC_SHA1_FOR_LEGACY_USE_ONLY, secret);
    let tag = hmac::sign(&key, &counter.to_be_bytes());
    let mac = tag.as_ref();
    let offset = (mac[mac.len() - 1] & 0x0f) as usize;
    let bin = ((mac[offset] & 0x7f) as u32) << 24
        | (mac[offset + 1] as u32) << 16
        | (mac[offset + 2] as u32) << 8
        | mac[offset + 3] as u32;
    let code = bin % 10u32.pow(digits);
    format!("{:0width$}", code, width = digits as usize)
}

fn verify_totp(secret: &str, code: &str) -> bool {
    if code.len() != 6 {
        return false;
    }
    if code.parse::<u32>().is_err() {
        return false;
    }
    let bytes = match decode_base32(secret) {
        Some(b) => b,
        None => return false,
    };
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);
    let counter = now / 30;
    // Allow one step of clock skew in either direction.
    for c in counter.saturating_sub(1)..=counter + 1 {
        if hotp(&bytes, c, 6) == code {
            return true;
        }
    }
    false
}

struct OpenValutPam;

/// Prompts for and verifies the current TOTP code for the authenticated user.
/// Shared by both the `auth` and `account` stack entry points so the module can
/// be used as either a one-time password gate placed in `account` (runs on
/// every sudo even when the password timestamp is cached) or in `auth`.
fn check_totp(pam: &Pam) -> PamError {
    let user = match pam.get_user(None) {
        Ok(Some(u)) => u.to_str().unwrap_or("").to_string(),
        _ => return PamError::USER_UNKNOWN,
    };

    let path = match totp_path(&user) {
        Some(p) => p,
        None => return PamError::AUTHINFO_UNAVAIL,
    };

    if !path.exists() {
        // No TOTP configured for this machine; silently succeed so the
        // module is only enforced after setup.
        return PamError::SUCCESS;
    }

    let ciphertext = match std::fs::read(&path) {
        Ok(c) => c,
        Err(_) => return PamError::AUTHINFO_UNAVAIL,
    };

    let mid = match machine_id() {
        Some(m) => m,
        None => return PamError::AUTHINFO_UNAVAIL,
    };
    let key = derive_key(&mid);
    let secret = match decrypt_secret(&ciphertext, &key) {
        Some(s) => s,
        None => return PamError::AUTHINFO_UNAVAIL,
    };

    // Re-prompt up to three times so a single typo does not surface sudo's
    // generic account-failure text ("is your account locked?"). Only after the
    // last attempt is a clear, explicit message shown.
    const MAX_ATTEMPTS: u32 = 3;
    let mut attempts = 0;
    loop {
        attempts += 1;
        let code = match pam.conv(Some("请输入两步验证码："), PamMsgStyle::PROMPT_ECHO_OFF) {
            Ok(Some(r)) => r.to_str().unwrap_or("").to_string(),
            Ok(None) => return PamError::AUTH_ERR,
            Err(e) => return e,
        };
        if verify_totp(&secret, code.trim()) {
            return PamError::SUCCESS;
        }
        if attempts >= MAX_ATTEMPTS {
            let _ = pam.conv(
                Some("账户验证失败，请确认密码是否正确。"),
                PamMsgStyle::ERROR_MSG,
            );
            return PamError::AUTH_ERR;
        }
    }
}

impl PamServiceModule for OpenValutPam {
    fn authenticate(pam: Pam, _flags: PamFlags, _args: Vec<String>) -> PamError {
        check_totp(&pam)
    }

    fn setcred(_pam: Pam, _flags: PamFlags, _args: Vec<String>) -> PamError {
        PamError::SUCCESS
    }

    fn acct_mgmt(_pam: Pam, _flags: PamFlags, _args: Vec<String>) -> PamError {
        check_totp(&_pam)
    }
}

pamsm::pam_module!(OpenValutPam);
