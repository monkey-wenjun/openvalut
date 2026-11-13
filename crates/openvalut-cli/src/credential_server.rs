//! CLI 自带的凭据服务：不打开桌面 App 也能让脚本读到凭据。
//!
//! 协议与 App 里的 credential server 完全一致：监听 `127.0.0.1:<随机端口>`，
//! 每行一个 JSON 请求/响应，token 放在 `<data dir>/openvalut.token`（0600），
//! 端口放在 `<data dir>/openvalut.port`。`openvalut-cli run/get/list/pam-setup`
//! 以及 `ov-ssh` 这类包装脚本读这两个文件后直接连过来。
//!
//! 支持的方法：
//! - `ping`      —— 探活
//! - `list`      —— 允许读取的条目元数据
//! - `get`       —— 单条条目的非敏感字段（label/group/file/allowed）
//! - `resolve`   —— Secret Reference（`ov://金库/条目/字段`）取值，含 TOTP
//! - `pamSetup`  —— 写 PAM TOTP 文件并返回路径

use std::fs;
use std::io::{BufRead, BufReader, Write};
use std::net::{TcpListener, TcpStream};
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::thread;
use std::time::{SystemTime, UNIX_EPOCH};

use keepass::db::fields;
use openvalut_core::secret_ref::{SecretReference, SecretReferenceField};
use serde_json::{json, Value};

use crate::{kdbx, pam_setup, totp};

pub struct ServeOptions {
    /// 固定端口；None 表示随机端口
    pub port: Option<u16>,
    /// credential server 数据目录（token/port 文件所在处）
    pub data_dir: PathBuf,
}

/// 启动服务，直到进程被结束。返回进程退出码。
pub fn serve(db: kdbx::Database, opts: &ServeOptions) -> i32 {
    let db = Arc::new(db);

    if let Some(port) = live_server_port(&opts.data_dir) {
        eprintln!(
            "error: 已经有一个凭据服务在跑（127.0.0.1:{port}）。\
             先停掉它（openvalut-cli lock 或 systemctl --user stop openvalut-serve），\
             或者用 --port 指定另一个端口。"
        );
        return 1;
    }

    let listener = match TcpListener::bind(("127.0.0.1", opts.port.unwrap_or(0))) {
        Ok(listener) => listener,
        Err(e) => {
            eprintln!("error: 无法监听 127.0.0.1：{e}");
            return 1;
        }
    };
    let port = match listener.local_addr() {
        Ok(addr) => addr.port(),
        Err(e) => {
            eprintln!("error: 无法获取监听端口：{e}");
            return 1;
        }
    };

    let files = match EndpointFiles::write(&opts.data_dir, port) {
        Ok(files) => files,
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };

    println!("凭据服务已启动：127.0.0.1:{port}");
    println!("  token: {}", files.token_path.display());
    println!("  port : {}", files.port_path.display());
    println!("（Ctrl-C 退出；长期运行建议用 systemd --user 托管）");

    for stream in listener.incoming() {
        match stream {
            Ok(stream) => {
                let db = Arc::clone(&db);
                let token = files.token.clone();
                thread::spawn(move || {
                    if let Err(e) = handle_connection(stream, &db, &token) {
                        eprintln!("warn: 连接处理失败：{e}");
                    }
                });
            }
            Err(e) => {
                eprintln!("error: accept 失败：{e}");
                break;
            }
        }
    }

    drop(files); // 移除 token/port，避免留下过期端点
    0
}

/// token/port 文件；drop 时清理（进程正常退出时不留垃圾）
struct EndpointFiles {
    token: String,
    token_path: PathBuf,
    port_path: PathBuf,
}

impl EndpointFiles {
    fn write(data_dir: &Path, port: u16) -> Result<Self, String> {
        fs::create_dir_all(data_dir)
            .map_err(|e| format!("无法创建 {}：{e}", data_dir.display()))?;
        let token = hex::encode(rand::random::<[u8; 16]>());
        let token_path = data_dir.join("openvalut.token");
        let port_path = data_dir.join("openvalut.port");

        fs::write(&token_path, &token).map_err(|e| format!("写入 token 失败：{e}"))?;
        fs::write(&port_path, port.to_string()).map_err(|e| format!("写入 port 失败：{e}"))?;
        for path in [&token_path, &port_path] {
            if let Err(e) = fs::set_permissions(path, fs::Permissions::from_mode(0o600)) {
                eprintln!("warn: 无法把 {} 设为 0600：{e}", path.display());
            }
        }
        Ok(Self {
            token,
            token_path,
            port_path,
        })
    }
}

