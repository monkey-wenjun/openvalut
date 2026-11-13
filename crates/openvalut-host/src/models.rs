//! Request/response models for the native-messaging protocol.

use serde::{Deserialize, Serialize};
use serde_json::Value;

/// Request envelope received from the extension.
#[derive(Debug, Clone, Deserialize)]
pub struct HostRequest {
    pub method: String,
    #[serde(default)]
    pub params: serde_json::Map<String, Value>,
    #[serde(rename = "requestId")]
    pub request_id: Option<String>,
}

/// Response envelope sent back to the extension.
#[derive(Debug, Clone, Serialize)]
pub struct HostResponse {
    pub ok: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub data: Option<Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub code: Option<String>,
    #[serde(rename = "requestId", skip_serializing_if = "Option::is_none")]
    pub request_id: Option<String>,
}

impl HostResponse {
    pub fn ok(data: Value, request_id: Option<String>) -> Self {
        Self {
            ok: true,
            data: Some(data),
            error: None,
            code: None,
            request_id,
        }
    }

    pub fn error(
        message: impl Into<String>,
        code: impl Into<String>,
        request_id: Option<String>,
    ) -> Self {
        Self {
            ok: false,
            data: None,
            error: Some(message.into()),
            code: Some(code.into()),
            request_id,
        }
    }
}

/// Metadata returned for a matched entry.
#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct MatchedEntry {
    pub file_id: String,
    pub file_name: String,
    pub entry_uuid: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub label: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub username: Option<String>,
    pub quality: String,
}

/// Credential returned when an entry is explicitly chosen.
#[derive(Debug, Clone, Serialize)]
pub struct EntryCredential {
    pub username: String,
    pub password: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub title: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub url: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub notes: Option<String>,
}

/// Current TOTP code and lifetime.
#[derive(Debug, Clone, Serialize)]
pub struct TotpCode {
    pub code: String,
    pub remaining_seconds: u64,
    pub period: u64,
}

/// Result of `generatePassword`.
#[derive(Debug, Clone, Serialize)]
pub struct GeneratedPassword {
    pub password: String,
}

/// Result of `createEntry`.
#[derive(Debug, Clone, Serialize)]
pub struct CreatedEntry {
    pub entry_uuid: String,
}

/// Stable error codes sent back to the extension.
pub mod error_codes {
    pub const UNKNOWN_METHOD: &str = "UNKNOWN_METHOD";
    pub const MISSING_PARAM: &str = "MISSING_PARAM";
    pub const NOT_FOUND: &str = "NOT_FOUND";
    pub const INVALID_KEY: &str = "INVALID_KEY";
    pub const STALE_KEY: &str = "STALE_KEY";
    pub const NO_VAULTS: &str = "NO_VAULTS";
    pub const FAILED: &str = "FAILED";
}

pub mod rpc_methods {
    pub const PING: &str = "ping";
    pub const OPEN_APP_VAULT: &str = "openAppVault";
    pub const CLOSE_VAULT: &str = "closeVault";
    pub const LOCK: &str = "lock";
    pub const LIST_VAULTS: &str = "listVaults";
    pub const MATCH_ENTRIES: &str = "matchEntries";
    pub const CHECK_ENTRY_EXISTS: &str = "checkEntryExists";
    pub const GET_CREDENTIAL: &str = "getCredential";
    pub const GET_TOTP: &str = "getTotp";
    pub const GENERATE_PASSWORD: &str = "generatePassword";
    pub const CREATE_ENTRY: &str = "createEntry";
    pub const UPDATE_ENTRY: &str = "updateEntry";
    pub const DELETE_ENTRY: &str = "deleteEntry";
    pub const LIST_PASSKEYS: &str = "listPasskeys";
    pub const CREATE_PASSKEY: &str = "createPasskey";
    pub const GET_PASSKEY: &str = "getPasskey";

    pub const ALL: [&str; 16] = [
        PING,
        OPEN_APP_VAULT,
        CLOSE_VAULT,
        LOCK,
        LIST_VAULTS,
        MATCH_ENTRIES,
        CHECK_ENTRY_EXISTS,
        GET_CREDENTIAL,
        GET_TOTP,
        GENERATE_PASSWORD,
        CREATE_ENTRY,
        UPDATE_ENTRY,
        DELETE_ENTRY,
        LIST_PASSKEYS,
        CREATE_PASSKEY,
        GET_PASSKEY,
    ];
}

/// Error raised inside the dispatcher.
#[derive(Debug)]
pub struct HandlerError {
    pub message: String,
    pub code: String,
}

impl HandlerError {
    pub fn new(message: impl Into<String>, code: impl Into<String>) -> Self {
        Self {
            message: message.into(),
            code: code.into(),
        }
    }
}

impl From<String> for HandlerError {
    fn from(message: String) -> Self {
        Self::new(message, error_codes::FAILED)
    }
}

#[cfg(test)]
mod tests {
    use std::collections::BTreeSet;

    use super::rpc_methods;

    #[test]
    fn native_messaging_methods_match_extension_contract() {
        let source = include_str!("../../../chrome_extension/rpc-contract.js");
        let extension_methods: BTreeSet<&str> = source
            .lines()
            .filter_map(|line| line.trim().split_once(": '"))
            .filter_map(|(_, value)| value.strip_suffix("',"))
            .collect();
        let host_methods: BTreeSet<&str> = rpc_methods::ALL.into_iter().collect();

        assert_eq!(extension_methods, host_methods);
    }
}
