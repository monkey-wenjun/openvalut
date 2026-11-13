//! Routes native-messaging requests to vault operations.

use std::path::PathBuf;
use std::process::Command;
use std::time::{SystemTime, UNIX_EPOCH};

use openvalut_core::generate_password;
use openvalut_core::totp;
use serde_json::{json, Map, Value};

use crate::bridge;
use crate::matcher;
use crate::models::{
    error_codes, rpc_methods, HandlerError, HostRequest, HostResponse, MatchedEntry, TotpCode,
};
use crate::passkey::{self, PasskeyEntry};
use crate::session::VaultSession;

impl From<bridge::BridgeError> for HandlerError {
    fn from(e: bridge::BridgeError) -> Self {
        Self::new(e.0, error_codes::FAILED)
    }
}

/// Handles a single native-messaging request.
pub struct MessageHandler {
    session: VaultSession,
    config_dir: Option<PathBuf>,
}

impl MessageHandler {
    pub fn new() -> Self {
        Self::with_config_dir(None)
    }

    pub fn with_config_dir(config_dir: Option<PathBuf>) -> Self {
        Self {
            session: VaultSession::with_config_dir(config_dir.clone()),
            config_dir,
        }
    }

    pub fn handle(&mut self, request: &HostRequest) -> HostResponse {
        let rid = request.request_id.clone();
        let result = self.dispatch(&request.method, &request.params);
        match result {
            Ok(value) => HostResponse::ok(value, rid),
            Err(e) => HostResponse::error(e.message, e.code, rid),
        }
    }

    fn dispatch(
        &mut self,
        method: &str,
        params: &Map<String, Value>,
    ) -> Result<Value, HandlerError> {
        match method {
            rpc_methods::PING => Ok(json!({"pong": true})),
            rpc_methods::OPEN_APP_VAULT => self.open_app_vault(),
            rpc_methods::CLOSE_VAULT => {
                let path = require_str(params, "path")?;
                self.session.close_vault(&path);
                Ok(Value::Null)
            }
            rpc_methods::LOCK => {
                self.session.lock();
                Ok(Value::Null)
            }
            rpc_methods::LIST_VAULTS => self.list_vaults(),
            rpc_methods::MATCH_ENTRIES => self.match_entries(params),
            rpc_methods::CHECK_ENTRY_EXISTS => self.check_entry_exists(params),
            rpc_methods::GET_CREDENTIAL => self.get_credential(params),
            rpc_methods::GET_TOTP => self.get_totp(params),
            rpc_methods::GENERATE_PASSWORD => Ok(self.generate_password(params)),
            rpc_methods::CREATE_ENTRY => self.create_entry(params),
            rpc_methods::UPDATE_ENTRY => self.update_entry(params),
            rpc_methods::DELETE_ENTRY => self.delete_entry(params),
            rpc_methods::LIST_PASSKEYS => self.list_passkeys(params),
            rpc_methods::CREATE_PASSKEY => self.create_passkey(params),
            rpc_methods::GET_PASSKEY => self.get_passkey(params),
            _ => Err(HandlerError::new(
                format!("Unknown method: {method}"),
                error_codes::UNKNOWN_METHOD,
            )),
        }
    }

    fn open_app_vault(&mut self) -> Result<Value, HandlerError> {
        match self.session.unlock_from_app() {
            Ok(count) if count > 0 => Ok(json!({
                "opened": true,
                "entryCount": count,
                "launched": false,
                "focused": false,
            })),
            Ok(_) => {
                if desktop_app_running() {
                    let _ = bridge::show_window(self.config_dir.clone());
                    Ok(json!({
                        "opened": false,
                        "entryCount": 0,
                        "launched": false,
                        "focused": true,
                        "reason": "OpenValut 已在运行，已切换到桌面窗口，请解锁密码库后返回刷新本页面。",
                    }))
                } else {
                    let launched = launch_desktop_app();
                    if launched {
                        std::thread::sleep(std::time::Duration::from_secs(1));
                        let count = self.session.unlock_from_app().unwrap_or(0);
                        Ok(json!({
                            "opened": count > 0,
                            "entryCount": count,
                            "launched": true,
                            "focused": false,
                        }))
                    } else {
                        Ok(json!({
                            "opened": false,
                            "entryCount": 0,
                            "launched": false,
                            "focused": false,
                            "reason": "无法启动桌面 OpenValut，请确认已安装 deb 包或 native host 已更新。",
                        }))
                    }
                }
            }
            Err(e) => Err(HandlerError::new(e.0, error_codes::NOT_FOUND)),
        }
    }

