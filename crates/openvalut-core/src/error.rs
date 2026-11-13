//! Error types for openvalut-core.

use thiserror::Error;

pub type Result<T> = std::result::Result<T, Error>;

#[derive(Debug, Error)]
pub enum Error {
    #[error("KDBX error: {0}")]
    Kdbx(String),

    #[error("cryptographic error: {0}")]
    Crypto(String),

    #[error("invalid credentials")]
    InvalidCredentials,

    #[error("invalid key format")]
    InvalidKey,

    #[error("entry not found")]
    EntryNotFound,

    #[error("group not found")]
    GroupNotFound,

    #[error("vault not found")]
    VaultNotFound,

    #[error("serialization error: {0}")]
    Serialization(#[from] serde_json::Error),

    #[error("invalid argument: {0}")]
    InvalidArgument(String),

    #[error("io error: {0}")]
    Io(#[from] std::io::Error),

    #[error(transparent)]
    Other(#[from] anyhow::Error),
}

impl From<keepass::db::DatabaseOpenError> for Error {
    fn from(e: keepass::db::DatabaseOpenError) -> Self {
        Error::Kdbx(e.to_string())
    }
}

impl From<keepass::db::DatabaseSaveError> for Error {
    fn from(e: keepass::db::DatabaseSaveError) -> Self {
        Error::Kdbx(e.to_string())
    }
}
