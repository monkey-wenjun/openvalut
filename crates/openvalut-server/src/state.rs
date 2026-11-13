//! Shared server state.

use base64::Engine;

use crate::db::{Db, DbKind};
use crate::middleware::{NonceCache, RateLimiter};
use crate::oss::OssConfig;

#[derive(Debug, Clone)]
pub struct AppState {
    pub db: Db,
    pub server_secret: [u8; 32],
    pub server_public: [u8; 32],
    pub nonce_cache: NonceCache,
    pub rate_limiter: RateLimiter,
    pub publish_key: Option<String>,
    pub oss: Option<OssConfig>,
}

impl AppState {
    pub async fn open(
        kind: DbKind,
        dsn: &str,
        server_secret: [u8; 32],
        publish_key: Option<String>,
    ) -> Result<Self, crate::error::ApiError> {
        let db = Db::open(kind, dsn).await?;
        let server_public = openvalut_core::x25519_public_from_secret(&server_secret);
        Ok(Self {
            db,
            server_secret,
            server_public,
            nonce_cache: NonceCache::new(),
            rate_limiter: RateLimiter::new(),
            publish_key: publish_key.or_else(|| std::env::var("PUBLISH_KEY").ok()),
            oss: OssConfig::from_env(),
        })
    }

    pub fn server_public_base64(&self) -> String {
        base64::engine::general_purpose::STANDARD.encode(self.server_public)
    }
}
