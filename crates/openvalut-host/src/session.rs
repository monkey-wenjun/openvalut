//! In-memory vault session for the host.
//!
//! Opens every unlocked vault served by the desktop app using the transformed
//! key (no master password), and keeps them cached so entry lookups and
//! matching are fast. Child mutations are delegated back to the app bridge,
//! which holds the original credentials.

use std::collections::HashMap;

use openvalut_core::kdbx::Vault;
use openvalut_core::VaultKey;

use crate::bridge::{self, AppVaultData, BridgeError};

/// A vault currently held in memory by the host.
#[derive(Debug, Clone)]
pub struct OpenedVault {
    pub id: String,
    pub name: String,
    pub vault: Vault,
    pub kdf_fingerprint: String,
}

/// Holds every vault unlocked in this host process.
#[derive(Debug, Default)]
pub struct VaultSession {
    vaults: HashMap<String, OpenedVault>,
    config_dir: Option<std::path::PathBuf>,
    generation: Option<String>,
    locked: bool,
}

impl VaultSession {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn with_config_dir(config_dir: Option<std::path::PathBuf>) -> Self {
        Self {
            vaults: HashMap::new(),
            config_dir,
            generation: None,
            locked: false,
        }
    }

    pub fn is_empty(&self) -> bool {
        self.vaults.is_empty()
    }

    pub fn opened_vaults(&self) -> Vec<&OpenedVault> {
        self.vaults.values().collect()
    }

    pub fn get_vault(&self, id: &str) -> Option<&OpenedVault> {
        self.vaults.get(id)
    }

    pub fn close_vault(&mut self, id: &str) {
        self.vaults.remove(id);
    }

    pub fn lock(&mut self) {
        self.vaults.clear();
        self.generation = None;
        self.locked = true;
    }

    pub fn sync_with_app(&mut self) -> Result<usize, BridgeError> {
        if self.locked {
            return Ok(0);
        }
        let status = bridge::fetch_session_status(self.config_dir.clone())?;
        if !status.unlocked {
            self.lock();
            self.generation = Some(status.generation);
            return Ok(0);
        }
        if self.generation.as_deref() != Some(status.generation.as_str()) {
            let count = self.open_vaults_from_app()?;
            self.generation = Some(status.generation);
            return Ok(count);
        }
        Ok(self.vaults.len())
    }

    pub fn unlock_from_app(&mut self) -> Result<usize, BridgeError> {
        self.locked = false;
        self.sync_with_app()
    }

    /// Opens every vault the desktop app has already unlocked.
    pub fn open_vaults_from_app(&mut self) -> Result<usize, BridgeError> {
        let vaults = bridge::fetch_vaults(self.config_dir.clone())?;
        let mut refreshed = VaultSession::with_config_dir(self.config_dir.clone());
        let mut count = 0;
        for data in vaults {
            if refreshed.open_vault(data).is_some() {
                count += 1;
            }
        }
        self.vaults = refreshed.vaults;
        Ok(count)
    }

    fn open_vault(&mut self, data: AppVaultData) -> Option<&OpenedVault> {
        let key = VaultKey::with_transformed_key(data.transformed_key);
        let vault = Vault::open(&data.kdbx_bytes, &key).ok()?;
        let name = vault.name().unwrap_or(&data.name).to_string();
        let id = data.id;
        let opened = OpenedVault {
            id: id.clone(),
            name,
            vault,
            kdf_fingerprint: data.kdf_fingerprint,
        };
        self.vaults.insert(id.clone(), opened);
        self.vaults.get(&id)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn explicit_lock_cannot_be_reopened_by_a_sensitive_request() {
        let mut session = VaultSession::new();
        session.lock();

        assert_eq!(session.sync_with_app().unwrap(), 0);
        assert!(session.is_empty());
    }
}