    fn ensure_unlocked(&mut self) -> Result<(), HandlerError> {
        let sync_result = self.session.sync_with_app();
        if let Err(error) = sync_result {
            self.session.lock();
            return Err(HandlerError::from(error));
        }
        if self.session.is_empty() {
            return Err(HandlerError::new(
                "No vaults are unlocked.",
                error_codes::NO_VAULTS,
            ));
        }
        Ok(())
    }

    fn list_vaults(&mut self) -> Result<Value, HandlerError> {
        self.ensure_unlocked()?;
        let vaults: Vec<_> = self
            .session
            .opened_vaults()
            .into_iter()
            .map(|v| json!({"id": v.id, "path": v.id, "name": v.name}))
            .collect();
        Ok(json!({"vaults": vaults}))
    }

    fn match_entries(&mut self, params: &Map<String, Value>) -> Result<Value, HandlerError> {
        self.ensure_unlocked()?;
        let url = require_str(params, "url")?;
        let submit_url = opt_str(params, "submitUrl");
        let top_url = opt_str(params, "topUrl");
        let limit = params.get("limit").and_then(Value::as_u64).unwrap_or(50) as usize;

        let mut request_hosts = Vec::new();
        if let Some(h) = matcher::host_of(&url) {
            request_hosts.push(h);
        }
        if let Some(su) = &submit_url {
            if let Some(h) = matcher::host_of(su) {
                request_hosts.push(h);
            }
        }
        if let Some(tu) = &top_url {
            if tu != &url {
                if let Some(h) = matcher::host_of(tu) {
                    request_hosts.push(h);
                }
            }
        }

        let mut matches = Vec::new();
        for vault in self.session.opened_vaults() {
            for entry in vault.vault.entries() {
                let urls = matcher::entry_urls(&entry.url, &entry.custom);
                if let Some(quality) = matcher::best_quality(&request_hosts, &urls) {
                    matches.push(MatchedEntry {
                        file_id: vault.id.clone(),
                        file_name: vault.name.clone(),
                        entry_uuid: entry.uuid.clone(),
                        label: if entry.title.is_empty() {
                            None
                        } else {
                            Some(entry.title.clone())
                        },
                        username: if entry.username.is_empty() {
                            None
                        } else {
                            Some(entry.username.clone())
                        },
                        quality: quality.name().to_string(),
                    });
                }
            }
        }
        Ok(json!({
            "matches": matches.into_iter().take(limit).collect::<Vec<_>>()
        }))
    }

    fn check_entry_exists(&mut self, params: &Map<String, Value>) -> Result<Value, HandlerError> {
        self.ensure_unlocked()?;
        let url = require_str(params, "url")?;
        let username = opt_str(params, "username")
            .unwrap_or_default()
            .trim()
            .to_string();
        let submit_url = opt_str(params, "submitUrl");
        let top_url = opt_str(params, "topUrl");
        let mut request_hosts = Vec::new();
        if let Some(h) = matcher::host_of(&url) {
            request_hosts.push(h);
        }
        if let Some(su) = &submit_url {
            if let Some(h) = matcher::host_of(su) {
                request_hosts.push(h);
            }
        }
        if let Some(tu) = &top_url {
            if let Some(h) = matcher::host_of(tu) {
                request_hosts.push(h);
            }
        }
        if request_hosts.is_empty() {
            return Ok(json!({"exists": false}));
        }
        if username.is_empty() {
            return Ok(json!({"exists": false}));
        }
        for vault in self.session.opened_vaults() {
            for entry in vault.vault.entries() {
                let urls = matcher::entry_urls(&entry.url, &entry.custom);
                if matcher::best_quality(&request_hosts, &urls).is_some()
                    && entry.username.eq_ignore_ascii_case(&username)
                {
                    return Ok(json!({"exists": true}));
                }
            }
        }
        Ok(json!({"exists": false}))
    }

