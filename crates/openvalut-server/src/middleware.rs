//! Axum middleware for request logging, envelope decryption/encryption,
//! signed auth and rate limiting.

use std::collections::HashMap;
use std::net::IpAddr;
use std::sync::Arc;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use axum::body::Body;
use axum::extract::{Request, State};
use axum::http::header;
use axum::middleware::Next;
use axum::response::{IntoResponse, Response};
use base64::Engine;
use http_body_util::BodyExt;
use sha2::Digest;
use tokio::sync::Mutex;

use crate::error::ApiError;
use crate::models::{AuthUser, EnvelopeRecipient, PlainBody};
use crate::state::AppState;

pub(crate) const SIGNATURE_WINDOW_SEC: i64 = 300;

/// Request logging middleware.
pub async fn logging_middleware(req: Request, next: Next) -> Response {
    let method = req.method().clone();
    let path = req.uri().path().to_string();
    let start = std::time::Instant::now();
    let response = next.run(req).await;
    let elapsed = start.elapsed();
    let status = response.status().as_u16();
    tracing::info!("{} {} -> {} ({:?})", method, path, status, elapsed);
    response
}

// ---------------------------------------------------------------------------
// request envelope decryption
// ---------------------------------------------------------------------------

/// Decrypts an incoming request envelope.
///
/// When the body is JSON shaped as `{ "enc": "<base64>" }` the base64 blob is
/// decrypted using the server's X25519 private key and the plaintext replaces
/// the request body. The plaintext bytes are also attached as the `PlainBody`
/// extension so the auth middleware can verify signatures over them.
pub async fn request_envelope_middleware(
    State(state): State<AppState>,
    req: Request,
    next: Next,
) -> Response {
    match request_envelope_inner(state, req, next).await {
        Ok(response) => response,
        Err(e) => e.into_response(),
    }
}

async fn request_envelope_inner(
    state: AppState,
    req: Request,
    next: Next,
) -> Result<Response, ApiError> {
    let method = req.method().clone();
    let path = req.uri().path().to_string();
    let (mut parts, body) = req.into_parts();
    let collected = body
        .collect()
        .await
        .map_err(|e| ApiError::BadRequestMsg(format!("body: {e}")))?;
    let body_bytes = collected.to_bytes().to_vec();

    let plaintext = if body_bytes.is_empty() {
        Vec::new()
    } else {
        match serde_json::from_slice::<serde_json::Value>(&body_bytes) {
            Ok(serde_json::Value::Object(mut map)) if map.contains_key("enc") => {
                let enc = map
                    .remove("enc")
                    .and_then(|v| v.as_str().map(|s| s.to_string()))
                    .ok_or_else(|| ApiError::BadRequestMsg("bad envelope".into()))?;
                let blob = base64::engine::general_purpose::STANDARD
                    .decode(&enc)
                    .map_err(|_| ApiError::BadRequestMsg("bad envelope".into()))?;
                openvalut_core::envelope_decrypt(&state.server_secret, &blob)?
            }
            _ => body_bytes,
        }
    };

    parts.extensions.insert(PlainBody(plaintext.clone()));
    // Never log the (decrypted) body: requests such as /api/login carry the
    // user's Secret Key, which is the HMAC signing key. Log metadata only.
    tracing::info!(
        "request body: {} {} ({} bytes)",
        method,
        path,
        plaintext.len()
    );
    let req = Request::from_parts(parts, Body::from(plaintext));
    Ok(next.run(req).await)
}

// ---------------------------------------------------------------------------
// response envelope encryption
// ---------------------------------------------------------------------------

/// Encrypts outgoing JSON responses when the client requested an envelope.
///
/// The auth middleware stores the recipient's X25519 public key as the
/// `EnvelopeRecipient` request extension for authenticated routes. For the
/// public `/api/register` and `/api/login` endpoints the public key is read
/// from the plaintext request body. This middleware rewrites the response body
/// to `{"enc": "<base64>"}`.
pub async fn response_envelope_middleware(req: Request, next: Next) -> Response {
    let mut recipient = req.extensions().get::<EnvelopeRecipient>().copied();

    if recipient.is_none()
        && wants_envelope(req.headers())
        && is_public_envelope_route(req.uri().path())
    {
        if let Some(plain) = req.extensions().get::<PlainBody>() {
            recipient = public_key_from_body(&plain.0);
        }
    }

    let res = next.run(req).await;
    match recipient {
        Some(EnvelopeRecipient(key)) => encrypt_response(res, key).await,
        None => res,
    }
}

fn wants_envelope(headers: &axum::http::HeaderMap) -> bool {
    headers.get("x-envelope").and_then(|v| v.to_str().ok()) == Some("1")
}

fn is_public_envelope_route(path: &str) -> bool {
    path == "/api/register" || path == "/api/login"
}

