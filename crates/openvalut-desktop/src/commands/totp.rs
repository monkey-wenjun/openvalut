//! TOTP generation for an entry's `OTPAuth` field.

use openvalut_core::{generate_totp, parse_otp_auth, FIELD_OTP};
use serde::Serialize;
use tauri::State;

use crate::state::AppState;

const OTP_COMPAT_KEYS: &[&str] = &["otp", "TOTP Seed", "TOTP Settings"];

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct TotpDto {
    pub present: bool,
    pub code: Option<String>,
    pub remaining: Option<u64>,
    pub period: Option<u64>,
}

#[tauri::command]
pub fn totp_for_entry(state: State<'_, AppState>, uuid: String) -> Result<TotpDto, String> {
    let guard = state.vault.read().unwrap();
    let handle = guard.as_ref().ok_or("密码库未解锁")?;
    let vault = handle.vault.lock().unwrap();
    let entry = vault
        .entries()
        .into_iter()
        .find(|e| e.uuid == uuid)
        .ok_or_else(|| "条目不存在".to_string())?;

    let raw = entry
        .custom
        .iter()
        .find(|(k, _)| k == FIELD_OTP || OTP_COMPAT_KEYS.contains(&k.as_str()))
        .map(|(_, v)| v.clone());
    let Some(raw) = raw else {
        return Ok(TotpDto {
            present: false,
            code: None,
            remaining: None,
            period: None,
        });
    };

    let otp = parse_otp_auth(&raw)
        .map_err(|e| format!("解析验证码配置失败: {e}"))?;
    let (code, remaining, period) = generate_totp(&otp, None).map_err(|e| e.to_string())?;
    Ok(TotpDto {
        present: true,
        code: Some(code),
        remaining: Some(remaining),
        period: Some(period),
    })
}
