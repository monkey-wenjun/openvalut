//! OpenValut server binary.
//!
//! Listens on `OPENVALUT_ADDR` / `-addr` (default `0.0.0.0:8080`) and stores
//! data in the database selected by `-db` / `-dsn`.

use std::env;

use openvalut_server::db::DbKind;

fn print_usage() {
    eprintln!(
        "Usage: openvalut-server [options]

Options:
  -addr <addr>        Listen address (default: 0.0.0.0:8080, env: OPENVALUT_ADDR)
  -db <sqlite|mysql|postgres>  Database kind (default: sqlite)
  -dsn <dsn>          Database DSN (default: openvalut.db, env: OPENVALUT_DSN)
  -key-file <path>    Server X25519 transport-envelope private key file
                      (default: /opt/openvalut-server/keys/server_key.bin,
                       env: SERVER_KEY_FILE; created if missing)
  -publish-key <key>  Key required to publish app releases (env: PUBLISH_KEY)
  -h, --help          Show this help message
"
    );
}

#[cfg(unix)]
fn load_or_generate_server_key(path: &str) -> anyhow::Result<[u8; 32]> {
    use std::os::unix::fs::PermissionsExt;
    use std::path::Path;

    if let Ok(data) = std::fs::read(path) {
        if data.len() == 32 {
            let mut key = [0u8; 32];
            key.copy_from_slice(&data);
            return Ok(key);
        }
        anyhow::bail!("server key file {path} has invalid length {}", data.len());
    }

    // Generate and persist (0600) a fresh key in a 0700 directory, mirroring
    // the Go server so `/api/server-key` is stable across restarts.
    let mut key = [0u8; 32];
    openvalut_core::secure_random_bytes(&mut key);
    if let Some(parent) = Path::new(path).parent() {
        std::fs::create_dir_all(parent)?;
        let _ = std::fs::set_permissions(parent, std::fs::Permissions::from_mode(0o700));
    }
    std::fs::write(path, key)?;
    let _ = std::fs::set_permissions(path, std::fs::Permissions::from_mode(0o600));
    Ok(key)
}

#[cfg(not(unix))]
fn load_or_generate_server_key(path: &str) -> anyhow::Result<[u8; 32]> {
    if let Ok(data) = std::fs::read(path) {
        if data.len() == 32 {
            let mut key = [0u8; 32];
            key.copy_from_slice(&data);
            return Ok(key);
        }
        anyhow::bail!("server key file {path} has invalid length {}", data.len());
    }
    let mut key = [0u8; 32];
    openvalut_core::secure_random_bytes(&mut key);
    if let Some(parent) = std::path::Path::new(path).parent() {
        std::fs::create_dir_all(parent)?;
    }
    std::fs::write(path, key)?;
    Ok(key)
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    let mut addr = env::var("OPENVALUT_ADDR").unwrap_or_else(|_| "0.0.0.0:8080".into());
    let mut db_kind = "sqlite".to_string();
    let mut dsn = env::var("OPENVALUT_DSN").unwrap_or_else(|_| "openvalut.db".into());
    let mut key_file = env::var("SERVER_KEY_FILE")
        .unwrap_or_else(|_| "/opt/openvalut-server/keys/server_key.bin".into());
    let mut publish_key = env::var("PUBLISH_KEY").ok();

    let args: Vec<String> = env::args().collect();
    let mut i = 1;
    while i < args.len() {
        match args[i].as_str() {
            "-h" | "--help" => {
                print_usage();
                return Ok(());
            }
            "-addr" => {
                i += 1;
                addr = args
                    .get(i)
                    .cloned()
                    .ok_or_else(|| anyhow::anyhow!("-addr requires a value"))?;
            }
            "-db" => {
                i += 1;
                db_kind = args
                    .get(i)
                    .cloned()
                    .ok_or_else(|| anyhow::anyhow!("-db requires a value"))?;
            }
            "-dsn" => {
                i += 1;
                dsn = args
                    .get(i)
                    .cloned()
                    .ok_or_else(|| anyhow::anyhow!("-dsn requires a value"))?;
            }
            "-key-file" => {
                i += 1;
                key_file = args
                    .get(i)
                    .cloned()
                    .ok_or_else(|| anyhow::anyhow!("-key-file requires a value"))?;
            }
            "-publish-key" => {
                i += 1;
                publish_key = args.get(i).cloned();
            }
            other => return Err(anyhow::anyhow!("unknown argument: {}", other)),
        }
        i += 1;
    }

    let db_kind: DbKind = db_kind.parse()?;
    let server_secret = load_or_generate_server_key(&key_file)?;
    openvalut_server::serve(&addr, db_kind, &dsn, server_secret, publish_key).await
}