    fn get_credential(&mut self, params: &Map<String, Value>) -> Result<Value, HandlerError> {
        self.ensure_unlocked()?;
        let file_id = require_str(params, "fileId")?;
        let entry_uuid = require_str(params, "entryUuid")?;
        let vault = self.session.get_vault(&file_id).ok_or_else(|| {
            HandlerError::new(
                format!("Vault {file_id} is not open."),
                error_codes::NOT_FOUND,
            )
        })?;
        let entry = vault
            .vault
            .entries()
            .into_iter()
            .find(|e| e.uuid == entry_uuid)
            .ok_or_else(|| {
                HandlerError::new(
                    format!("Entry {entry_uuid} not found."),
                    error_codes::NOT_FOUND,
                )
            })?;
        Ok(json!({
            "username": entry.username,
            "password": entry.password,
            "title": entry.title,
            "url": entry.url,
            "notes": entry.notes,
        }))
    }

    fn get_totp(&mut self, params: &Map<String, Value>) -> Result<Value, HandlerError> {
        self.ensure_unlocked()?;
        let file_id = require_str(params, "fileId")?;
        let entry_uuid = require_str(params, "entryUuid")?;
        let vault = self.session.get_vault(&file_id).ok_or_else(|| {
            HandlerError::new(
                format!("Vault {file_id} is not open."),
                error_codes::NOT_FOUND,
            )
        })?;
        let raw = vault
            .vault
            .entry_value(&entry_uuid, openvalut_core::FIELD_OTP)
            .filter(|s| !s.is_empty())
            .ok_or_else(|| {
                HandlerError::new(
                    "Entry has no usable OTP configuration.",
                    error_codes::NOT_FOUND,
                )
            })?;
        let auth = totp::parse_otp_auth(&raw).map_err(|e| {
            HandlerError::new(
                format!("Invalid OTP configuration: {e}"),
                error_codes::FAILED,
            )
        })?;
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|d| d.as_secs())
            .unwrap_or(0);
        let (code, remaining, period) = totp::generate_totp(&auth, Some(now))
            .map_err(|e| HandlerError::new(e.to_string(), error_codes::FAILED))?;
        Ok(serde_json::to_value(TotpCode {
            code,
            remaining_seconds: remaining,
            period,
        })
        .unwrap_or_default())
    }

    fn generate_password(&self, params: &Map<String, Value>) -> Value {
        let length = params
            .get("length")
            .and_then(Value::as_u64)
            .unwrap_or(20)
            .clamp(8, 128) as usize;
        let upper = params
            .get("includeUppercase")
            .and_then(Value::as_bool)
            .unwrap_or(false);
        let digits = params
            .get("includeDigits")
            .and_then(Value::as_bool)
            .unwrap_or(false);
        let special = params
            .get("includeSpecial")
            .and_then(Value::as_bool)
            .unwrap_or(false);
        let password = generate_password(length, upper, digits, special)
            .unwrap_or_else(|_| "password".to_string());
        json!({"password": password})
    }

    fn create_entry(&mut self, params: &Map<String, Value>) -> Result<Value, HandlerError> {
        self.ensure_unlocked()?;
        let file_id = require_str(params, "fileId")?;
        let title = opt_str(params, "title");
        let username = opt_str(params, "username");
        let url = opt_str(params, "url");
        let uuid = bridge::create_entry(
            self.config_dir.clone(),
            &file_id,
            title.as_deref(),
            username.as_deref(),
            url.as_deref(),
            None,
        )
        .map_err(HandlerError::from)?;
        Ok(json!({"entryUuid": uuid}))
    }

    fn update_entry(&mut self, params: &Map<String, Value>) -> Result<Value, HandlerError> {
        self.ensure_unlocked()?;
        let file_id = require_str(params, "fileId")?;
        let entry_uuid = require_str(params, "entryUuid")?;
        let title = opt_str(params, "title");
        let username = opt_str(params, "username");
        let password = opt_str(params, "password");
        let url = opt_str(params, "url");
        let notes = opt_str(params, "notes");
        bridge::update_entry(
            self.config_dir.clone(),
            &file_id,
            &entry_uuid,
            title.as_deref(),
            username.as_deref(),
            password.as_deref(),
            url.as_deref(),
            notes.as_deref(),
        )
        .map_err(HandlerError::from)?;
        let _ = self.session.open_vaults_from_app();
        Ok(json!({"ok": true}))
    }

    fn delete_entry(&mut self, params: &Map<String, Value>) -> Result<Value, HandlerError> {
        self.ensure_unlocked()?;
        let file_id = require_str(params, "fileId")?;
        let entry_uuid = require_str(params, "entryUuid")?;
        bridge::delete_entry(self.config_dir.clone(), &file_id, &entry_uuid)
            .map_err(HandlerError::from)?;
        let _ = self.session.open_vaults_from_app();
        Ok(json!({"ok": true}))
    }

    fn list_passkeys(&mut self, params: &Map<String, Value>) -> Result<Value, HandlerError> {
        self.ensure_unlocked()?;
        let rp_id = opt_str(params, "rpId");
        let mut passkeys = Vec::new();
        for vault in self.session.opened_vaults() {
            for entry in vault.vault.entries() {
                if let Some(pk) = PasskeyEntry::from_kdbx(&entry) {
                    if let Some(rp) = &rp_id {
                        if &pk.relying_party != rp {
                            continue;
                        }
                    }
                    passkeys.push(json!({
                        "fileId": vault.id,
                        "entryUuid": entry.uuid,
                        "credentialId": pk.credential_id_b64url(),
                        "rpId": pk.relying_party,
                        "username": pk.username,
                    }));
                }
            }
        }
        Ok(json!({"passkeys": passkeys}))
    }

    fn create_passkey(&mut self, params: &Map<String, Value>) -> Result<Value, HandlerError> {
        self.ensure_unlocked()?;
        let options_json = params
            .get("options")
            .and_then(Value::as_object)
            .ok_or_else(|| {
                HandlerError::new(
                    "Missing required parameter: options",
                    error_codes::MISSING_PARAM,
                )
            })?;
        let mut options = parse_creation_options(options_json)?;
        options.rp_id = validated_rp_id(params, Some(&options.rp_id))?;
        let result = passkey::create(&options);
        let file_id = opt_str(params, "fileId")
            .or_else(|| self.session.opened_vaults().first().map(|v| v.id.clone()))
            .ok_or_else(|| HandlerError::new("No vaults are unlocked.", error_codes::NO_VAULTS))?;

        let entry = &result.entry;
        let mut custom = serde_json::Map::new();
        custom.insert(
            passkey::FIELD_CREDENTIAL_ID.to_string(),
            json!({"value": entry.credential_id_b64url(), "protect": true}),
        );
        custom.insert(
            passkey::FIELD_PRIVATE_KEY_PEM.to_string(),
            json!({"value": entry.private_key_pem, "protect": true}),
        );
        custom.insert(
            passkey::FIELD_RELYING_PARTY.to_string(),
            json!({"value": entry.relying_party, "protect": false}),
        );
        if let Some(uh) = &entry.user_handle {
            custom.insert(
                passkey::FIELD_USER_HANDLE.to_string(),
                json!({"value": passkey::base64_url_encode(uh), "protect": true}),
            );
        }
        if let Some(name) = &entry.username {
            custom.insert(
                passkey::FIELD_USERNAME.to_string(),
                json!({"value": name, "protect": false}),
            );
        }
        custom.insert(
            passkey::FIELD_FLAG_BE.to_string(),
            json!({"value": "1", "protect": false}),
        );
        custom.insert(
            passkey::FIELD_FLAG_BS.to_string(),
            json!({"value": "1", "protect": false}),
        );

        let rp_url = format!("https://{}", options.rp_id);
        // Prefer attaching the credential to the existing entry for this site
        // (so the passkey lives on the same row as the username/password)
        // instead of creating a duplicate entry that breaks the login flow.
        let entry_uuid = match self.find_passkey_target(&options.rp_id, &options.user_name) {
            Some((vault_id, uuid)) => {
                bridge::update_entry_custom(
                    self.config_dir.clone(),
                    &vault_id,
                    &uuid,
                    &Value::Object(custom),
                )
                .map_err(HandlerError::from)?;
                uuid
            }
            None => bridge::create_entry(
                self.config_dir.clone(),
                &file_id,
                Some(options.rp_name.as_str()),
                Some(options.user_name.as_str()),
                Some(rp_url.as_str()),
                Some(&Value::Object(custom)),
            )
            .map_err(HandlerError::from)?,
        };
        let _ = self.session.open_vaults_from_app();
        Ok(json!({
            "attestation": result.response.to_json(),
            "fileId": file_id,
            "entryUuid": entry_uuid,
        }))
    }

    /// Finds an existing entry for the same relying party that is not already a
    /// passkey, so a new credential can be attached to it instead of creating a
    /// duplicate. Prefers an entry whose username matches the registering user.
    fn find_passkey_target(&self, rp_id: &str, user_name: &str) -> Option<(String, String)> {
        let requested = normalize_rp_id(rp_id);
        let mut fallback: Option<(String, String)> = None;
        for vault in self.session.opened_vaults() {
            for entry in vault.vault.entries() {
                // Skip entries that already hold a passkey; we want to enrich a
                // plain login row, not append onto an existing credential.
                if PasskeyEntry::from_kdbx(&entry).is_some() {
                    continue;
                }
                let host = matcher::host_of(&entry.url).unwrap_or_default();
                if host.is_empty() || normalize_rp_id(&host) != requested {
                    continue;
                }
                if !user_name.is_empty() && entry.username == user_name {
                    return Some((vault.id.clone(), entry.uuid.clone()));
                }
                if fallback.is_none() {
                    fallback = Some((vault.id.clone(), entry.uuid.clone()));
                }
            }
        }
        fallback
    }

    fn get_passkey(&mut self, params: &Map<String, Value>) -> Result<Value, HandlerError> {
        self.ensure_unlocked()?;
        let options_json = params
            .get("options")
            .and_then(Value::as_object)
            .ok_or_else(|| {
                HandlerError::new(
                    "Missing required parameter: options",
                    error_codes::MISSING_PARAM,
                )
            })?;
        let mut options = parse_request_options(options_json)?;
        options.rp_id = Some(validated_rp_id(params, options.rp_id.as_deref())?);
        let requested_rp = options.rp_id.as_deref().map(normalize_rp_id);
        let mut matched: Option<(String, String, PasskeyEntry)> = None;
        let mut candidates: Vec<String> = Vec::new();
        'outer: for vault in self.session.opened_vaults() {
            for entry in vault.vault.entries() {
                if let Some(pk) = PasskeyEntry::from_kdbx(&entry) {
                    candidates.push(format!(
                        "{}/{}",
                        pk.relying_party,
                        pk.credential_id_b64url()
                    ));
                    let rp_matches = match &requested_rp {
                        Some(rp) => normalize_rp_id(&pk.relying_party) == *rp,
                        None => true,
                    };
                    if !rp_matches {
                        continue;
                    }
                    let allow_matches = options.allow_credential_ids.is_empty()
                        || options
                            .allow_credential_ids
                            .iter()
                            .any(|id| id == &pk.credential_id);
                    if !allow_matches {
                        continue;
                    }
                    matched = Some((vault.id.clone(), entry.uuid.clone(), pk));
                    break 'outer;
                }
            }
        }
        let (file_id, entry_uuid, pk) = matched.ok_or_else(|| {
            let allow_ids: Vec<String> = options
                .allow_credential_ids
                .iter()
                .map(|id| passkey::base64_url_encode(id))
                .collect();
            HandlerError::new(
                format!(
                    "No matching passkey found. rpId={:?}, allowCredentials={:?}, candidates={:?}",
                    options.rp_id, allow_ids, candidates
                ),
                error_codes::NOT_FOUND,
            )
        })?;
        let assertion = passkey::get(&pk, &options);
        Ok(json!({
            "assertion": assertion.to_json(),
            "fileId": file_id,
            "entryUuid": entry_uuid,
        }))
    }
}