impl Drop for EndpointFiles {
    fn drop(&mut self) {
        let _ = fs::remove_file(&self.token_path);
        let _ = fs::remove_file(&self.port_path);
    }
}

/// 已有服务在跑时返回其端口（token/port 文件 + ping 探活）
fn live_server_port(data_dir: &Path) -> Option<u16> {
    let token = fs::read_to_string(data_dir.join("openvalut.token")).ok()?;
    let port: u16 = fs::read_to_string(data_dir.join("openvalut.port"))
        .ok()?
        .trim()
        .parse()
        .ok()?;
    let request = json!({"id": 1, "token": token.trim(), "method": "ping", "params": {}});
    let mut stream = TcpStream::connect(("127.0.0.1", port)).ok()?;
    stream.write_all(format!("{request}\n").as_bytes()).ok()?;
    let mut reader = BufReader::new(stream);
    let mut line = String::new();
    reader.read_line(&mut line).ok()?;
    let ok = serde_json::from_str::<Value>(line.trim())
        .ok()?
        .get("ok")
        .and_then(Value::as_bool)
        .unwrap_or(false);
    ok.then_some(port)
}

fn handle_connection(
    mut stream: TcpStream,
    db: &kdbx::Database,
    token: &str,
) -> Result<(), String> {
    let reader_stream = stream.try_clone().map_err(|e| e.to_string())?;
    let mut reader = BufReader::new(reader_stream);
    let mut line = String::new();
    loop {
        line.clear();
        let read = reader.read_line(&mut line).map_err(|e| e.to_string())?;
        if read == 0 {
            return Ok(());
        }
        let trimmed = line.trim();
        if trimmed.is_empty() {
            continue;
        }
        let response = handle_line(db, token, trimmed);
        let mut payload = serde_json::to_string(&response).map_err(|e| e.to_string())?;
        payload.push('\n');
        stream
            .write_all(payload.as_bytes())
            .map_err(|e| e.to_string())?;
        stream.flush().map_err(|e| e.to_string())?;
    }
}

fn handle_line(db: &kdbx::Database, token: &str, line: &str) -> Value {
    let request: Value = match serde_json::from_str(line) {
        Ok(value) => value,
        Err(_) => return error_response(Value::Null, "invalid json"),
    };
    let id = request.get("id").cloned().unwrap_or(Value::Null);
    if request.get("token").and_then(Value::as_str) != Some(token) {
        return error_response(id, "unauthorized");
    }
    let method = request.get("method").and_then(Value::as_str).unwrap_or("");
    let params = request
        .get("params")
        .cloned()
        .unwrap_or_else(|| Value::Object(serde_json::Map::new()));

    let result = match method {
        "ping" => Ok(json!({"pong": true})),
        "list" => Ok(json!({"entries": list_entries(db)})),
        "get" => get_metadata(db, &params),
        "resolve" => resolve(db, &params),
        "pamSetup" => pam_setup_remote(db),
        other => Err(format!("unknown method: {other}")),
    };
    match result {
        Ok(data) => ok_response(id, data),
        Err(message) => error_response(id, &message),
    }
}

fn list_entries(db: &kdbx::Database) -> Vec<Value> {
    kdbx::list_readable_entries(db)
        .into_iter()
        .map(|entry| {
            json!({
                "label": entry.title,
                "username": entry.username,
                "group": entry.group,
                "file": entry.file,
                "allowed": true,
            })
        })
        .collect()
}

fn get_metadata(db: &kdbx::Database, params: &Value) -> Result<Value, String> {
    let query = params
        .get("query")
        .and_then(Value::as_str)
        .unwrap_or("")
        .trim()
        .to_lowercase();
    let field = params
        .get("field")
        .and_then(Value::as_str)
        .unwrap_or("label")
        .to_lowercase();
    if !matches!(
        field.as_str(),
        "label" | "group" | "file" | "allowed" | "json"
    ) {
        return Err(format!(
            "get only returns non-sensitive metadata; use resolve with a Secret Reference for {field}"
        ));
    }
    let entry = find_allowed_entry(db, &query).ok_or_else(|| "no matching entry".to_string())?;
    if field == "json" {
        return Ok(json!({
            "label": entry.title,
            "username": entry.username,
            "group": entry.group,
            "file": entry.file,
            "allowed": true,
        }));
    }
    let value = match field.as_str() {
        "group" => entry.group,
        "file" => entry.file,
        "allowed" => "true".to_string(),
        _ => entry.title,
    };
    Ok(Value::String(value))
}

