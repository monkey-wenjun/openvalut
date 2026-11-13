//! Rust Chrome native messaging host for OpenValut.
//!
//! Talks to the desktop app over the loopback app bridge (`host-bridge.json`)
//! to list/match entries, then serves the extension the same JSON methods the
//! original Dart host served.

pub mod bridge;
pub mod dispatcher;
pub mod framing;
pub mod matcher;
pub mod models;
pub mod passkey;
pub mod session;

pub use bridge::{AppVaultData, BridgeError};
pub use dispatcher::MessageHandler;
pub use models::{HostRequest, HostResponse};