fn public_key_from_body(body: &[u8]) -> Option<EnvelopeRecipient> {
    let value: serde_json::Value = serde_json::from_slice(body).ok()?;
    let pk = value.get("publicKey")?.as_str()?;
    let decoded = base64::engine::general_purpose::STANDARD
        .decode(pk.trim())
        .ok()?;
    decoded.try_into().ok().map(EnvelopeRecipient)
}

async fn encrypt_response(res: Response, recipient: [u8; 32]) -> Response {
    let (mut parts, body) = res.into_parts();
    let bytes = match body.collect().await {
        Ok(c) => c.to_bytes(),
        Err(e) => {
            tracing::error!("response envelope: failed to collect body: {e}");
            return ApiError::Internal.into_response();
        }
    };

    if bytes.is_empty() {
        return Response::from_parts(parts, Body::empty());
    }

    let encrypted = match openvalut_core::envelope_encrypt(&recipient, &bytes) {
        Ok(b) => b,
        Err(e) => {
            tracing::error!("response envelope: encrypt failed: {e}");
            return ApiError::Internal.into_response();
        }
    };

    let payload = serde_json::json!({
        "enc": base64::engine::general_purpose::STANDARD.encode(encrypted)
    });

    parts
        .headers
        .insert(header::CONTENT_TYPE, "application/json".parse().unwrap());
    Response::from_parts(parts, Body::from(payload.to_string()))
}

/// Try to store `public_key_b64` as the envelope recipient for this request.
pub fn set_envelope_recipient(extensions: &mut axum::http::Extensions, public_key_b64: &str) {
    let trimmed = public_key_b64.trim();
    if trimmed.is_empty() {
        return;
    }
    let Ok(decoded) = base64::engine::general_purpose::STANDARD.decode(trimmed) else {
        return;
    };
    let Ok(key) = decoded.try_into() else {
        return;
    };
    extensions.insert(EnvelopeRecipient(key));
}

// ---------------------------------------------------------------------------
// auth
// ---------------------------------------------------------------------------

/// Authenticated route middleware.
///
/// Requires a valid `Authorization: Bearer <token>` header and a valid
/// HMAC-SHA256 request signature in `X-Timestamp`, `X-Nonce`, `X-Signature`.
/// The signature key is the user's 32-char UUID.
pub async fn auth_middleware(
    State(state): State<AppState>,
    mut req: Request,
    next: Next,
) -> Response {
    let auth_header = match req
        .headers()
        .get("authorization")
        .and_then(|v| v.to_str().ok())
    {
        Some(h) => h,
        None => return ApiError::Unauthorized.into_response(),
    };

    let token = match auth_header
        .strip_prefix("Bearer ")
        .or_else(|| auth_header.strip_prefix("bearer "))
    {
        Some(t) => t,
        None => return ApiError::Unauthorized.into_response(),
    };

    let token_hash = hex::encode(sha2::Sha256::digest(token));
    let user_id = match state.db.user_id_by_token(&token_hash).await {
        Ok(id) => id,
        Err(_) => return ApiError::Unauthorized.into_response(),
    };
    let user = match state.db.user_by_id(&user_id).await {
        Ok(u) => u,
        Err(_) => return ApiError::Unauthorized.into_response(),
    };

    if let Err(e) = verify_signature(&state, &req, &user.id) {
        return e.into_response();
    }

    let wants_envelope = req
        .headers()
        .get("x-envelope")
        .and_then(|v| v.to_str().ok())
        == Some("1");
    if wants_envelope {
        set_envelope_recipient(req.extensions_mut(), &user.public_key);
    }

    req.extensions_mut().insert(AuthUser {
        id: user.id,
        username: user.username,
        public_key: if user.public_key.is_empty() {
            None
        } else {
            Some(user.public_key)
        },
    });

    next.run(req).await
}

fn verify_signature(state: &AppState, req: &Request, user_id: &str) -> Result<(), ApiError> {
    let timestamp = req
        .headers()
        .get("x-timestamp")
        .and_then(|v| v.to_str().ok())
        .ok_or(ApiError::Unauthorized)?;
    let nonce = req
        .headers()
        .get("x-nonce")
        .and_then(|v| v.to_str().ok())
        .ok_or(ApiError::Unauthorized)?;
    let signature = req
        .headers()
        .get("x-signature")
        .and_then(|v| v.to_str().ok())
        .ok_or(ApiError::Unauthorized)?;

    let ts: i64 = timestamp.parse().map_err(|_| ApiError::Unauthorized)?;
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs() as i64;
    if (now - ts).abs() > SIGNATURE_WINDOW_SEC {
        return Err(ApiError::Unauthorized);
    }

    if !state
        .nonce_cache
        .use_nonce(nonce, ts + SIGNATURE_WINDOW_SEC)
    {
        return Err(ApiError::Unauthorized);
    }

    let body = req
        .extensions()
        .get::<PlainBody>()
        .map(|b| b.0.clone())
        .unwrap_or_default();

    openvalut_core::verify_request_signature(
        user_id,
        req.method().as_str(),
        req.uri().path(),
        timestamp,
        nonce,
        &body,
        signature,
    )
    .map_err(|_| ApiError::Unauthorized)?;

    Ok(())
}