fn resolve(db: &kdbx::Database, params: &Value) -> Result<Value, String> {
    let reference = params
        .get("reference")
        .and_then(Value::as_str)
        .unwrap_or("")
        .trim();
    if reference.is_empty() {
        return Err("missing reference".to_string());
    }
    let parsed = SecretReference::parse(reference).map_err(|e| e.to_string())?;
    // CLI 一次只解锁一个库，所以金库名不再严格比对（App 里是多库，需要比对）。
    let entry = find_allowed_entry(db, &parsed.entry_query.to_lowercase())
        .ok_or_else(|| "unable to resolve reference".to_string())?;
    let entry_ref = db
        .entry(entry.id)
        .ok_or_else(|| "unable to resolve reference".to_string())?;

    match parsed.field {
        SecretReferenceField::Title => Ok(Value::String(value(&entry_ref, fields::TITLE))),
        SecretReferenceField::Username => Ok(Value::String(value(&entry_ref, fields::USERNAME))),
        SecretReferenceField::Password => Ok(Value::String(value(&entry_ref, fields::PASSWORD))),
        SecretReferenceField::Url => Ok(Value::String(value(&entry_ref, fields::URL))),
        SecretReferenceField::Notes => Ok(Value::String(value(&entry_ref, fields::NOTES))),
        SecretReferenceField::AccessKey => {
            Ok(Value::String(value(&entry_ref, kdbx::ACCESS_KEY_FIELD)))
        }
        SecretReferenceField::SecretKey => {
            Ok(Value::String(value(&entry_ref, kdbx::SECRET_KEY_FIELD)))
        }
        SecretReferenceField::Totp => {
            let secret = kdbx::entry_value(&entry_ref, kdbx::OTP_FIELD)
                .ok_or_else(|| "entry has no OTPAuth field".to_string())?;
            let config =
                totp::parse_otp_auth(&secret).ok_or_else(|| "invalid OTPAuth value".to_string())?;
            let now = SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .map(|d| d.as_secs())
                .unwrap_or(0);
            let (code, remaining) = totp::generate(&config, now);
            Ok(json!({"code": code, "period": remaining}))
        }
    }
}

fn pam_setup_remote(db: &kdbx::Database) -> Result<Value, String> {
    let machine_id =
        pam_setup::machine_id().ok_or_else(|| "无法读取 /etc/machine-id".to_string())?;
    let entry = kdbx::find_computer_entry(db, &machine_id)
        .ok_or_else(|| "未找到当前计算机的条目".to_string())?;
    let entry_ref = db
        .entry(entry.id)
        .ok_or_else(|| "未找到当前计算机的条目".to_string())?;
    let secret = kdbx::entry_value(&entry_ref, kdbx::OTP_FIELD)
        .filter(|v| !v.is_empty())
        .ok_or_else(|| "计算机条目未配置两步验证码（OTP）".to_string())?;
    let config = totp::parse_otp_auth(&secret).ok_or_else(|| "无效的两步验证码配置".to_string())?;
    let raw = base32::encode(base32::Alphabet::Rfc4648 { padding: false }, &config.secret);
    let path = pam_setup::write_encrypted_totp(&raw)?;
    Ok(json!({"path": path.display().to_string()}))
}

fn value(entry: &keepass::db::EntryRef<'_>, key: &str) -> String {
    kdbx::entry_value(entry, key).unwrap_or_default()
}

/// 只在「允许读取」的条目里匹配：全等（title/username）优先，其次子串。
fn find_allowed_entry(db: &kdbx::Database, query: &str) -> Option<kdbx::EntryInfo> {
    let entries = kdbx::list_readable_entries(db);
    if query.is_empty() {
        return entries.into_iter().next();
    }
    for entry in &entries {
        if entry.title.to_lowercase() == query || entry.username.to_lowercase() == query {
            return Some(entry.clone());
        }
    }
    entries.into_iter().find(|entry| {
        entry.title.to_lowercase().contains(query) || entry.username.to_lowercase().contains(query)
    })
}