/// Normalizes an RP id for matching: lowercases, drops scheme, leading 'www.'
/// and trailing slashes.
fn normalize_rp_id(rp_id: &str) -> String {
    let mut s = rp_id.trim().to_lowercase();
    if let Some(rest) = s.strip_prefix("https://") {
        s = rest.to_string();
    } else if let Some(rest) = s.strip_prefix("http://") {
        s = rest.to_string();
    }
    if let Some(rest) = s.strip_prefix("www.") {
        s = rest.to_string();
    }
    while s.ends_with('/') {
        s.pop();
    }
    s
}

fn validated_rp_id(
    params: &Map<String, Value>,
    requested_rp_id: Option<&str>,
) -> Result<String, HandlerError> {
    let page_url = require_str(params, "pageUrl")?;
    let page_url = url::Url::parse(&page_url)
        .map_err(|_| HandlerError::new("Invalid pageUrl", error_codes::FAILED))?;
    let page_host = page_url
        .host_str()
        .map(|host| host.trim_end_matches('.').to_ascii_lowercase())
        .filter(|host| !host.is_empty())
        .ok_or_else(|| HandlerError::new("pageUrl has no host", error_codes::FAILED))?;
    let local_page = page_host == "localhost" || page_host.parse::<std::net::IpAddr>().is_ok();
    if page_url.scheme() != "https" && !(page_url.scheme() == "http" && local_page) {
        return Err(HandlerError::new(
            "Passkeys require a secure page origin",
            error_codes::FAILED,
        ));
    }

    let rp_id = requested_rp_id
        .filter(|value| !value.trim().is_empty())
        .unwrap_or(&page_host)
        .trim()
        .trim_end_matches('.')
        .to_ascii_lowercase();
    if rp_id
        .chars()
        .any(|value| matches!(value, '/' | ':' | '@') || value.is_whitespace())
        || rp_id.is_empty()
    {
        return Err(HandlerError::new("Invalid rpId", error_codes::FAILED));
    }

    let host_matches = page_host == rp_id
        || page_host
            .strip_suffix(&rp_id)
            .is_some_and(|prefix| prefix.ends_with('.'));
    let registrable = psl::domain_str(&rp_id).is_some();
    if !host_matches || (!registrable && !local_page) {
        return Err(HandlerError::new(
            "rpId is not valid for the requesting origin",
            error_codes::FAILED,
        ));
    }
    Ok(rp_id)
}

