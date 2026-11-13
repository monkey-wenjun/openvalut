//! Password generation for the built-in generator view.

#[tauri::command]
pub fn password_generate(
    length: Option<u8>,
    uppercase: Option<bool>,
    digits: Option<bool>,
    symbols: Option<bool>,
) -> Result<String, String> {
    let length = length.unwrap_or(20) as usize;
    openvalut_core::generate_password(
        length,
        uppercase.unwrap_or(true),
        digits.unwrap_or(true),
        symbols.unwrap_or(true),
    )
    .map_err(|e| e.to_string())
}

/// zxcvbn score (0-4) for the registration password-strength bar.
#[tauri::command]
pub fn password_strength(password: String, user_inputs: Option<Vec<String>>) -> u8 {
    if password.is_empty() {
        return 0;
    }
    let user_inputs = user_inputs.unwrap_or_default();
    let inputs: Vec<&str> = user_inputs.iter().map(|s| s.as_str()).collect();
    u8::from(zxcvbn::zxcvbn(&password, &inputs).score())
}
