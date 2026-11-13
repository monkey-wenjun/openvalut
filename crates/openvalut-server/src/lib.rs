//! OpenValut server implementation.
//!
//! This crate provides the E2E-encrypted vault sync backend, compatible with
//! the existing Flutter and CLI clients. It mirrors the HTTP API and database
//! schema of the reference Go server in `server/`.

pub mod db;
pub mod error;
pub mod handlers;
pub mod middleware;
pub mod models;
pub mod oss;
pub mod state;

use axum::extract::DefaultBodyLimit;
use axum::routing::{delete, get, post, put};
use axum::Router;

use crate::db::DbKind;
use crate::middleware::{
    auth_middleware, logging_middleware, rate_limit_middleware, request_envelope_middleware,
    response_envelope_middleware,
};
use crate::state::AppState;

/// Build an axum [`Router`] for the OpenValut API.
pub fn router(state: AppState) -> Router {
    let public = Router::new()
        .route("/healthz", get(handlers::healthz))
        .route("/api/server-key", get(handlers::server_key))
        .route("/api/register", post(handlers::register))
        .route("/api/login", post(handlers::login))
        .route("/api/login/scan", post(handlers::create_scan_login))
        .route("/api/login/scan/:id", get(handlers::poll_scan_login))
        .route("/api/versions/latest", get(handlers::latest_version))
        .route(
            "/api/versions/publish",
            post(handlers::publish_version).layer(DefaultBodyLimit::max(100 * 1024 * 1024)),
        );

    let protected = Router::new()
        .route("/api/me", get(handlers::me))
        .route("/api/me/public-key", put(handlers::set_public_key))
        .route(
            "/api/users/:username/public-key",
            get(handlers::get_user_public_key),
        )
        .route(
            "/api/vaults",
            post(handlers::create_vault).get(handlers::list_vaults),
        )
        .route(
            "/api/vaults/:id",
            get(handlers::get_vault)
                .put(handlers::update_vault)
                .delete(handlers::delete_vault),
        )
        .route("/api/vaults/:id/meta", get(handlers::get_vault_meta))
        .route(
            "/api/vaults/:id/entries",
            post(handlers::upsert_entry).get(handlers::list_entries),
        )
        .route("/api/vaults/:id/entries/sync", post(handlers::sync_entries))
        .route(
            "/api/vaults/:id/entries/:uuid",
            delete(handlers::delete_entry),
        )
        .route("/api/vaults/:id/shares", post(handlers::create_share))
        .route(
            "/api/vaults/:id/group-shares",
            post(handlers::create_group_share),
        )
        .route("/api/shares/incoming", get(handlers::list_incoming_shares))
        .route("/api/shares/outgoing", get(handlers::list_outgoing_shares))
        .route("/api/shares/:id", delete(handlers::delete_share))
        .route(
            "/api/group-shares/incoming",
            get(handlers::list_incoming_group_shares),
        )
        .route(
            "/api/group-shares/outgoing",
            get(handlers::list_outgoing_group_shares),
        )
        .route(
            "/api/group-shares/:id",
            get(handlers::get_group_share).delete(handlers::delete_group_share),
        )
        .route(
            "/api/group-shares/:id/entries",
            post(handlers::upsert_group_share_entries),
        )
        .route(
            "/api/group-shares/:id/entries/:entry_uuid",
            delete(handlers::remove_group_share_entry),
        )
        .route(
            "/api/login/scan/:id/confirm",
            post(handlers::confirm_scan_login),
        )
        .layer(axum::middleware::from_fn_with_state(
            state.clone(),
            auth_middleware,
        ));

    Router::new()
        .merge(public)
        .merge(protected)
        .layer(axum::middleware::from_fn(response_envelope_middleware))
        .layer(axum::middleware::from_fn_with_state(
            state.clone(),
            request_envelope_middleware,
        ))
        .layer(axum::middleware::from_fn_with_state(
            state.clone(),
            rate_limit_middleware,
        ))
        .layer(axum::middleware::from_fn(logging_middleware))
        .with_state(state)
}

/// Run the server on `addr` using the given database configuration.
pub async fn serve(
    addr: &str,
    db_kind: DbKind,
    dsn: &str,
    server_secret: [u8; 32],
    publish_key: Option<String>,
) -> anyhow::Result<()> {
    let state = AppState::open(db_kind, dsn, server_secret, publish_key).await?;
    let listener = tokio::net::TcpListener::bind(addr).await?;
    tracing::info!("openvalut-server listening on {}", addr);
    axum::serve(
        listener,
        router(state).into_make_service_with_connect_info::<std::net::SocketAddr>(),
    )
    .await?;
    Ok(())
}