impl Default for MessageHandler {
    fn default() -> Self {
        Self::new()
    }
}

fn require_str(params: &Map<String, Value>, key: &str) -> Result<String, HandlerError> {
    match params.get(key).and_then(Value::as_str) {
        Some(v) if !v.is_empty() => Ok(v.to_string()),
        _ => Err(HandlerError::new(
            format!("Missing required parameter: {key}"),
            error_codes::MISSING_PARAM,
        )),
    }
}

fn opt_str(params: &Map<String, Value>, key: &str) -> Option<String> {
    params
        .get(key)
        .and_then(Value::as_str)
        .map(|s| s.to_string())
}

fn desktop_app_running() -> bool {
    let pgrep_ok = Command::new("pgrep")
        .arg("-x")
        .arg("openvalut")
        .output()
        .map(|out| out.status.success())
        .unwrap_or(false);
    if pgrep_ok {
        return true;
    }
    Command::new("pidof")
        .arg("openvalut")
        .output()
        .map(|out| out.status.success())
        .unwrap_or(false)
}

fn launch_desktop_app() -> bool {
    let mut candidates: Vec<Vec<&str>> = vec![
        vec!["gtk-launch", "openvalut"],
        vec!["/usr/bin/openvalut"],
        vec!["/opt/openvalut/openvalut"],
    ];
    // xdg-open first is common, but it can be flaky in a headless host; keep
    // the direct launchers first and add xdg-open as a fallback.
    candidates.push(vec![
        "xdg-open",
        "/usr/share/applications/openvalut.desktop",
    ]);
    for args in candidates {
        if Command::new(args[0]).args(&args[1..]).spawn().is_ok() {
            return true;
        }
    }
    false
}

