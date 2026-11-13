//! Chrome native messaging frame encoding/decoding.
//!
//! Chrome's native messaging protocol uses a 4-byte little-endian length prefix
//! followed by a UTF-8 encoded JSON payload.

use std::io::{self, Read, Write};

/// Maximum allowed payload size in bytes (10 MiB), matching the Dart host.
pub const MAX_MESSAGE_SIZE: u32 = 10 * 1024 * 1024;

/// Size of the frame length prefix in bytes.
const LENGTH_BYTES: usize = 4;

/// Reads a single native-messaging frame from `input`.
///
/// Returns `Ok(None)` on a clean EOF before any frame bytes are read.
/// Returns an error if the length prefix exceeds [`MAX_MESSAGE_SIZE`] or if the
/// payload cannot be read.
pub fn read_frame<R: Read>(input: &mut R) -> Result<Option<Vec<u8>>, FrameError> {
    let mut length_bytes = [0u8; LENGTH_BYTES];
    match input.read_exact(&mut length_bytes) {
        Ok(()) => {}
        Err(e) if e.kind() == io::ErrorKind::UnexpectedEof => return Ok(None),
        Err(e) => return Err(FrameError::Io(e)),
    }

    let length = u32::from_le_bytes(length_bytes);
    if length > MAX_MESSAGE_SIZE {
        return Err(FrameError::Oversized(length));
    }

    let mut payload = vec![0u8; length as usize];
    input.read_exact(&mut payload)?;
    Ok(Some(payload))
}

/// Writes a native-messaging frame to `output`.
pub fn write_frame<W: Write>(output: &mut W, payload: &[u8]) -> io::Result<()> {
    let length: u32 = payload
        .len()
        .try_into()
        .map_err(|_| io::Error::new(io::ErrorKind::InvalidData, "payload exceeds u32"))?;
    if length > MAX_MESSAGE_SIZE {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            format!("payload exceeds max message size of {MAX_MESSAGE_SIZE}"),
        ));
    }

    output.write_all(&length.to_le_bytes())?;
    output.write_all(payload)?;
    output.flush()?;
    Ok(())
}

/// Errors that can occur while reading a frame.
#[derive(Debug)]
pub enum FrameError {
    Io(io::Error),
    Oversized(u32),
}

impl std::fmt::Display for FrameError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            FrameError::Io(e) => write!(f, "io error: {e}"),
            FrameError::Oversized(size) => {
                write!(f, "message size {size} exceeds maximum {MAX_MESSAGE_SIZE}")
            }
        }
    }
}

impl std::error::Error for FrameError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            FrameError::Io(e) => Some(e),
            FrameError::Oversized(_) => None,
        }
    }
}

impl From<io::Error> for FrameError {
    fn from(value: io::Error) -> Self {
        FrameError::Io(value)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn round_trip_single_frame() {
        let payload = b"{\"method\":\"ping\"}";
        let mut buf = Vec::new();
        write_frame(&mut buf, payload).unwrap();

        assert_eq!(&buf[..4], &(payload.len() as u32).to_le_bytes());
        assert_eq!(&buf[4..], payload);

        let mut cursor = io::Cursor::new(buf);
        let read = read_frame(&mut cursor).unwrap().unwrap();
        assert_eq!(read, payload);
    }

    #[test]
    fn read_multiple_frames_from_stream() {
        let p1 = b"{\"method\":\"ping\"}";
        let p2 = b"{\"method\":\"listVaults\"}";
        let mut buf = Vec::new();
        write_frame(&mut buf, p1).unwrap();
        write_frame(&mut buf, p2).unwrap();

        let mut cursor = io::Cursor::new(buf);
        assert_eq!(read_frame(&mut cursor).unwrap().unwrap(), p1);
        assert_eq!(read_frame(&mut cursor).unwrap().unwrap(), p2);
        assert!(read_frame(&mut cursor).unwrap().is_none());
    }

    #[test]
    fn clean_eof_returns_none() {
        let mut cursor = io::Cursor::new(&[] as &[u8]);
        assert!(read_frame(&mut cursor).unwrap().is_none());
    }

    #[test]
    fn oversized_message_is_rejected() {
        let length = (MAX_MESSAGE_SIZE + 1).to_le_bytes();
        let mut buf = Vec::from(length);
        buf.resize(buf.len() + (MAX_MESSAGE_SIZE as usize) + 1, 0u8);
        let mut cursor = io::Cursor::new(buf);
        let err = read_frame(&mut cursor).unwrap_err();
        assert!(matches!(err, FrameError::Oversized(size) if size == MAX_MESSAGE_SIZE + 1));
    }

    #[test]
    fn max_size_frame_is_allowed() {
        let payload = vec![b' '; MAX_MESSAGE_SIZE as usize];
        let mut buf = Vec::new();
        write_frame(&mut buf, &payload).unwrap();
        assert_eq!(buf.len(), LENGTH_BYTES + MAX_MESSAGE_SIZE as usize);
    }

    #[test]
    fn write_rejects_payload_above_max_size() {
        let payload = vec![b' '; (MAX_MESSAGE_SIZE as usize) + 1];
        let mut buf = Vec::new();
        assert!(write_frame(&mut buf, &payload).is_err());
    }
}