fn ok_response(id: Value, data: Value) -> Value {
    json!({"id": id, "ok": true, "data": data})
}

fn error_response(id: Value, message: &str) -> Value {
    json!({"id": id, "ok": false, "error": message})
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::kdbx;

    fn sample_db(allowed: bool) -> kdbx::Database {
        let bytes = kdbx::create_empty("我的密码库", "pw").unwrap();
        let mut db = kdbx::load(&bytes, "pw", None).unwrap();
        let id = kdbx::add_entry(
            &mut db,
            &kdbx::EntryChanges {
                title: Some("root-server".into()),
                username: Some("alice".into()),
                password: Some("s3cr3t".into()),
                ..Default::default()
            },
        )
        .unwrap();
        if allowed {
            let mut entry = db.entry_mut(id).expect("entry");
            entry.set_unprotected(kdbx::READ_ALLOWED_FIELD, "1");
        }
        db
    }

    fn request(db: &kdbx::Database, token: &str, line: &str) -> Value {
        handle_line(db, token, line)
    }

    #[test]
    fn resolve_returns_field_value() {
        let db = sample_db(true);
        let response = request(
            &db,
            "tok",
            r#"{"id":1,"token":"tok","method":"resolve","params":{"reference":"ov://我的密码库/root-server/password"}}"#,
        );
        assert_eq!(response["ok"], json!(true), "{response}");
        assert_eq!(response["data"], json!("s3cr3t"));
    }

    #[test]
    fn resolve_is_denied_without_allow_mark() {
        let db = sample_db(false);
        let response = request(
            &db,
            "tok",
            r#"{"id":1,"token":"tok","method":"resolve","params":{"reference":"ov://我的密码库/root-server/password"}}"#,
        );
        assert_eq!(response["ok"], json!(false));
    }

    #[test]
    fn wrong_token_is_rejected() {
        let db = sample_db(true);
        let response = request(
            &db,
            "tok",
            r#"{"id":1,"token":"nope","method":"list","params":{}}"#,
        );
        assert_eq!(response["error"], json!("unauthorized"));
    }

    #[test]
    fn resolve_reads_ak_sk_fields() {
        let bytes = kdbx::create_empty("我的密码库", "pw").unwrap();
        let mut db = kdbx::load(&bytes, "pw", None).unwrap();
        let id = kdbx::add_entry(
            &mut db,
            &kdbx::EntryChanges {
                title: Some("Ark".into()),
                access_key: Some("AKLTabcdef".into()),
                secret_key: Some("s3cr3tSK".into()),
                ..Default::default()
            },
        )
        .unwrap();
        let mut entry = db.entry_mut(id).expect("entry");
        entry.set_unprotected(kdbx::READ_ALLOWED_FIELD, "1");

        for (field, expected) in [("access-key", "AKLTabcdef"), ("sk", "s3cr3tSK")] {
            let response = request(
                &db,
                "tok",
                &format!(
                    r#"{{"id":1,"token":"tok","method":"resolve","params":{{"reference":"ov://我的密码库/Ark/{field}"}}}}"#
                ),
            );
            assert_eq!(response["ok"], json!(true), "{response}");
            assert_eq!(response["data"], json!(expected), "{field}");
        }
    }

    #[test]
    fn get_only_surfaces_metadata() {
        let db = sample_db(true);
        let response = request(
            &db,
            "tok",
            r#"{"id":1,"token":"tok","method":"get","params":{"query":"root-server","field":"label"}}"#,
        );
        assert_eq!(response["data"], json!("root-server"));

        let denied = request(
            &db,
            "tok",
            r#"{"id":1,"token":"tok","method":"get","params":{"query":"root-server","field":"password"}}"#,
        );
        assert_eq!(denied["ok"], json!(false));
    }

    #[test]
    fn list_only_returns_allowed_entries() {
        let allowed = request(
            &sample_db(true),
            "tok",
            r#"{"id":1,"token":"tok","method":"list","params":{}}"#,
        );
        assert_eq!(allowed["data"]["entries"].as_array().map(Vec::len), Some(1));

        let denied = request(
            &sample_db(false),
            "tok",
            r#"{"id":1,"token":"tok","method":"list","params":{}}"#,
        );
        assert_eq!(denied["data"]["entries"].as_array().map(Vec::len), Some(0));
    }
}