fn b64url_decode_s(value: &str) -> Result<Vec<u8>, HandlerError> {
    passkey::base64_url_decode(value)
        .ok_or_else(|| HandlerError::new("Invalid base64url value", error_codes::FAILED))
}

fn parse_creation_options(
    obj: &Map<String, Value>,
) -> Result<passkey::CreationOptions, HandlerError> {
    let rp = obj
        .get("rp")
        .and_then(Value::as_object)
        .ok_or_else(|| HandlerError::new("Missing options.rp", error_codes::MISSING_PARAM))?;
    let user = obj
        .get("user")
        .and_then(Value::as_object)
        .ok_or_else(|| HandlerError::new("Missing options.user", error_codes::MISSING_PARAM))?;
    let rp_id = rp
        .get("id")
        .and_then(Value::as_str)
        .unwrap_or_default()
        .to_string();
    let rp_name = rp
        .get("name")
        .and_then(Value::as_str)
        .unwrap_or_default()
        .to_string();
    let user_name = user
        .get("name")
        .and_then(Value::as_str)
        .unwrap_or_default()
        .to_string();
    let user_display_name = user
        .get("displayName")
        .and_then(Value::as_str)
        .unwrap_or_default()
        .to_string();
    let user_id_b64 = user
        .get("id")
        .and_then(Value::as_str)
        .ok_or_else(|| HandlerError::new("Missing options.user.id", error_codes::MISSING_PARAM))?;
    let user_id = b64url_decode_s(user_id_b64)?;
    let challenge_b64 = obj
        .get("challenge")
        .and_then(Value::as_str)
        .ok_or_else(|| {
            HandlerError::new("Missing options.challenge", error_codes::MISSING_PARAM)
        })?;
    let challenge = b64url_decode_s(challenge_b64)?;
    Ok(passkey::CreationOptions {
        rp_id,
        rp_name,
        user_id,
        user_name,
        user_display_name,
        challenge,
    })
}

