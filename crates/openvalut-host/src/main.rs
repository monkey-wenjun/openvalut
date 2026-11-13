//! Chrome native messaging host entry point.
//!
//! Reads framed JSON requests from stdin and writes framed JSON responses to
//! stdout, implementing the Chrome native-messaging protocol.

use std::io;

use openvalut_host::dispatcher::MessageHandler;
use openvalut_host::framing::{read_frame, write_frame};
use openvalut_host::models::HostRequest;

fn main() -> io::Result<()> {
    let mut handler = MessageHandler::new();
    let mut stdin = io::stdin().lock();
    let mut stdout = io::stdout().lock();

    loop {
        let Some(payload) = read_frame(&mut stdin).map_err(|e| {
            io::Error::new(
                io::ErrorKind::InvalidData,
                format!("frame read failed: {e}"),
            )
        })?
        else {
            // Clean EOF: stdin closed, exit gracefully.
            return Ok(());
        };

        let request: HostRequest = match serde_json::from_slice(&payload) {
            Ok(req) => req,
            Err(e) => {
                let response = serde_json::json!({
                    "ok": false,
                    "error": format!("bad request: {e}"),
                    "code": "FAILED",
                });
                write_frame(
                    &mut stdout,
                    &serde_json::to_vec(&response).unwrap_or_default(),
                )?;
                continue;
            }
        };

        let response = handler.handle(&request);
        let bytes = serde_json::to_vec(&response).unwrap_or_default();
        write_frame(&mut stdout, &bytes)?;
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use openvalut_host::framing;

    #[test]
    fn handler_is_constructible_and_ping_round_trips() {
        let mut handler = MessageHandler::new();
        let request = HostRequest {
            method: "ping".into(),
            params: Default::default(),
            request_id: Some("req_1".into()),
        };
        let response = handler.handle(&request);
        assert!(response.ok);
        let bytes = serde_json::to_vec(&response).unwrap();
        let mut buf = Vec::new();
        framing::write_frame(&mut buf, &bytes).unwrap();
        assert!(!buf.is_empty());
    }
}
