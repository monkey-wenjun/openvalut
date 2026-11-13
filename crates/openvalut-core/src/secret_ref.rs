//! Secret reference parsing and resolution.
//!
//! Supports references of the form:
//!
//! * `ov://vault/entry/field`
//! * `op://vault/entry/field` (1Password compatibility)
//!
//! Standard fields: `title`, `username`, `password`, `url`, `notes`, `totp`.
//! AK/SK credentials add `access-key` (aliases `accesskey`, `ak`) and
//! `secret-key` (aliases `secretkey`, `sk`).

use crate::error::{Error, Result};
use crate::kdbx::{Entry, Vault};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SecretReferenceField {
    Title,
    Username,
    Password,
    Url,
    Notes,
    Totp,
    AccessKey,
    SecretKey,
}

impl SecretReferenceField {
    pub fn parse(s: &str) -> Option<Self> {
        match s.to_lowercase().as_str() {
            "title" => Some(Self::Title),
            "username" | "user" => Some(Self::Username),
            "password" | "pw" => Some(Self::Password),
            "url" => Some(Self::Url),
            "notes" | "note" => Some(Self::Notes),
            "totp" | "otp" => Some(Self::Totp),
            "access-key" | "accesskey" | "ak" => Some(Self::AccessKey),
            "secret-key" | "secretkey" | "sk" => Some(Self::SecretKey),
            _ => None,
        }
    }
}

/// A parsed secret reference.
#[derive(Debug, Clone)]
pub struct SecretReference {
    pub raw: String,
    pub vault_name: String,
    pub entry_query: String,
    pub field: SecretReferenceField,
}

impl SecretReference {
    /// Parse a secret reference string.
    pub fn parse(raw: &str) -> Result<Self> {
        let raw = raw.trim();
        let rest = raw
            .strip_prefix("ov://")
            .or_else(|| raw.strip_prefix("op://"))
            .ok_or_else(|| {
                Error::InvalidArgument("secret reference must start with ov:// or op://".into())
            })?;

        let parts: Vec<&str> = rest.split('/').collect();
        if parts.len() < 3 {
            return Err(Error::InvalidArgument(
                "secret reference must be ov://vault/entry/field".into(),
            ));
        }

        let field = SecretReferenceField::parse(parts[2])
            .ok_or_else(|| Error::InvalidArgument(format!("unknown field: {}", parts[2])))?;

        Ok(Self {
            raw: raw.to_string(),
            vault_name: parts[0].to_string(),
            entry_query: parts[1].to_string(),
            field,
        })
    }
}

/// Resolve a secret reference against a collection of open vaults.
///
/// The first vault whose name matches `reference.vault_name` is used.
pub fn resolve_secret_reference<'a>(
    reference: &SecretReference,
    vaults: &'a [(&str, &'a Vault)],
) -> Result<String> {
    let (_, vault) = vaults
        .iter()
        .find(|(name, _)| name.eq_ignore_ascii_case(&reference.vault_name))
        .ok_or_else(|| Error::VaultNotFound)?;

    let entry = vault
        .find_entry(&reference.entry_query)
        .ok_or_else(|| Error::EntryNotFound)?;

    match reference.field {
        SecretReferenceField::Title => Ok(entry.title),
        SecretReferenceField::Username => Ok(entry.username),
        SecretReferenceField::Password => Ok(entry.password),
        SecretReferenceField::Url => Ok(entry.url),
        SecretReferenceField::Notes => Ok(entry.notes),
        SecretReferenceField::Totp => Err(Error::InvalidArgument(
            "totp resolution requires a TOTP generator; use generate_totp".into(),
        )),
        SecretReferenceField::AccessKey => custom(&entry, "access-key"),
        SecretReferenceField::SecretKey => custom(&entry, "secret-key"),
    }
}

/// Reads a custom (non-standard) field, e.g. the AK/SK pair.
fn custom(entry: &Entry, key: &str) -> Result<String> {
    Ok(entry
        .custom
        .iter()
        .find(|(k, _)| k == key)
        .map(|(_, v)| v.clone())
        .unwrap_or_default())
}

/// Resolve the standard field value from an entry directly.
pub fn resolve_entry_field(entry: &Entry, field: SecretReferenceField) -> String {
    match field {
        SecretReferenceField::Title => entry.title.clone(),
        SecretReferenceField::Username => entry.username.clone(),
        SecretReferenceField::Password => entry.password.clone(),
        SecretReferenceField::Url => entry.url.clone(),
        SecretReferenceField::Notes => entry.notes.clone(),
        SecretReferenceField::Totp => entry
            .custom
            .iter()
            .find(|(k, _)| k == "OTPAuth")
            .map(|(_, v)| v.clone())
            .unwrap_or_default(),
        SecretReferenceField::AccessKey => entry
            .custom
            .iter()
            .find(|(k, _)| k == "access-key")
            .map(|(_, v)| v.clone())
            .unwrap_or_default(),
        SecretReferenceField::SecretKey => entry
            .custom
            .iter()
            .find(|(k, _)| k == "secret-key")
            .map(|(_, v)| v.clone())
            .unwrap_or_default(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::kdbx::{CreateEntryRequest, Vault};

    #[test]
    fn parse_secret_reference() {
        let r = SecretReference::parse("ov://Work/GitHub/password").unwrap();
        assert_eq!(r.vault_name, "Work");
        assert_eq!(r.entry_query, "GitHub");
        assert_eq!(r.field, SecretReferenceField::Password);
    }

    #[test]
    fn parse_op_prefix() {
        let r = SecretReference::parse("op://Personal/Email/username").unwrap();
        assert_eq!(r.vault_name, "Personal");
        assert_eq!(r.entry_query, "Email");
        assert_eq!(r.field, SecretReferenceField::Username);
    }

    #[test]
    fn parse_ak_sk_fields() {
        for (name, expected) in [
            ("access-key", SecretReferenceField::AccessKey),
            ("ak", SecretReferenceField::AccessKey),
            ("secret-key", SecretReferenceField::SecretKey),
            ("sk", SecretReferenceField::SecretKey),
        ] {
            let r = SecretReference::parse(&format!("ov://Work/Ark/{name}")).unwrap();
            assert_eq!(r.field, expected, "{name}");
        }
    }

    #[test]
    fn resolve_reference() {
        let mut vault = Vault::create_new("Work").unwrap();
        vault
            .add_entry(&CreateEntryRequest {
                title: "GitHub".into(),
                username: "alice".into(),
                password: "s3cret".into(),
                ..Default::default()
            })
            .unwrap();

        let r = SecretReference::parse("ov://Work/GitHub/username").unwrap();
        let value = resolve_secret_reference(&r, &[("Work", &vault)]).unwrap();
        assert_eq!(value, "alice");
    }
}