// ---------------------------------------------------------------------------
// rate limiting
// ---------------------------------------------------------------------------

/// Token-bucket rate limiter: 120 requests per minute with a burst of 30.
#[derive(Debug, Clone, Default)]
pub struct RateLimiter {
    inner: Arc<Mutex<HashMap<String, TokenBucket>>>,
}

impl RateLimiter {
    pub fn new() -> Self {
        Self::default()
    }

    /// Returns `true` when the request is allowed and `false` when it should be
    /// rejected with 429.
    pub async fn check(&self, ip: &str) -> bool {
        const RATE_PER_SEC: f64 = 120.0 / 60.0;
        const BURST: f64 = 30.0;

        let mut map = self.inner.lock().await;
        let now = Instant::now();
        map.retain(|_, bucket| now.duration_since(bucket.last) < Duration::from_secs(120));

        let bucket = map.entry(ip.to_string()).or_insert_with(|| TokenBucket {
            tokens: BURST,
            last: now,
        });

        let elapsed = now.duration_since(bucket.last).as_secs_f64();
        bucket.tokens = (bucket.tokens + elapsed * RATE_PER_SEC).min(BURST);
        bucket.last = now;

        if bucket.tokens >= 1.0 {
            bucket.tokens -= 1.0;
            true
        } else {
            false
        }
    }
}

#[derive(Debug, Clone)]
struct TokenBucket {
    tokens: f64,
    last: Instant,
}

/// Axum middleware that enforces per-IP rate limiting.
pub async fn rate_limit_middleware(
    State(state): State<AppState>,
    req: Request,
    next: Next,
) -> Response {
    let ip = client_ip(&req);
    let forwarded =
        req.headers().contains_key("x-forwarded-for") || req.headers().contains_key("x-real-ip");

    if should_rate_limit(&ip, forwarded) && !state.rate_limiter.check(&ip).await {
        let body = serde_json::json!({ "error": "rate limit exceeded" });
        return (axum::http::StatusCode::TOO_MANY_REQUESTS, axum::Json(body)).into_response();
    }

    next.run(req).await
}

fn client_ip(req: &Request) -> String {
    // Prefer X-Real-IP: the reverse proxy (nginx) overwrites it with the real
    // client address, so a client cannot spoof it through the proxy.
    if let Some(xri) = req.headers().get("x-real-ip").and_then(|v| v.to_str().ok()) {
        let xri = xri.trim();
        if !xri.is_empty() {
            return xri.to_string();
        }
    }

    // Otherwise take the LAST entry of X-Forwarded-For: nginx appends the real
    // client address last (`$proxy_add_x_forwarded_for`), so earlier entries
    // are client-controlled and must not be trusted as the rate-limit key.
    if let Some(xff) = req
        .headers()
        .get("x-forwarded-for")
        .and_then(|v| v.to_str().ok())
    {
        if let Some(last) = xff.rsplit(',').next() {
            let trimmed = last.trim();
            if !trimmed.is_empty() {
                return trimmed.to_string();
            }
        }
    }

    if let Some(addr) = req
        .extensions()
        .get::<axum::extract::ConnectInfo<std::net::SocketAddr>>()
    {
        return addr.ip().to_string();
    }

    req.uri()
        .authority()
        .map(|a| a.host().to_string())
        .unwrap_or_default()
}

fn should_rate_limit(ip: &str, forwarded: bool) -> bool {
    // If the request came through a proxy we always enforce the limit based on
    // the forwarded IP. We only skip loopback requests that were made directly
    // (no forwarding headers), which lets local/integration tests run without
    // hitting the bucket.
    if forwarded {
        return true;
    }
    match ip.parse::<IpAddr>() {
        Ok(addr) => !addr.is_loopback(),
        Err(_) => true,
    }
}

// ---------------------------------------------------------------------------
// nonce cache
// ---------------------------------------------------------------------------

/// Cache of nonces that have been used in valid signed requests.
#[derive(Debug, Clone, Default)]
pub struct NonceCache {
    inner: Arc<std::sync::Mutex<HashMap<String, i64>>>,
}

impl NonceCache {
    pub fn new() -> Self {
        Self::default()
    }

    /// Records a nonce as used. Returns false if the nonce is already present
    /// and has not expired.
    pub fn use_nonce(&self, nonce: &str, expires_at: i64) -> bool {
        let mut map = self.inner.lock().unwrap();
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs() as i64;
        map.retain(|_, exp| *exp > now);
        if map.contains_key(nonce) {
            return false;
        }
        map.insert(nonce.to_string(), expires_at);
        true
    }
}