fn parse_request_options(
    obj: &Map<String, Value>,
) -> Result<passkey::RequestOptions, HandlerError> {
    let challenge_b64 = obj
        .get("challenge")
        .and_then(Value::as_str)
        .ok_or_else(|| {
            HandlerError::new("Missing options.challenge", error_codes::MISSING_PARAM)
        })?;
    let challenge = b64url_decode_s(challenge_b64)?;
    let rp_id = obj
        .get("rpId")
        .and_then(Value::as_str)
        .map(|s| s.to_string());
    let allow_credential_ids = obj
        .get("allowCredentials")
        .and_then(Value::as_array)
        .map(|arr| {
            arr.iter()
                .filter_map(|v| v.get("id").and_then(Value::as_str))
                .filter_map(|s| b64url_decode_s(s).ok())
                .collect::<Vec<_>>()
        })
        .unwrap_or_default();
    Ok(passkey::RequestOptions {
        challenge,
        rp_id,
        allow_credential_ids,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn params(page_url: &str) -> Map<String, Value> {
        let mut params = Map::new();
        params.insert("pageUrl".into(), Value::String(page_url.into()));
        params
    }

    #[test]
    fn rp_id_must_be_bound_to_page_origin() {
        let request = params("https://accounts.example.com/login");
        assert_eq!(
            validated_rp_id(&request, Some("example.com")).unwrap(),
            "example.com"
        );
        assert_eq!(
            validated_rp_id(&request, Some("accounts.example.com")).unwrap(),
            "accounts.example.com"
        );
        assert!(validated_rp_id(&request, Some("evil.example")).is_err());
        assert!(validated_rp_id(&request, Some("com")).is_err());
    }

    #[test]
    fn rp_id_defaults_to_origin_host_and_requires_secure_origin() {
        let request = params("https://login.example.com/path");
        assert_eq!(
            validated_rp_id(&request, None).unwrap(),
            "login.example.com"
        );
        assert!(validated_rp_id(&params("http://login.example.com"), Some("example.com")).is_err());
        assert_eq!(
            validated_rp_id(&params("http://localhost:8080"), None).unwrap(),
            "localhost"
        );
    }
}
