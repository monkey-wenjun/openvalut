//! Error handling for the OpenValut server.

use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use serde_json::json;

/// Errors that can be returned from API handlers.
#[derive(Debug, thiserror::Error)]
pub enum ApiError {
    #[error("bad request")]
    BadRequest,
    #[error("{0}")]
    BadRequestMsg(String),
    #[error("unauthorized")]
    Unauthorized,
    #[error("forbidden")]
    Forbidden,
    #[error("not found")]
    NotFound,
    #[error("gone")]
    Gone,
    #[error("conflict")]
    Conflict,
    #[error("internal server error")]
    Internal,
    #[error("{0}")]
    InternalMsg(String),
}

impl ApiError {
    pub fn status(&self) -> StatusCode {
        match self {
            ApiError::BadRequest | ApiError::BadRequestMsg(_) => StatusCode::BAD_REQUEST,
            ApiError::Unauthorized => StatusCode::UNAUTHORIZED,
            ApiError::Forbidden => StatusCode::FORBIDDEN,
            ApiError::NotFound => StatusCode::NOT_FOUND,
            ApiError::Gone => StatusCode::GONE,
            ApiError::Conflict => StatusCode::CONFLICT,
            ApiError::Internal | ApiError::InternalMsg(_) => StatusCode::INTERNAL_SERVER_ERROR,
        }
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let status = self.status();
        let message = self.to_string();
        let body = axum::Json(json!({ "error": message }));
        (status, body).into_response()
    }
}

impl From<sqlx::Error> for ApiError {
    fn from(e: sqlx::Error) -> Self {
        match e {
            sqlx::Error::RowNotFound => ApiError::NotFound,
            _ => ApiError::InternalMsg(format!("database error: {e}")),
        }
    }
}

impl From<openvalut_core::Error> for ApiError {
    fn from(e: openvalut_core::Error) -> Self {
        ApiError::BadRequestMsg(e.to_string())
    }
}

impl From<serde_json::Error> for ApiError {
    fn from(_: serde_json::Error) -> Self {
        ApiError::BadRequest
    }
}
