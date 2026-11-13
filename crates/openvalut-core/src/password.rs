//! Secure password generation.

use rand::Rng;

use crate::error::{Error, Result};

const LOWERCASE: &[u8] = b"abcdefghijklmnopqrstuvwxyz";
const UPPERCASE: &[u8] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ";
const DIGITS: &[u8] = b"0123456789";
const SYMBOLS: &[u8] = b"!@#$%^&*()-_=+[]{}|;:,.<>?";

/// Generate a random password.
///
/// At least one character from each enabled character class is guaranteed.
pub fn generate_password(
    length: usize,
    include_uppercase: bool,
    include_digits: bool,
    include_symbols: bool,
) -> Result<String> {
    if length < 4 {
        return Err(Error::InvalidArgument(
            "password length must be at least 4".into(),
        ));
    }

    let mut charset: Vec<u8> = Vec::from(LOWERCASE);
    let mut required: Vec<u8> = Vec::new();

    required.push(random_char(LOWERCASE));
    if include_uppercase {
        charset.extend_from_slice(UPPERCASE);
        required.push(random_char(UPPERCASE));
    }
    if include_digits {
        charset.extend_from_slice(DIGITS);
        required.push(random_char(DIGITS));
    }
    if include_symbols {
        charset.extend_from_slice(SYMBOLS);
        required.push(random_char(SYMBOLS));
    }

    if length < required.len() {
        return Err(Error::InvalidArgument(format!(
            "password length {} is too short for required character classes",
            length
        )));
    }

    let required_len = required.len();
    let mut password: Vec<u8> = required;
    password.extend((required_len..length).map(|_| random_char(&charset)));

    // Shuffle so the guaranteed characters are not always at the start.
    shuffle(&mut password);

    Ok(String::from_utf8(password).expect("charset is ascii"))
}

fn random_char(charset: &[u8]) -> u8 {
    let idx = rand::thread_rng().gen_range(0..charset.len());
    charset[idx]
}

fn shuffle(data: &mut [u8]) {
    let mut rng = rand::thread_rng();
    for i in (1..data.len()).rev() {
        let j = rng.gen_range(0..=i);
        data.swap(i, j);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn generate_all_classes() {
        let pw = generate_password(16, true, true, true).unwrap();
        assert_eq!(pw.len(), 16);
        assert!(pw.chars().any(|c| LOWERCASE.contains(&(c as u8))));
        assert!(pw.chars().any(|c| UPPERCASE.contains(&(c as u8))));
        assert!(pw.chars().any(|c| DIGITS.contains(&(c as u8))));
        assert!(pw.chars().any(|c| SYMBOLS.contains(&(c as u8))));
    }

    #[test]
    fn length_too_short_fails() {
        assert!(generate_password(2, true, true, true).is_err());
    }
}
