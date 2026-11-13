// openvalut-cli: access OpenValut credentials.
//
// Two operation modes:
//  - default: talk to the credential server of a running, unlocked app
//    (read-only; see docs/credential-server.md). When the server is not
//    running, list/pam-setup fall back to the last `--db` local vault.
//  - standalone: open a KDBX file (--db) or an OpenValut Cloud vault (--cloud)
//    directly with the master password, including item add/edit/delete.
//
// Usage:
//   openvalut-cli list [query]
//   openvalut-cli get <query> [--field label|group|file|allowed]
//   openvalut-cli run --env NAME=op://vault/item/field [--env ...] -- <command> [args...]
//   openvalut-cli pam-setup
//   openvalut-cli --db <vault.kdbx> [--key-file <f>] item add <title> [options]
//   openvalut-cli --db <vault.kdbx> [--key-file <f>] item allow|deny <query>
//   openvalut-cli --cloud --email <e> --secret-key <key> item edit <query> [options]
use serde_json::{json, Map, Value};
use std::collections::HashMap;
use std::env;
use std::fs;
use std::io::{self, BufRead, BufReader, Write};
use std::net::TcpStream;
use std::path::{Path, PathBuf};
use std::process::{Command, ExitCode};

use data_encoding::BASE64;

mod auth;
mod cloud;
mod credential_server;
mod dotenv;
mod kdbx;
mod keychain;
mod pam_setup;
mod row_store;
mod scan_login;
mod ssh_agent;
mod totp;

fn main() -> ExitCode {
    let args: Vec<String> = env::args().skip(1).collect();
    ExitCode::from(run(&args) as u8)
}

fn run(args: &[String]) -> i32 {
    let mut opts = match parse_args(args) {
        Some(opts) => opts,
        None => {
            usage();
            return 2;
        }
    };
    if opts.help {
        usage();
        return 0;
    }
    // Commands that used to print the secret / one-time password to the
    // terminal are removed regardless of whether the app is running.
    if let Some(c) = opts.command.as_deref() {
        if matches!(c, "read" | "export" | "sudo" | "totp") {
            eprintln!("error: {c} 已移除：该命令会在终端输出密码或一次性密码");
            return 2;
        }
    }
    if opts.db.is_some()
        || opts.cloud
        || matches!(
            opts.command.as_deref(),
            Some("agent" | "auth" | "exec" | "unlock" | "lock")
        )
    {
        return run_standalone(opts);
    }

    // When the credential server is not running, fall back to the local KDBX
    // remembered by the last successful `--db` run so the CLI still works
    // without the desktop app.
    if matches!(
        opts.command.as_deref(),
        Some("list" | "pam-setup" | "serve")
    ) {
        if let Some(home) = home_dir() {
            let base = credential_server_data_dir(&home);
            let token_path = opts
                .token
                .clone()
                .unwrap_or_else(|| base.join("openvalut.token"));
            if !token_path.is_file() {
                if let Some((db, key_file)) = load_default_vault(&home) {
                    if db.exists() {
                        opts.db = Some(db);
                        if opts.key_file.is_none() {
                            opts.key_file = key_file;
                        }
                        return run_standalone(opts);
                    }
                }
            }
        }
    }
    run_socket(opts)
}

// ---------------------------------------------------------------------------
// options
// ---------------------------------------------------------------------------

#[derive(Default)]
struct Options {
    help: bool,
    token: Option<PathBuf>,
    port: Option<String>,
    field: Option<String>,
    command: Option<String>,
    query: String,
    run_envs: Vec<(String, String)>,
    run_command: Vec<String>,
    db: Option<PathBuf>,
    key_file: Option<PathBuf>,
    cloud: bool,
    server: Option<String>,
    email: Option<String>,
    secret_key: Option<String>,
    password: Option<String>,
    password_stdin: bool,
    sudo_mode: bool,
    scan: bool,
    vault: Option<String>,
    item_fields: ItemFields,
    item_target: Option<String>,
    vault_name: Option<String>,
    item_empty_title_delete: bool,
    list_uuids: bool,
}

#[derive(Default)]
struct ItemFields {
    title: Option<String>,
    username: Option<String>,
    password: Option<String>,
    password_stdin: bool,
    url: Option<String>,
    notes: Option<String>,
    otp: Option<String>,
    otp_stdin: bool,
    group: Option<String>,
    machine_id: Option<String>,
    ssh_private_key: Option<PathBuf>,
    access_key: Option<String>,
    secret_key: Option<String>,
    // 和 --password-field-stdin / --otp-stdin 一个道理：AK/SK 也不该出现在
    // 命令行里（`ps` 一眼就能看到）。`--ak-stdin`/`--sk-stdin` 从 stdin 按
    // 出现顺序各读一行。
    ak_stdin: bool,
    sk_stdin: bool,
}

fn parse_args(args: &[String]) -> Option<Options> {
    let mut help = false;
    let mut token = None;
    let mut port = None;
    let mut field = None;
    let mut db = None;
    let mut key_file = None;
    let mut cloud_mode = false;
    let mut server = None;
    let mut email = None;
    let mut secret_key = None;
    let mut password = None;
    let mut password_stdin = false;
    let mut sudo_mode = false;
    let mut scan = false;
    let mut vault = None;
    let mut item_fields = ItemFields::default();
    let mut item_target = None;
    let mut vault_name = None;
    let mut item_empty_title_delete = false;
    let mut list_uuids = false;
    let mut run_envs: Vec<(String, String)> = Vec::new();
    let mut run_command: Vec<String> = Vec::new();
    let mut positional: Vec<String> = Vec::new();

    let take_value = |args: &[String], i: &mut usize| -> Option<String> {
        *i += 1;
        args.get(*i).cloned()
    };

    let mut i = 0;
    while i < args.len() {
        match args[i].as_str() {
            "--help" | "-h" => help = true,
            "--token" => token = Some(PathBuf::from(take_value(args, &mut i)?)),
            "--port" => port = Some(take_value(args, &mut i)?),
            "--field" => field = Some(take_value(args, &mut i)?),
            "--env" => {
                let value = take_value(args, &mut i)?;
                let (key, reference) = value.split_once('=')?;
                run_envs.push((key.to_string(), reference.to_string()));
            }
            "--" => {
                // Everything after `--` is the command to execute.
                run_command.extend(args[i + 1..].iter().cloned());
                break;
            }
            "--db" => db = Some(PathBuf::from(take_value(args, &mut i)?)),
            "--key-file" => key_file = Some(PathBuf::from(take_value(args, &mut i)?)),
            "--cloud" => cloud_mode = true,
            "--server" => server = Some(take_value(args, &mut i)?),
            "--email" => email = Some(take_value(args, &mut i)?),
            "--secret-key" => secret_key = Some(take_value(args, &mut i)?),
            "--password" => password = Some(take_value(args, &mut i)?),
            "--password-stdin" => password_stdin = true,
            "--sudo" => sudo_mode = true,
            // QR-code login: with `auth login` and `unlock`, create a scan
            // session and wait for the phone to confirm instead of prompting.
            "--scan" => scan = true,
            "--vault" => vault = Some(take_value(args, &mut i)?),
            "--title" => item_fields.title = Some(take_value(args, &mut i)?),
            "--username" => item_fields.username = Some(take_value(args, &mut i)?),
            "--password-field" => item_fields.password = Some(take_value(args, &mut i)?),
            "--password-field-stdin" => item_fields.password_stdin = true,
            "--url" => item_fields.url = Some(take_value(args, &mut i)?),
            "--notes" => item_fields.notes = Some(take_value(args, &mut i)?),
            "--otp" => item_fields.otp = Some(take_value(args, &mut i)?),
            // 和 --password-field-stdin 一个思路：TOTP secret 也不该出现在命令行里（ps 能看到）
            "--otp-stdin" => item_fields.otp_stdin = true,
            "--group" => item_fields.group = Some(take_value(args, &mut i)?),
            "--machine-id" => item_fields.machine_id = Some(take_value(args, &mut i)?),
            "--ssh-private-key" => {
                item_fields.ssh_private_key = Some(PathBuf::from(take_value(args, &mut i)?))
            }
            // AK/SK entry fields. `--secret-key` is already taken by the cloud
            // account Secret Key, so the entry fields spell it out.
            "--access-key-id" | "--ak" => item_fields.access_key = Some(take_value(args, &mut i)?),
            "--secret-access-key" | "--sk" => {
                item_fields.secret_key = Some(take_value(args, &mut i)?)
            }
            "--ak-stdin" => item_fields.ak_stdin = true,
            "--sk-stdin" => item_fields.sk_stdin = true,
            "--empty-title" => item_empty_title_delete = true,
            "--uuids" => list_uuids = true,
            arg if arg.starts_with("--") => return None,
            arg => positional.push(arg.to_string()),
        }
        i += 1;
    }
    let command = positional.first().cloned();
    let query = positional.get(1).cloned().unwrap_or_default();
    if positional.len() == 3 {
        let third = positional.get(2).cloned();
        match (command.as_deref(), query.as_str()) {
            // `item add <title>`: the third positional is the entry title.
            (Some("item"), "add") => {
                if item_fields.title.is_none() {
                    item_fields.title = third;
                }
            }
            // `item edit|delete|allow|deny <target>`: the third positional is the
            // entry to operate on.
            (Some("item"), "edit" | "delete" | "allow" | "deny") => item_target = third,
            (Some("item"), "import-env") => item_target = third,
            (Some("agent"), "add" | "remove") => item_target = third,
            // `rows delete <uuids>`: the third positional is the uuid list.
            (Some("rows"), "delete") => item_target = third,
            // `rows dump <file.json>`: the third positional is the output path.
            (Some("rows"), "dump") => item_target = third,
            // `vault create <name>`: the third positional is the vault name.
            (Some("vault"), "create") => vault_name = third,
            _ => return None,
        }
    } else if command.as_deref() == Some("run") && run_command.is_empty() {
        // `run [--env ...] <command> [args...]`: positional after `run` is the
        // command to execute. Using `--` makes this explicit and is preferred.
        run_command = positional.into_iter().skip(1).collect();
    } else if positional.len() > 2 {
        return None;
    }
    Some(Options {
        help,
        token,
        port,
        field,
        command,
        query,
        run_envs,
        run_command,
        db,
        key_file,
        cloud: cloud_mode,
        server,
        email,
        secret_key,
        password,
        password_stdin,
        sudo_mode,
        scan,
        vault,
        item_fields,
        item_target,
        vault_name,
        item_empty_title_delete,
        list_uuids,
    })
}

// ---------------------------------------------------------------------------
// socket mode (existing read-only behavior)
// ---------------------------------------------------------------------------

fn run_socket(opts: Options) -> i32 {
    let home = match home_dir() {
        Some(home) => home,
        None => {
            eprintln!("error: cannot determine home directory");
            return 1;
        }
    };
    let base = credential_server_data_dir(&home);
    let token_path = opts
        .token
        .clone()
        .unwrap_or_else(|| base.join("openvalut.token"));

    let token = match fs::read_to_string(&token_path) {
        Ok(text) => text.trim().to_string(),
        Err(e) => {
            if e.kind() == io::ErrorKind::NotFound {
                eprintln!(
                    "error: OpenValut credential server is not running (no {}). \
                     Open the app with an unlocked vault, or run once with \
                     `--db <vault.kdbx>` to remember a default local vault \
                     for standalone use.",
                    token_path.display()
                );
            } else {
                eprintln!("error: {e}");
            }
            return 1;
        }
    };

    let port_override = opts.port.clone();
    let port_text = match &port_override {
        Some(text) => text.clone(),
        None => match fs::read_to_string(base.join("openvalut.port")) {
            Ok(text) => text.trim().to_string(),
            Err(e) => {
                eprintln!("error: {e}");
                return 1;
            }
        },
    };
    let port: u16 = match port_text.parse() {
        Ok(port) => port,
        Err(_) => {
            let label =
                port_override.unwrap_or_else(|| base.join("openvalut.port").display().to_string());
            eprintln!("error: corrupt port file {label}");
            return 1;
        }
    };

    if opts.command.as_deref() == Some("run") {
        return run_subprocess(port, &token, &opts.run_envs, &opts.run_command);
    }
    if opts.command.as_deref() == Some("serve") {
        eprintln!(
            "error: 已经有一个凭据服务在跑（127.0.0.1:{port}）。\
             先 `openvalut-cli lock` 或停掉 systemd 单元，再启动新的 serve。"
        );
        return 1;
    }

    let method = match opts.command.as_deref() {
        Some("list") => "list",
        Some("get") => "get",
        Some("pam-setup") => "pamSetup",
        _ => {
            usage();
            return 2;
        }
    };

    let mut params = Map::new();
    if !opts.query.is_empty() {
        params.insert("query".to_string(), Value::String(opts.query.clone()));
    }
    if let Some(field) = &opts.field {
        params.insert("field".to_string(), Value::String(field.clone()));
    }

    let response = match request(port, &token, method, &params) {
        Ok(response) => response,
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };
    if !response.ok {
        eprintln!(
            "error: {}",
            response.error.as_deref().unwrap_or("unknown error")
        );
        return 1;
    }

    print_socket_response(method, opts.field.as_deref(), &opts.query, response.data);
    0
}

/// Resolves each Secret Reference in `envs` through the credential server,
/// then executes `command` with the resolved values injected as environment
/// variables. The subprocess inherits stdio and its exit code is returned.
fn run_subprocess(port: u16, token: &str, envs: &[(String, String)], command: &[String]) -> i32 {
    if command.is_empty() {
        eprintln!("error: run 需要指定要执行的命令，例如 openvalut-cli run --env PASS=op://... -- 命令及其参数");
        return 2;
    }
    if let Err(reason) = reject_secret_dump(command, envs) {
        eprintln!("error: run 拒绝执行：{reason}。密钥只能注入给真正消费它的命令，禁止用 echo/printenv 等回显密钥");
        return 2;
    }

    let mut resolved_envs: Vec<(String, String)> = Vec::with_capacity(envs.len());
    for (key, reference) in envs {
        let mut params = Map::new();
        params.insert("reference".to_string(), Value::String(reference.clone()));
        let response = match request(port, token, "resolve", &params) {
            Ok(response) => response,
            Err(e) => {
                eprintln!("error: failed to resolve {reference}: {e}");
                return 1;
            }
        };
        if !response.ok {
            eprintln!(
                "error: failed to resolve {reference}: {}",
                response.error.as_deref().unwrap_or("unknown error")
            );
            return 1;
        }
        let value = match response.data {
            Some(Value::String(text)) => text,
            Some(Value::Object(mut map)) => map
                .remove("code")
                .and_then(|v| v.as_str().map(String::from))
                .unwrap_or_default(),
            _ => String::new(),
        };
        resolved_envs.push((key.clone(), value));
    }

    let program = &command[0];
    let args = &command[1..];
    let status = match Command::new(program)
        .args(args)
        .envs(resolved_envs)
        .status()
    {
        Ok(status) => status,
        Err(e) => {
            eprintln!("error: failed to execute {program}: {e}");
            return 1;
        }
    };
    status.code().unwrap_or(1)
}

/// Guards `run` from becoming a secret-dumping tool: commands whose only
/// purpose is to echo the injected environment back to the terminal/pipe are
/// rejected, so neither a user nor an agent can print vault secrets.
fn reject_secret_dump(command: &[String], envs: &[(String, String)]) -> Result<(), String> {
    if command.is_empty() || envs.is_empty() {
        return Ok(());
    }
    let program = command[0].split('/').next_back().unwrap_or(&command[0]);
    let args = &command[1..];

    let references_var = |argv: &[String]| {
        envs.iter().any(|(key, _)| {
            argv.iter()
                .any(|arg| arg == key || arg == &format!("${key}") || arg == &format!("${{{key}}}"))
        })
    };

    match program {
        // `env` / `printenv` dump the whole environment by themselves.
        "env" | "printenv" => {
            if program == "env" && args.first().is_some_and(|a| a.contains('=')) {
                // `env KEY=VAL cmd...` runs a program; not a dump.
                return Ok(());
            }
            Err(format!("{program} 会打印注入的环境变量（含密钥）"))
        }
        // `echo` / `printf` are only a leak when they mention an injected name.
        "echo" | "printf" => {
            if references_var(args) {
                Err(format!("{program} 会回显注入的密钥"))
            } else {
                Ok(())
            }
        }
        // Shell one-liners that echo an injected variable.
        "sh" | "bash" | "dash" | "zsh" | "ksh" => {
            if let Some(idx) = args.iter().position(|a| a == "-c") {
                if let Some(script) = args.get(idx + 1) {
                    if shell_script_dumps_secret(script, envs) {
                        return Err("shell 脚本会回显注入的密钥".to_string());
                    }
                }
            }
            Ok(())
        }
        _ => Ok(()),
    }
}

/// Detects a shell one-liner that prints an injected environment variable
/// (e.g. `sh -c 'echo "$PASS"'` or `printenv PW`). Splitting on statement
/// separators keeps unrelated `echo` calls in the same script (e.g. a grep
/// test that echoes OK/FAIL) from being flagged.
fn shell_script_dumps_secret(script: &str, envs: &[(String, String)]) -> bool {
    let builtins = ["echo", "printf", "printenv"];
    script.split([';', '\n', '&']).any(|stmt| {
        if !builtins.iter().any(|b| stmt.contains(b)) {
            return false;
        }
        envs.iter().any(|(key, _)| {
            stmt.contains(&format!("${key}"))
                || stmt.contains(&format!("${{{key}}}"))
                || (stmt.contains("printenv") && stmt.split_whitespace().any(|t| t == key))
        })
    })
}

fn print_socket_response(method: &str, field: Option<&str>, query: &str, data: Option<Value>) {
    let data = data.unwrap_or(Value::Null);
    match method {
        "list" => {
            let filter = query.to_lowercase();
            if let Some(entries) = data.get("entries").and_then(Value::as_array) {
                for entry in entries {
                    let label = entry.get("label").and_then(Value::as_str).unwrap_or("");
                    let username = entry.get("username").and_then(Value::as_str).unwrap_or("");
                    if !filter.is_empty()
                        && !label.to_lowercase().contains(&filter)
                        && !username.to_lowercase().contains(&filter)
                    {
                        continue;
                    }
                    let group = entry.get("group").and_then(Value::as_str).unwrap_or("");
                    let file = entry.get("file").and_then(Value::as_str).unwrap_or("");
                    println!("{label}\t{username}\t{group}\t{file}");
                }
            }
        }
        "get" => {
            if field == Some("json") {
                println!(
                    "{}",
                    serde_json::to_string(&data).unwrap_or_else(|_| "null".into())
                );
            } else if let Some(text) = data.as_str() {
                println!("{text}");
            }
        }
        "pamSetup" => {
            if field == Some("json") {
                println!(
                    "{}",
                    serde_json::to_string(&data).unwrap_or_else(|_| "null".into())
                );
            } else {
                let value = data.get("path").unwrap_or(&Value::Null);
                println!("{}", plain(value));
            }
        }
        _ => unreachable!(),
    }
}

/// Renders a JSON value the same way Dart's `writeln` would for scalars.
fn plain(value: &Value) -> String {
    match value {
        Value::String(text) => text.clone(),
        Value::Null => "null".to_string(),
        Value::Bool(b) => b.to_string(),
        Value::Number(n) => n.to_string(),
        other => serde_json::to_string(other).unwrap_or_else(|_| "null".into()),
    }
}

/// CLI-local default vault memory: the path (and optional keyfile) of the
/// last local KDBX opened successfully with `--db`, so plain `list` /
/// `pam-setup` can run standalone when the desktop app is not running.
const CLI_DEFAULT_FILE: &str = "cli-default.json";

fn load_default_vault(home: &Path) -> Option<(PathBuf, Option<PathBuf>)> {
    let path = app_data_dir(home).join(CLI_DEFAULT_FILE);
    let text = fs::read_to_string(path).ok()?;
    let root: Value = serde_json::from_str(&text).ok()?;
    let db = root.get("db")?.as_str()?;
    let key_file = root
        .get("key_file")
        .and_then(Value::as_str)
        .map(PathBuf::from);
    Some((PathBuf::from(db), key_file))
}

fn save_default_vault(home: &Path, db: &Path, key_file: Option<&Path>) {
    let payload = json!({
        "db": db.display().to_string(),
        "key_file": key_file.map(|p| p.display().to_string()),
    });
    if let Ok(text) = serde_json::to_string_pretty(&payload) {
        let _ = fs::write(app_data_dir(home).join(CLI_DEFAULT_FILE), text);
    }
}

fn remember_default_vault(opts: &Options) {
    if opts.cloud {
        return;
    }
    if let Some(db) = opts.db.as_ref() {
        if let Some(home) = home_dir() {
            save_default_vault(&home, db, opts.key_file.as_deref());
        }
    }
}

/// Mirrors the app's data-directory resolution: data lives under the XDG
/// config dir (default `~/.config/openvalut/data`). If the legacy
/// `~/.openvalut/data` directory still exists and the new XDG directory does
/// not, the contents are copied over once so existing users keep their
/// token/port files and other data.
fn app_data_dir(home: &Path) -> PathBuf {
    let legacy = home.join(".openvalut").join("data");
    let xdg = env::var_os("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| home.join(".config"));
    let target = xdg.join("openvalut").join("data");
    if !target.exists() && legacy.exists() {
        if let Err(e) = copy_dir_all(&legacy, &target) {
            eprintln!(
                "warning: failed to migrate data directory from {} to {}: {e}",
                legacy.display(),
                target.display()
            );
            return legacy;
        }
    }
    if !target.exists() {
        let _ = fs::create_dir_all(&target);
    }
    target
}

fn credential_server_data_dir(home: &Path) -> PathBuf {
    if cfg!(target_os = "macos") {
        let sandboxed = home.join(
            "Library/Containers/app.openvalut/Data/Library/Application Support/app.openvalut",
        );
        if sandboxed.join("openvalut.token").is_file() {
            return sandboxed;
        }
    }
    app_data_dir(home)
}

fn copy_dir_all(src: impl AsRef<Path>, dst: impl AsRef<Path>) -> io::Result<()> {
    fs::create_dir_all(&dst)?;
    for entry in fs::read_dir(src)? {
        let entry = entry?;
        let ty = entry.file_type()?;
        if ty.is_dir() {
            copy_dir_all(entry.path(), dst.as_ref().join(entry.file_name()))?;
        } else {
            fs::copy(entry.path(), dst.as_ref().join(entry.file_name()))?;
        }
    }
    Ok(())
}

fn home_dir() -> Option<PathBuf> {
    env::var_os("HOME")
        .map(PathBuf::from)
        .or_else(|| env::var_os("USERPROFILE").map(PathBuf::from))
}

/// Sends one newline-delimited JSON request and returns the parsed response.
fn request(
    port: u16,
    token: &str,
    method: &str,
    params: &Map<String, Value>,
) -> Result<Response, String> {
    let mut stream = TcpStream::connect(("127.0.0.1", port)).map_err(|e| {
        if e.kind() == std::io::ErrorKind::ConnectionRefused {
            "OpenValut credential server is not reachable. \
             Open the app with an unlocked vault."
                .to_string()
        } else {
            e.to_string()
        }
    })?;
    let body = json!({
        "id": 1,
        "token": token,
        "method": method,
        "params": Value::Object(params.clone()),
    });
    let mut line = serde_json::to_string(&body).map_err(|e| e.to_string())?;
    line.push('\n');
    stream
        .write_all(line.as_bytes())
        .map_err(|e| e.to_string())?;

    let mut reader = BufReader::new(stream);
    let mut buffer = Vec::new();
    reader
        .read_until(b'\n', &mut buffer)
        .map_err(|e| e.to_string())?;
    let text = String::from_utf8_lossy(&buffer);
    serde_json::from_str(text.trim()).map_err(|e| e.to_string())
}

#[derive(serde::Deserialize)]
struct Response {
    ok: bool,
    data: Option<Value>,
    error: Option<String>,
}

// ---------------------------------------------------------------------------
// standalone mode (local KDBX or OpenValut Cloud)
// ---------------------------------------------------------------------------

fn run_standalone(opts: Options) -> i32 {
    // `--scan` only makes sense for the two QR-code flows.
    if opts.scan
        && !matches!(
            (opts.command.as_deref(), opts.query.as_str()),
            (Some("auth"), "login") | (Some("unlock"), _)
        )
    {
        eprintln!("error: --scan 只能用于 `auth login --scan` 或 `unlock --scan`");
        return 2;
    }
    if opts.command.as_deref() == Some("agent") {
        return run_agent(opts);
    }
    if opts.command.as_deref() == Some("rows") {
        return run_rows(&opts);
    }
    if opts.command.as_deref() == Some("auth") {
        return run_auth(opts, keychain::default_key_store());
    }
    if opts.command.as_deref() == Some("exec") {
        return standalone_exec(&opts);
    }
    if opts.command.as_deref() == Some("unlock") {
        return unlock_command(&opts, keychain::default_key_store());
    }
    if opts.command.as_deref() == Some("lock") {
        return lock_command(keychain::default_key_store());
    }
    if opts.command.as_deref() == Some("serve") {
        return serve_command(&opts);
    }
    // Validate the subcommand before prompting for the master password, so a
    // missing/subcommand-only invocation (e.g. bare `--cloud`) reports the
    // error immediately instead of asking for the password and then printing
    // usage without ever reaching the cloud login.
    let command = match opts.command.as_deref() {
        Some(c) => c,
        None => {
            eprintln!(
                "error: 未指定命令。请提供 list / get / item / pam-setup / exec 等命令，例如：openvalut-cli --cloud list"
            );
            return 2;
        }
    };
    if command == "get" {
        eprintln!("error: get 已移除：该命令会在终端输出密码（socket 元数据 get 仍可用）");
        return 2;
    }
    let password = match resolve_password(&opts) {
        Ok(p) => p,
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };

    if command == "vaults" {
        return run_cloud_vaults(&opts, &password);
    }

    // `vault create` starts from an empty database instead of opening one.
    if command == "vault" && opts.query == "create" {
        return vault_create(&opts, &password);
    }

    // Load the KDBX bytes: local file or decrypted cloud blob.
    let (mut db, save_back, persist): (kdbx::Database, bool, Box<Persist>) = if opts.cloud {
        match open_cloud(&opts, &password) {
            Ok(v) => v,
            Err(e) => {
                eprintln!("error: {e}");
                return 1;
            }
        }
    } else {
        match open_local(&opts, &password) {
            Ok(v) => v,
            Err(e) => {
                eprintln!("error: {e}");
                return 1;
            }
        }
    };

    // Unlocking a vault also loads its SSH server profiles into the agent.
    ssh_agent::add_server_keys(&db);

    let code = match command {
        "list" => standalone_list(&opts, &db),
        "pam-setup" => standalone_pam_setup(&db),
        "item" => {
            let sub = opts.query.as_str();
            match sub {
                "add" => item_add(&mut db, &opts),
                "edit" => item_edit(&mut db, &opts, opts.item_target.as_deref().unwrap_or("")),
                "delete" => {
                    if opts.item_empty_title_delete {
                        item_delete_empty_titles(&mut db)
                    } else {
                        item_delete(&mut db, opts.item_target.as_deref().unwrap_or(""))
                    }
                }
                "allow" => {
                    item_set_read_allowed(&mut db, opts.item_target.as_deref().unwrap_or(""), true)
                }
                "deny" => {
                    item_set_read_allowed(&mut db, opts.item_target.as_deref().unwrap_or(""), false)
                }
                "import-env" => item_import_env(&mut db, &opts),
                _ => {
                    usage();
                    2
                }
            }
        }
        _ => {
            usage();
            2
        }
    };
    if code != 0 {
        return code;
    }
    if save_back {
        match persist(&db, &password) {
            Ok(()) => {}
            Err(e) => {
                eprintln!("error: {e}");
                return 1;
            }
        }
    }
    remember_default_vault(&opts);
    0
}

type Persist = dyn Fn(&kdbx::Database, &str) -> Result<(), String>;

/// `agent` subcommands manage the system ssh-agent from vault keys.
/// `list`/`remove-all` only need SSH_AUTH_SOCK; `add`/`remove` need a vault.
fn run_agent(opts: Options) -> i32 {
    let sub = opts.query.as_str();
    match sub {
        "list" => return ssh_agent::list(),
        "remove-all" => return ssh_agent::remove_all(),
        "add" | "remove" => {}
        _ => {
            usage();
            return 2;
        }
    }
    let target = opts.item_target.as_deref().unwrap_or("");
    if target.is_empty() {
        eprintln!("error: agent {sub} 需要条目（agent {sub} <query>）");
        return 2;
    }
    if !opts.db.is_some() && !opts.cloud {
        eprintln!("error: agent {sub} 需要 --db <file> 或 --cloud");
        return 2;
    }
    let password = match resolve_password(&opts) {
        Ok(p) => p,
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };
    let db = if opts.cloud {
        match open_cloud(&opts, &password) {
            Ok((db, _, _)) => db,
            Err(e) => {
                eprintln!("error: {e}");
                return 1;
            }
        }
    } else {
        match open_local(&opts, &password) {
            Ok((db, _, _)) => db,
            Err(e) => {
                eprintln!("error: {e}");
                return 1;
            }
        }
    };
    match sub {
        "add" => ssh_agent::add(&db, target),
        "remove" => ssh_agent::remove(&db, target),
        _ => unreachable!(),
    }
}

/// `auth` subcommands persist the cloud account so later `--cloud` commands
/// don't need to repeat `--email`/`--secret-key`.
fn run_auth(opts: Options, store: &dyn keychain::KeyStore) -> i32 {
    let home = match home_dir() {
        Some(home) => home,
        None => {
            eprintln!("error: 无法确定 home 目录");
            return 1;
        }
    };
    let path = app_data_dir(&home).join(auth::ACCOUNT_FILE);
    let sub = opts.query.as_str();
    match sub {
        "login" => {
            let server = opts
                .server
                .clone()
                .unwrap_or_else(|| "https://openvalut.example.com/".to_string());
            if opts.scan {
                return auth_login_scan(&server, &path, store);
            }
            let email = match opts.email.clone() {
                Some(e) => e,
                None => match prompt_line("邮箱 (email): ") {
                    Some(v) if !v.is_empty() => v,
                    _ => {
                        eprintln!("error: auth login 需要 --email 或在提示中输入邮箱");
                        return 2;
                    }
                },
            };
            let secret_key = match opts.secret_key.clone() {
                Some(k) => k,
                None => match rpassword::prompt_password("Secret Key（输入时不可见）: ") {
                    Ok(k) if !k.trim().is_empty() => k,
                    _ => {
                        eprintln!("error: auth login 需要 --secret-key 或在提示中输入 Secret Key");
                        return 2;
                    }
                },
            };
            // Validate credentials first; only persist on a successful login.
            match cloud::CloudClient::login(&server, &email, &secret_key) {
                Ok(_) => {}
                Err(e) => {
                    eprintln!("error: {e}");
                    return 1;
                }
            }
            // Store the secret key in the keychain first; only write the
            // non-sensitive server + email to the config once that succeeded.
            // Normalize to the canonical 32-hex form so later `--cloud`
            // commands compare consistently regardless of the input format.
            let normalized_key = secret_key.trim().to_lowercase().replace('-', "");
            if let Err(e) = store.set(keychain::CLOUD_SECRET_KEY, &normalized_key) {
                eprintln!("error: {e}");
                return 1;
            }
            let account = auth::CloudAccount {
                server: server.trim_end_matches('/').to_string(),
                email: email.trim().to_lowercase(),
            };
            if let Err(e) = auth::save_account(&path, &account) {
                let _ = store.delete(keychain::CLOUD_SECRET_KEY);
                eprintln!("error: {e}");
                return 1;
            }
            println!("已登录 {}（{}）", account.email, account.server);
            0
        }
        "status" => match auth::load_account(&path) {
            Ok(Some(account)) => match store.get(keychain::CLOUD_SECRET_KEY) {
                Ok(Some(key)) if !key.is_empty() => {
                    println!("已登录：{}（{}）", account.email, account.server);
                    0
                }
                _ => {
                    eprintln!(
                            "已保存连接配置：{}（{}），但缺少 Secret Key，请重新运行 openvalut-cli auth login",
                            account.email, account.server
                        );
                    1
                }
            },
            Ok(None) => {
                eprintln!("未保存云账号，请先运行 openvalut-cli auth login");
                1
            }
            Err(e) => {
                eprintln!("error: {e}");
                1
            }
        },
        "logout" => {
            let deleted_config = match auth::delete_account(&path) {
                Ok(v) => v,
                Err(e) => {
                    eprintln!("error: {e}");
                    return 1;
                }
            };
            let has_key = match store.get(keychain::CLOUD_SECRET_KEY) {
                Ok(v) => v.is_some(),
                Err(e) => {
                    eprintln!("error: {e}");
                    return 1;
                }
            };
            if let Err(e) = store.delete(keychain::CLOUD_SECRET_KEY) {
                eprintln!("error: {e}");
                return 1;
            }
            if deleted_config || has_key {
                println!("已退出登录");
                0
            } else {
                eprintln!("没有已保存的云账号");
                1
            }
        }
        _ => {
            eprintln!("error: auth 子命令需为 login / status / logout");
            2
        }
    }
}

/// `auth login --scan`: log in by scanning a terminal QR code with the phone,
/// so the account Secret Key is never typed (or stored) on the PC.
fn auth_login_scan(server: &str, account_path: &Path, store: &dyn keychain::KeyStore) -> i32 {
    let result = match run_scan_session(server, "登录本机") {
        Ok(result) => result,
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };
    let email = result.username.trim().to_lowercase();
    if email.is_empty() {
        eprintln!("error: 服务器未返回账号邮箱，无法完成扫码登录");
        return 1;
    }
    // The account id (the 32-char UUID) doubles as the Secret Key used to sign
    // every authenticated request, so it is what we persist in the keychain.
    let user_id = match result.user_id {
        Some(id) if !id.is_empty() => id,
        _ => {
            eprintln!("error: 服务器未返回账号 ID，无法完成扫码登录（请升级服务端后重试）");
            return 1;
        }
    };
    if let Err(e) = store.set(keychain::CLOUD_SECRET_KEY, &user_id) {
        eprintln!("error: {e}");
        return 1;
    }
    let account = auth::CloudAccount {
        server: server.trim_end_matches('/').to_string(),
        email: email.clone(),
    };
    if let Err(e) = auth::save_account(account_path, &account) {
        let _ = store.delete(keychain::CLOUD_SECRET_KEY);
        eprintln!("error: {e}");
        return 1;
    }
    // If the phone had the vault unlocked it also relayed the master password;
    // cache it so later commands run without prompting (same as `unlock`).
    if let Some(password) = result.master_password.filter(|p| !p.is_empty()) {
        match store.set(keychain::MASTER_PASSWORD, &password) {
            Ok(()) => {
                println!("已登录 {}（{}），并已同步解锁", email, account.server);
                return 0;
            }
            Err(e) => eprintln!("warning: 已登录，但保存主密码失败：{e}"),
        }
    }
    println!("已登录 {}（{}）", email, account.server);
    0
}

/// Creates a scan-login session, prints the QR code, and blocks until the phone
/// confirms (or the session expires). `action` is woven into the prompt text,
/// e.g. "登录本机".
fn run_scan_session(server: &str, action: &str) -> Result<scan_login::ScanResult, String> {
    let session = scan_login::ScanLogin::start(server)?;
    let qr = session.qr_terminal()?;
    println!("请用手机 OpenValut App 的「扫码授权登录」扫描下面的二维码以{action}：");
    println!();
    println!("{qr}");
    println!();
    println!("二维码内容：{}", session.qr_content());
    println!("等待手机确认…（二维码 2 分钟内有效，Ctrl-C 取消）");
    io::stdout().flush().ok();
    session.wait()
}

/// Reads one line of visible input from the terminal with a prompt.
fn prompt_line(prompt: &str) -> Option<String> {
    print!("{prompt}");
    io::stdout().flush().ok()?;
    let mut line = String::new();
    match io::stdin().read_line(&mut line) {
        Ok(_) => Some(line.trim().to_string()),
        Err(_) => None,
    }
}

/// Stores the vault master password (default) or the system sudo password
/// (`--sudo`) in the OS keychain so later commands don't re-prompt.
fn unlock_command(opts: &Options, store: &dyn keychain::KeyStore) -> i32 {
    if opts.scan {
        if opts.sudo_mode {
            eprintln!("error: unlock --scan 不能与 --sudo 一起使用");
            return 2;
        }
        return unlock_scan(opts, store);
    }
    if opts.sudo_mode {
        let value = match opts.password.clone() {
            Some(v) => v,
            None if opts.password_stdin => {
                let mut line = String::new();
                match io::stdin().read_line(&mut line) {
                    Ok(_) => line.trim().to_string(),
                    Err(e) => {
                        eprintln!("error: {e}");
                        return 1;
                    }
                }
            }
            None => match rpassword::prompt_password("系统 sudo 密码：") {
                Ok(v) => v,
                Err(e) => {
                    eprintln!("error: {e}");
                    return 1;
                }
            },
        };
        return match store.set(keychain::SUDO_PASSWORD, &value) {
            Ok(()) => {
                println!("已保存 sudo 密码");
                0
            }
            Err(e) => {
                eprintln!("error: {e}");
                1
            }
        };
    }

    let value = match opts.password.clone() {
        Some(v) => v,
        None => match rpassword::prompt_password("Master password: ") {
            Ok(v) => v,
            Err(e) => {
                eprintln!("error: {e}");
                return 1;
            }
        },
    };
    // Validate the password against the configured vault before storing, so a
    // mistyped master password is rejected here instead of failing (confusingly)
    // on the first --cloud/--db command that uses it.
    store_master_password(opts, store, &value)
}

/// `unlock --scan`: have the phone push the vault master password over the QR
/// relay channel, then store it exactly like a typed `unlock`.
fn unlock_scan(opts: &Options, store: &dyn keychain::KeyStore) -> i32 {
    let server = opts
        .server
        .clone()
        .unwrap_or_else(|| scan_login::DEFAULT_SERVER.to_string());
    let result = match run_scan_session(&server, "解锁本机") {
        Ok(result) => result,
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };
    let password = match result.master_password.filter(|p| !p.is_empty()) {
        Some(password) => password,
        None => {
            eprintln!("error: 手机未回传主密码：请先在手机上打开该密码库并解锁，再重新扫码");
            return 1;
        }
    };
    store_master_password(opts, store, &password)
}

/// Validates and stores a master password, sharing the outcome messages between
/// the interactive prompt and `unlock --scan`.
fn store_master_password(opts: &Options, store: &dyn keychain::KeyStore, value: &str) -> i32 {
    match validate_master_password(opts, store, value) {
        Ok(MasterPasswordValidation::NoContext) => {
            // No vault context to validate against; store but say so.
            if let Err(e) = store.set(keychain::MASTER_PASSWORD, value) {
                eprintln!("error: {e}");
                return 1;
            }
            println!("已解锁（未校验：未指定 --cloud/--db，也未保存云账号）");
            0
        }
        Ok(MasterPasswordValidation::CloudCredentialsUnavailable) => {
            // A saved account exists but its Secret Key can't be read, so there
            // is no vault to validate against. `unlock` only caches the master
            // password — the missing Secret Key is surfaced clearly by the real
            // --cloud command, so don't fail here after the user typed it.
            if let Err(e) = store.set(keychain::MASTER_PASSWORD, value) {
                eprintln!("error: {e}");
                return 1;
            }
            println!("已解锁（未校验：缺少云 Secret Key，可用 openvalut-cli auth login 补齐）");
            0
        }
        Ok(MasterPasswordValidation::Verified) => {
            if let Err(e) = store.set(keychain::MASTER_PASSWORD, value) {
                eprintln!("error: {e}");
                return 1;
            }
            auto_load_server_keys_after_unlock(opts, value);
            println!("已解锁（本机终端 / SSH 均可用，重启后失效；App 打开时会自动带入）");
            0
        }
        Err(e) => {
            eprintln!("error: 主密码验证失败：{e}");
            1
        }
    }
}

/// After `unlock` verified the master password, best-effort loads SSH server
/// profiles (entries carrying ssh-host/ssh-port + a private key) into the
/// agent. Silently skips when no vault context is configured.
fn auto_load_server_keys_after_unlock(opts: &Options, password: &str) {
    if !opts.cloud && opts.db.is_none() {
        return;
    }
    let result = if opts.cloud {
        open_cloud(opts, password).map(|(db, _, _)| db)
    } else {
        open_local(opts, password).map(|(db, _, _)| db)
    };
    match result {
        Ok(db) => {
            ssh_agent::add_server_keys(&db);
        }
        Err(e) => {
            eprintln!("warning: 无法在解锁后加载 SSH 服务器密钥：{e}");
        }
    }
}

/// Outcome of trying to verify a master password against the configured vault.
enum MasterPasswordValidation {
    /// The password opened the configured vault.
    Verified,
    /// No vault context at all (bare unlock, no saved account, no --cloud/--db).
    NoContext,
    /// A cloud account is saved but its Secret Key isn't available, so the
    /// password can't be verified here; the real --cloud command will surface
    /// the missing key.
    CloudCredentialsUnavailable,
}

/// Verifies that `password` can actually open the configured vault before
/// `unlock` stores it. Returns [MasterPasswordValidation::Verified] when the
/// password opens the vault, [MasterPasswordValidation::NoContext] when there
/// is no vault context (bare `unlock` with no saved cloud account and no
/// `--db`), and `Err` when the password fails to decrypt the vault.
fn validate_master_password(
    opts: &Options,
    store: &dyn keychain::KeyStore,
    password: &str,
) -> Result<MasterPasswordValidation, String> {
    let home = home_dir().ok_or_else(|| "无法确定 home 目录".to_string())?;
    let account_path = app_data_dir(&home).join(auth::ACCOUNT_FILE);
    let has_saved_account = auth::load_account(&account_path)
        .map(|a| a.is_some())
        .unwrap_or(false);

    let cloud_context = opts.cloud
        || opts.server.is_some()
        || opts.email.is_some()
        || opts.secret_key.is_some()
        || has_saved_account;

    // An explicit --db wins: validate against the local file even when a cloud
    // account happens to be saved.
    if let Some(path) = &opts.db {
        let bytes = fs::read(path).map_err(|e| format!("无法读取 {}: {e}", path.display()))?;
        let keyfile = match &opts.key_file {
            Some(kf) => {
                Some(fs::read(kf).map_err(|e| format!("无法读取 keyfile {}: {e}", kf.display()))?)
            }
            None => None,
        };
        kdbx::load(&bytes, password, keyfile.as_deref())
            .map_err(|e| format!("无法打开 {}: {e}", path.display()))?;
        return Ok(MasterPasswordValidation::Verified);
    }

    if cloud_context {
        let (server, email, secret_key) = match resolve_cloud_credentials(opts, store) {
            Ok(creds) => creds,
            // A saved account whose Secret Key (or email) can't be resolved
            // means there is no vault to validate against. Store the password
            // unverified instead of failing after the user already typed it —
            // the missing Secret Key is surfaced clearly by the real --cloud
            // command.
            Err(_) => return Ok(MasterPasswordValidation::CloudCredentialsUnavailable),
        };
        let client = cloud::CloudClient::login(&server, &email, &secret_key)?;
        let vaults = client.list_vaults()?;
        let vault = match &opts.vault {
            Some(selector) => vaults
                .into_iter()
                .find(|v| v.id == *selector || v.name == *selector)
                .ok_or_else(|| format!("未找到密码库：{selector}"))?,
            None => vaults
                .into_iter()
                .next()
                .ok_or_else(|| "账号下还没有云密码库".to_string())?,
        };
        let full = client.get_vault(&vault.id)?;
        let key = cloud::derive_key(password, &full.id)?;
        // AES-GCM authentication fails when the password is wrong.
        cloud::decrypt_blob(&key, &full.nonce, &full.ciphertext)?;
        return Ok(MasterPasswordValidation::Verified);
    }

    Ok(MasterPasswordValidation::NoContext)
}

/// `openvalut-cli serve`：用 CLI 自己解锁保险库并起本地凭据服务。
///
/// 等价于 App 里的那个 credential server（127.0.0.1 + token/port 文件），
/// 所以 `openvalut-cli run`、`ov-ssh` 这类只认凭据服务的脚本不用打开 App 也能用。
fn serve_command(opts: &Options) -> i32 {
    if !opts.cloud && opts.db.is_none() {
        eprintln!(
            "error: serve 需要指定保险库：--db <vault.kdbx> [--key-file <f>]，\
             或先跑一次 `openvalut-cli --db <vault.kdbx> list` 记住默认库。"
        );
        return 2;
    }
    let port = match opts.port.as_deref() {
        Some(text) => match text.parse::<u16>() {
            Ok(port) => Some(port),
            Err(_) => {
                eprintln!("error: 无效端口 {text}");
                return 2;
            }
        },
        None => None,
    };
    let password = match resolve_password(opts) {
        Ok(password) => password,
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };
    let (db, _save_back, _persist) = if opts.cloud {
        match open_cloud(opts, &password) {
            Ok(db) => db,
            Err(e) => {
                eprintln!("error: {e}");
                return 1;
            }
        }
    } else {
        match open_local(opts, &password) {
            Ok(db) => db,
            Err(e) => {
                eprintln!("error: {e}");
                return 1;
            }
        }
    };
    let home = match home_dir() {
        Some(home) => home,
        None => {
            eprintln!("error: 无法确定家目录");
            return 1;
        }
    };
    let data_dir = credential_server_data_dir(&home);
    credential_server::serve(db, &credential_server::ServeOptions { port, data_dir })
}

/// Clears the stored master and sudo passwords from the keychain.
fn lock_command(store: &dyn keychain::KeyStore) -> i32 {
    // Clear both *reports* whether something was actually removed, so a
    // locked/unavailable OS keychain (a bare SSH login) can't block clearing
    // the in-memory session keyring.
    let mut removed = false;
    let mut failed = false;
    for id in [keychain::MASTER_PASSWORD, keychain::SUDO_PASSWORD] {
        match store.delete(id) {
            Ok(did_remove) => removed |= did_remove,
            Err(e) => {
                eprintln!("warn: 无法清除 {id}：{e}");
                failed = true;
            }
        }
    }
    if !removed {
        eprintln!("没有已保存的主密码/sudo 密码");
        return 1;
    }
    if failed {
        eprintln!("已部分锁定（部分钥匙串条目无法清除）");
        return 1;
    }
    println!("已锁定");
    0
}

/// `exec` runs a command, optionally through `sudo` with the sudo password
/// (and, if configured, the current machine's TOTP) fed automatically over a
/// PTY. The vault master password is only read when a vault is provided and a
/// machine TOTP is needed.
fn standalone_exec(opts: &Options) -> i32 {
    let argv = &opts.run_command;
    if argv.is_empty() {
        eprintln!("error: exec 需要指定命令，例如 openvalut-cli exec --sudo -- apt update");
        return 2;
    }
    let wants_sudo = opts.sudo_mode || argv[0] == "sudo";
    if !wants_sudo {
        return spawn_plain(argv, &opts.run_envs);
    }

    let sudo_password = match keychain::default_key_store().get(keychain::SUDO_PASSWORD) {
        Ok(Some(p)) if !p.is_empty() => p,
        Ok(_) => {
            eprintln!("error: 未找到 sudo 密码，请先运行 openvalut-cli unlock --sudo");
            return 1;
        }
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };

    // Optional: feed the current machine's TOTP if a vault was provided and a
    // computer entry with an OTP exists. This only runs when --db/--cloud was
    // given, so a plain password-only sudo needs no vault at all.
    let mut totp = None;
    if opts.db.is_some() || opts.cloud {
        match load_totp_for_current_machine(opts) {
            Ok(Some(code)) => totp = Some(code),
            Ok(None) => {}
            Err(e) => {
                eprintln!("error: {e}");
                return 1;
            }
        }
    }
    spawn_sudo(argv, &sudo_password, totp.as_deref(), &opts.run_envs)
}

fn spawn_plain(argv: &[String], envs: &[(String, String)]) -> i32 {
    let mut cmd = Command::new(&argv[0]);
    cmd.args(&argv[1..]);
    for (key, value) in envs {
        cmd.env(key, value);
    }
    match cmd.status() {
        Ok(status) => status.code().unwrap_or(1),
        Err(e) => {
            eprintln!("error: 无法执行 {}: {e}", argv[0]);
            1
        }
    }
}

/// Runs `sudo <argv[1..]>` under a PTY, echoing the sudo password and the (optional)
/// machine TOTP in response to the corresponding prompts.
fn spawn_sudo(
    argv: &[String],
    sudo_password: &str,
    totp: Option<&str>,
    envs: &[(String, String)],
) -> i32 {
    use portable_pty::{native_pty_system, CommandBuilder, PtySize};
    use std::io::Read;

    let pty = native_pty_system();
    let pair = match pty.openpty(PtySize {
        rows: 24,
        cols: 80,
        pixel_width: 0,
        pixel_height: 0,
    }) {
        Ok(pair) => pair,
        Err(e) => {
            eprintln!("error: 无法打开 PTY: {e}");
            return 1;
        }
    };

    let mut cmd = CommandBuilder::new("sudo");
    // argv[0] is the command to run under sudo. Accept both `exec --sudo --
    // dpkg -i f` (whole argv is the command) and `exec -- sudo dpkg -i f`
    // (argv[0] is literally `sudo`).
    let command_args: &[String] = if argv[0] == "sudo" { &argv[1..] } else { argv };
    cmd.args(command_args);
    for (key, value) in envs {
        cmd.env(key, value);
    }
    let mut child = match pair.slave.spawn_command(cmd) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("error: 无法启动 sudo: {e}");
            return 1;
        }
    };
    // Keep the slave from keeping the PTY open in the parent, so reads see EOF
    // when the child exits.
    drop(pair.slave);
    let mut reader = match pair.master.try_clone_reader() {
        Ok(r) => r,
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };
    let mut writer = match pair.master.take_writer() {
        Ok(w) => w,
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };

    let mut buffer = Vec::new();
    let mut totp_done = false;
    let mut stdout = io::stdout();
    loop {
        let mut chunk = [0u8; 4096];
        let n = match reader.read(&mut chunk) {
            Ok(0) => break,
            Ok(n) => n,
            Err(e) => {
                eprintln!("error: 读取 sudo 输出失败: {e}");
                break;
            }
        };
        let _ = stdout.write_all(&chunk[..n]);
        let _ = stdout.flush();
        buffer.extend_from_slice(&chunk[..n]);
        let text = String::from_utf8_lossy(&buffer);

        // Feed the sudo password each time a password prompt appears (English
        // `password for` / `Password:` and the Chinese Deepin PAM prompt
        // `请输入密码`), so a typo (sudo retries up to 3 times) is answered
        // instead of hanging.
        if text.contains("assword") || text.contains("请输入密码") {
            let _ = writer.write_all(sudo_password.as_bytes());
            let _ = writer.write_all(b"\n");
            let _ = writer.flush();
            buffer.clear();
            continue;
        }
        // Feed the current machine's TOTP once, when pam_openvalut asks.
        if !totp_done && (text.contains("验证码") || text.contains("OTP")) {
            if let Some(code) = totp {
                let _ = writer.write_all(code.as_bytes());
                let _ = writer.write_all(b"\n");
                let _ = writer.flush();
                totp_done = true;
                buffer.clear();
            } else {
                // pam_openvalut is asking for a TOTP but we have no code for
                // this machine; bail out instead of letting sudo hang.
                eprintln!(
                    "error: sudo 需要两步验证码，但未配置当前机器的 TOTP（请用 --db/--cloud 打开密码库）"
                );
                let _ = child.clone_killer().kill();
                return 2;
            }
        }
    }
    child
        .wait()
        .map(|st| {
            if st.success() {
                0
            } else {
                st.exit_code() as i32
            }
        })
        .unwrap_or(1)
}

/// Opens the provided vault and computes the current machine's TOTP code. Used
/// by `exec --sudo` so a `pam_openvalut`-guarded sudo can be answered too.
fn load_totp_for_current_machine(opts: &Options) -> Result<Option<String>, String> {
    // Prefer the local PAM TOTP file: no vault unlock / master password needed
    // for the current machine's two-step sudo (matches pam_openvalut).
    if let Some(secret) = pam_setup::read_encrypted_totp() {
        if let Some(config) = totp::parse_otp_auth(&secret) {
            let now = std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .map(|d| d.as_secs())
                .unwrap_or(0);
            let (code, _) = totp::generate(&config, now);
            return Ok(Some(code));
        }
    }
    let password = resolve_password(opts)?;
    let db = if opts.cloud {
        open_cloud(opts, &password).map(|(db, _, _)| db)?
    } else {
        open_local(opts, &password).map(|(db, _, _)| db)?
    };
    let mid = pam_setup::machine_id().ok_or_else(|| "无法读取 /etc/machine-id".to_string())?;
    let entry = match kdbx::find_computer_entry(&db, &mid) {
        Some(e) => e,
        None => return Ok(None),
    };
    let entry_ref = db.entry(entry.id).ok_or("无法读取计算机条目")?;
    let secret = match kdbx::entry_value(&entry_ref, kdbx::OTP_FIELD) {
        Some(v) if !v.is_empty() => v,
        _ => return Ok(None),
    };
    let config = totp::parse_otp_auth(&secret).ok_or("当前计算机条目的两步验证码配置无效")?;
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);
    let (code, _) = totp::generate(&config, now);
    Ok(Some(code))
}

fn open_local(
    opts: &Options,
    password: &str,
) -> Result<(kdbx::Database, bool, Box<Persist>), String> {
    let path = opts.db.as_ref().expect("--db");
    let bytes = fs::read(path).map_err(|e| format!("unable to read {}: {e}", path.display()))?;
    let keyfile = match &opts.key_file {
        Some(kf) => Some(
            fs::read(kf).map_err(|e| format!("unable to read keyfile {}: {e}", kf.display()))?,
        ),
        None => None,
    };
    let db = kdbx::load(&bytes, password, keyfile.as_deref())?;
    let path = path.clone();
    let keyfile = keyfile.clone();
    let persist: Box<Persist> = Box::new(move |db, password| {
        let bytes = kdbx::save(db, password, keyfile.as_deref())?;
        // Write atomically: temp file + rename.
        let tmp = path.with_extension("kdbx.tmp");
        fs::write(&tmp, bytes).map_err(|e| format!("unable to write {}: {e}", tmp.display()))?;
        fs::rename(&tmp, &path)
            .map_err(|e| format!("unable to replace {}: {e}", path.display()))?;
        Ok(())
    });
    Ok((db, true, persist))
}

fn vault_create(opts: &Options, password: &str) -> i32 {
    let name = match &opts.vault_name {
        Some(n) => n.clone(),
        None => {
            eprintln!("error: vault create 需要名称（vault create <name>）");
            return 2;
        }
    };
    let bytes = match kdbx::create_empty(&name, password) {
        Ok(b) => b,
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };
    if opts.cloud {
        let (server, email, secret_key) =
            match resolve_cloud_credentials(opts, keychain::default_key_store()) {
                Ok(c) => c,
                Err(e) => {
                    eprintln!("error: {e}");
                    return 2;
                }
            };
        let client = match cloud::CloudClient::login(&server, &email, &secret_key) {
            Ok(c) => c,
            Err(e) => {
                eprintln!("error: {e}");
                return 1;
            }
        };
        let vault_id = cloud::new_vault_id();
        let key = match cloud::derive_key(password, &vault_id) {
            Ok(k) => k,
            Err(e) => {
                eprintln!("error: {e}");
                return 1;
            }
        };
        let (nonce, ciphertext) = match cloud::encrypt_blob(&key, &bytes) {
            Ok(v) => v,
            Err(e) => {
                eprintln!("error: {e}");
                return 1;
            }
        };
        match client.create_vault(&vault_id, &name, &nonce, &ciphertext) {
            Ok(_) => {
                println!("created vault {name}");
                0
            }
            Err(e) => {
                eprintln!("error: {e}");
                1
            }
        }
    } else {
        let path = match &opts.db {
            Some(p) => p,
            None => {
                eprintln!("error: 本地创建密码库需要 --db <file>");
                return 2;
            }
        };
        match fs::write(path, &bytes) {
            Ok(()) => {
                println!("created vault {name} at {}", path.display());
                remember_default_vault(opts);
                0
            }
            Err(e) => {
                eprintln!("error: {e}");
                1
            }
        }
    }
}

fn open_cloud(
    opts: &Options,
    password: &str,
) -> Result<(kdbx::Database, bool, Box<Persist>), String> {
    let (server, email, secret_key) =
        resolve_cloud_credentials(opts, keychain::default_key_store())?;
    let client = cloud::CloudClient::login(&server, &email, &secret_key)?;
    let vaults = client.list_vaults()?;
    let vault = match &opts.vault {
        Some(selector) => vaults
            .into_iter()
            .find(|v| v.id == *selector || v.name == *selector)
            .ok_or_else(|| format!("未找到密码库：{selector}"))?,
        None => vaults
            .into_iter()
            .next()
            .ok_or_else(|| "账号下还没有云密码库".to_string())?,
    };
    let key = cloud::derive_key(password, &vault.id)?;
    let rows = client.list_rows(&vault.id)?;
    // Row storage is the source of truth; fall back to the legacy blob only
    // when the vault has no rows yet (old 0-row blob-only vaults).
    if rows.is_empty() {
        let full = client.get_vault(&vault.id)?;
        let plain = cloud::decrypt_blob(&key, &full.nonce, &full.ciphertext)?;
        let db = kdbx::load(&plain, password, None)?;
        let base_updated_at = full.updated_at.unwrap_or(0);
        let persist: Box<Persist> = Box::new(move |db, password| {
            let bytes = kdbx::save(db, password, None)?;
            let (nonce, ciphertext) = cloud::encrypt_blob(&key, &bytes)?;
            client
                .update_vault(&full.id, &full.name, &nonce, &ciphertext, base_updated_at)
                .map_err(|e| format!("写入云库失败（可能是并发冲突）：{e}"))?;
            Ok(())
        });
        return Ok((db, true, persist));
    }
    let (db, synced) = match row_store::database_from_rows(&vault.name, &rows, &key) {
        Ok(v) => v,
        Err(row_err) => {
            // Mirror the app: rows may be encrypted under a remembered
            // auto-unlock key instead of the typed master. When the legacy
            // blob opens with the typed master, rebuild from it and rewrite
            // the rows under the current vault key on the next save.
            let full = client.get_vault(&vault.id)?;
            let plain = cloud::decrypt_blob(&key, &full.nonce, &full.ciphertext).map_err(|e| {
                format!("行数据无法用当前主密码解密，且旧 blob 也打不开（{row_err}；{e}）")
            })?;
            let db = kdbx::load(&plain, password, None)?;
            let synced: HashMap<String, row_store::DecodedRow> = rows
                .iter()
                .map(|r| {
                    (
                        r.uuid.clone(),
                        row_store::DecodedRow {
                            group_path: String::new(),
                            fields: HashMap::new(),
                            protected: Vec::new(),
                            icon: None,
                            updated_at: r.updated_at,
                        },
                    )
                })
                .collect();
            (db, synced)
        }
    };
    let persist: Box<Persist> = Box::new(move |db, _password| {
        let (upserts, deletes) = row_store::diff_entries(db, &key, &synced)?;
        if upserts.is_empty() && deletes.is_empty() {
            return Ok(());
        }
        let (_upserted, conflicts) = client
            .sync_entries(&vault.id, &upserts, &deletes)
            .map_err(|e| format!("写入云库失败：{e}"))?;
        if !conflicts.is_empty() {
            eprintln!(
                "提示：{} 行因并发冲突未写入，将在下次保存时重试。",
                conflicts.len()
            );
        }
        Ok(())
    });
    Ok((db, true, persist))
}

/// Resolves the cloud vault selector to a vault id (no blob download).
fn resolve_cloud_vault_id(opts: &Options) -> Result<String, String> {
    let (server, email, secret_key) =
        resolve_cloud_credentials(opts, keychain::default_key_store())?;
    let client = cloud::CloudClient::login(&server, &email, &secret_key)?;
    let vaults = client.list_vaults()?;
    match &opts.vault {
        Some(selector) => vaults
            .into_iter()
            .find(|v| v.id == *selector || v.name == *selector)
            .map(|v| v.id)
            .ok_or_else(|| format!("未找到密码库：{selector}")),
        None => vaults
            .into_iter()
            .next()
            .map(|v| v.id)
            .ok_or_else(|| "账号下还没有云密码库".to_string()),
    }
}

/// Row-level store operations (`rows list` / `rows delete <uuids>`), used to
/// reconcile the per-entry rows against the blob-backed truth.
fn run_cloud_vaults(opts: &Options, password: &str) -> i32 {
    let (server, email, secret_key) =
        match resolve_cloud_credentials(opts, keychain::default_key_store()) {
            Ok(c) => c,
            Err(e) => {
                eprintln!("error: {e}");
                return 1;
            }
        };
    let client = match cloud::CloudClient::login(&server, &email, &secret_key) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };
    let vaults = match client.list_vaults() {
        Ok(v) => v,
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };
    if vaults.is_empty() {
        println!("账号下还没有云密码库");
        return 0;
    }
    for vault in &vaults {
        let key = cloud::derive_key(password, &vault.id);
        let mut row_count = 0usize;
        let mut row_opens = false;
        let mut blob_opens = false;
        let mut key_fp = String::from("derive_err");
        if let Ok(key) = key {
            key_fp = format!("{:02x}{:02x}{:02x}{:02x}", key[0], key[1], key[2], key[3]);
            if let Ok(rows) = client.list_rows(&vault.id) {
                row_count = rows.len();
                if let Some(row) = rows.first() {
                    row_opens = cloud::decrypt_row(&key, &row.nonce, &row.ciphertext).is_ok();
                }
            }
            if let Ok(full) = client.get_vault(&vault.id) {
                blob_opens = cloud::decrypt_blob(&key, &full.nonce, &full.ciphertext).is_ok();
            }
        }
        println!(
            "{}\tname_len={}\tupdated={:?}\trows={}\trow_opens={}\tblob_opens={}\tkey_fp={}",
            vault.id,
            vault.name.len(),
            vault.updated_at,
            row_count,
            row_opens,
            blob_opens,
            key_fp
        );
    }
    0
}

fn run_rows(opts: &Options) -> i32 {
    let sub = opts.query.as_str();
    let vault_id = match resolve_cloud_vault_id(opts) {
        Ok(id) => id,
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };
    let (server, email, secret_key) =
        match resolve_cloud_credentials(opts, keychain::default_key_store()) {
            Ok(c) => c,
            Err(e) => {
                eprintln!("error: {e}");
                return 1;
            }
        };
    let client = match cloud::CloudClient::login(&server, &email, &secret_key) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };
    match sub {
        "list" => match client.list_rows(&vault_id) {
            Ok(rows) => {
                for r in &rows {
                    println!("{}\t{}\t{}", r.uuid, r.group, r.updated_at);
                }
                0
            }
            Err(e) => {
                eprintln!("error: {e}");
                1
            }
        },
        "delete" => {
            let target = opts.item_target.as_deref().unwrap_or("");
            let uuids: Vec<String> = target
                .split([',', ' ', '\n'])
                .filter(|s| !s.is_empty())
                .map(String::from)
                .collect();
            if uuids.is_empty() {
                eprintln!("error: rows delete 需要 uuid 列表（逗号/空格分隔）");
                return 2;
            }
            match client.delete_rows(&vault_id, &uuids) {
                Ok(conflicts) => {
                    println!(
                        "deleted {} rows ({} unknown/conflict)",
                        uuids.len().saturating_sub(conflicts),
                        conflicts
                    );
                    0
                }
                Err(e) => {
                    eprintln!("error: {e}");
                    1
                }
            }
        }
        "dump" => {
            let target = opts.item_target.clone().unwrap_or_default();
            if target.is_empty() {
                eprintln!("error: rows dump 需要输出文件路径");
                return 2;
            }
            let dump = (|| -> Result<serde_json::Value, String> {
                let rows = client.list_rows(&vault_id)?;
                let vault = client.get_vault(&vault_id)?;
                Ok(serde_json::json!({
                    "vaultId": vault_id,
                    "rows": rows.iter().map(|r| serde_json::json!({
                        "uuid": r.uuid,
                        "group": r.group,
                        "nonce": BASE64.encode(&r.nonce),
                        "ciphertext": BASE64.encode(&r.ciphertext),
                        "updatedAt": r.updated_at,
                    })).collect::<Vec<_>>(),
                    "blob": {
                        "nonce": BASE64.encode(&vault.nonce),
                        "ciphertext": BASE64.encode(&vault.ciphertext),
                        "updatedAt": vault.updated_at,
                    },
                }))
            })();
            match dump {
                Ok(value) => match std::fs::File::create(&target)
                    .and_then(|mut f| f.write_all(value.to_string().as_bytes()))
                {
                    Ok(_) => {
                        println!("dumped to {target}");
                        0
                    }
                    Err(e) => {
                        eprintln!("error: cannot write {target}: {e}");
                        1
                    }
                },
                Err(e) => {
                    eprintln!("error: {e}");
                    1
                }
            }
        }
        _ => {
            usage();
            2
        }
    }
}

/// Resolves the cloud server + email + Secret Key for a `--cloud` operation.
///
/// Explicit `--server`/`--email`/`--secret-key` win; otherwise the account
/// saved by `openvalut-cli auth login` is reused so repeated commands don't
/// need to restate the credentials.
fn resolve_cloud_credentials(
    opts: &Options,
    store: &dyn keychain::KeyStore,
) -> Result<(String, String, String), String> {
    let home = home_dir().ok_or_else(|| "无法确定 home 目录".to_string())?;
    let account_path = app_data_dir(&home).join(auth::ACCOUNT_FILE);
    let saved = auth::load_account(&account_path)?;
    let server = match opts
        .server
        .clone()
        .or_else(|| saved.as_ref().map(|a| a.server.clone()))
    {
        Some(s) => s,
        None => "https://openvalut.example.com/".to_string(),
    };
    let email = opts
        .email
        .clone()
        .or_else(|| saved.as_ref().map(|a| a.email.clone()))
        .ok_or_else(|| "--cloud 需要 --email，或先运行 openvalut-cli auth login".to_string())?;
    let secret_key = match opts.secret_key.clone() {
        Some(k) => k,
        None => store.get(keychain::CLOUD_SECRET_KEY)?.ok_or_else(|| {
            "--cloud 需要 --secret-key，或先运行 openvalut-cli auth login".to_string()
        })?,
    };
    Ok((server, email, secret_key))
}

fn resolve_password(opts: &Options) -> Result<String, String> {
    resolve_password_with(opts, keychain::default_key_store())
}

fn resolve_password_with(opts: &Options, store: &dyn keychain::KeyStore) -> Result<String, String> {
    if let Some(p) = &opts.password {
        return Ok(p.clone());
    }
    if let Ok(p) = env::var("openvalut_MASTER_PASSWORD") {
        return Ok(p);
    }
    if opts.password_stdin {
        let mut line = String::new();
        io::stdin()
            .read_line(&mut line)
            .map_err(|e| e.to_string())?;
        return Ok(line.trim().to_string());
    }
    // A previously `unlock`ed master password lets `--cloud`/`--db` commands
    // run without re-prompting.
    match store.get(keychain::MASTER_PASSWORD) {
        Ok(Some(p)) if !p.is_empty() => return Ok(p),
        Ok(_) => {}
        // A locked/unavailable keychain (e.g. a bare SSH login with no desktop
        // session) must not stop us from asking interactively.
        Err(e) => eprintln!("warn: 无法读取已保存的解锁凭据：{e}"),
    }
    rpassword::prompt_password("Master password: ").map_err(|e| {
        format!(
            "无法读取主密码：{e}（可用 --password、--password-stdin、openvalut_MASTER_PASSWORD 或先运行 openvalut-cli unlock）"
        )
    })
}

fn standalone_list(opts: &Options, db: &kdbx::Database) -> i32 {
    // Read interfaces are deny-by-default: only entries the owner explicitly
    // allowed (in the app, or by setting openvalut.read-allowed=1) appear.
    let entries = kdbx::list_readable_entries(db);
    let filter = opts.query.to_lowercase();
    if entries.is_empty() && opts.query.is_empty() {
        eprintln!(
            "warning: 没有允许读取的条目。请在 App 中为该条目/分组开启“允许 CLI/脚本读取”（默认禁止读取全部条目）"
        );
    }
    for e in entries {
        if !filter.is_empty()
            && !e.title.to_lowercase().contains(&filter)
            && !e.username.to_lowercase().contains(&filter)
        {
            continue;
        }
        if opts.list_uuids {
            println!(
                "{}\t{}\t{}\t{}\t{}",
                e.id, e.title, e.username, e.group, e.file
            );
        } else {
            println!("{}\t{}\t{}\t{}", e.title, e.username, e.group, e.file);
        }
    }
    0
}

fn standalone_pam_setup(db: &kdbx::Database) -> i32 {
    let machine_id = match pam_setup::machine_id() {
        Some(id) => id,
        None => {
            eprintln!("error: 无法读取 /etc/machine-id");
            return 1;
        }
    };
    let entry = match kdbx::find_computer_entry(db, &machine_id) {
        Some(e) => e,
        None => {
            eprintln!("error: 未找到当前计算机的条目，请先在 OpenValut 侧边栏「计算机」中创建");
            return 1;
        }
    };
    let entry_ref = db.entry(entry.id).expect("entry exists");
    let secret = match kdbx::entry_value(&entry_ref, kdbx::OTP_FIELD) {
        Some(v) if !v.is_empty() => v,
        _ => {
            eprintln!("error: 计算机条目未配置两步验证码（OTP）");
            return 1;
        }
    };
    // Extract the raw base32 secret from otpauth:// URI or query format.
    let secret = match totp::parse_otp_auth(&secret) {
        Some(cfg) => base32::encode(base32::Alphabet::Rfc4648 { padding: false }, &cfg.secret),
        None => {
            eprintln!("error: 无效的两步验证码配置");
            return 1;
        }
    };
    match pam_setup::write_encrypted_totp(&secret) {
        Ok(path) => {
            println!("已写入 PAM TOTP 文件：{}", path.display());
            0
        }
        Err(e) => {
            eprintln!("error: {e}");
            1
        }
    }
}

fn item_add(db: &mut kdbx::Database, opts: &Options) -> i32 {
    let title = match opts.item_fields.title.clone().or_else(|| {
        if opts.query.is_empty() {
            None
        } else {
            Some(opts.query.clone())
        }
    }) {
        Some(t) => t,
        None => {
            eprintln!("error: item add 需要标题（--title 或位置参数）");
            return 2;
        }
    };
    let ssh_pem = match read_ssh_private_key(opts) {
        Ok(pem) => pem,
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };
    let (ak_stdin, sk_stdin) = match aksk_from_stdin(opts) {
        Ok(v) => v,
        Err(code) => return code,
    };
    let changes = kdbx::EntryChanges {
        title: Some(title.clone()),
        username: opts.item_fields.username.clone(),
        password: opts.item_fields.password.clone(),
        url: opts.item_fields.url.clone(),
        notes: opts.item_fields.notes.clone(),
        otp: opts.item_fields.otp.clone(),
        group: opts.item_fields.group.clone(),
        machine_id: opts.item_fields.machine_id.clone(),
        ssh_private_key: ssh_pem,
        access_key: ak_stdin.or_else(|| opts.item_fields.access_key.clone()),
        secret_key: sk_stdin.or_else(|| opts.item_fields.secret_key.clone()),
    };
    match kdbx::add_entry(db, &changes) {
        Ok(_) => {
            println!("added {title}");
            eprintln!("note: 新条目默认禁止 CLI/脚本读取；需要时请执行 item allow {title}");
            0
        }
        Err(e) => {
            eprintln!("error: {e}");
            1
        }
    }
}

/// 从 stdin 读一行（去掉行尾换行）。给 `--ak-stdin` / `--sk-stdin` / `--password-field-stdin` 用。
fn read_stdin_line() -> Result<String, String> {
    let mut line = String::new();
    std::io::stdin()
        .read_line(&mut line)
        .map_err(|e| e.to_string())?;
    Ok(line.trim().to_string())
}

/// AK/SK 的 stdin 入口：`--ak-stdin` 先读一行、`--sk-stdin` 再读一行。
/// 为什么要有：`--ak/--sk` 会出现在 argv 里，`ps` 一眼就看到 —— 跟
/// `--password-field-stdin` 同样的理由（2026-10-07 加，用于把腾讯云 COS 凭据导进库里）。
/// 返回 (从 stdin 得到的 AK, 从 stdin 得到的 SK)，没用到就是 (None, None)。
fn aksk_from_stdin(opts: &Options) -> Result<(Option<String>, Option<String>), i32> {
    let mut ak = None;
    let mut sk = None;
    if opts.item_fields.ak_stdin {
        if opts.item_fields.access_key.is_some() {
            eprintln!("error: 不能同时使用 --ak 和 --ak-stdin");
            return Err(2);
        }
        ak = Some(read_stdin_line().map_err(|e| {
            eprintln!("error: {e}");
            1
        })?);
    }
    if opts.item_fields.sk_stdin {
        if opts.item_fields.secret_key.is_some() {
            eprintln!("error: 不能同时使用 --sk 和 --sk-stdin");
            return Err(2);
        }
        sk = Some(read_stdin_line().map_err(|e| {
            eprintln!("error: {e}");
            1
        })?);
    }
    Ok((ak, sk))
}

fn item_edit(db: &mut kdbx::Database, opts: &Options, target: &str) -> i32 {
    let (ak_stdin, sk_stdin) = match aksk_from_stdin(opts) {
        Ok(v) => v,
        Err(code) => return code,
    };
    let entry = match kdbx::find_entry(db, target) {
        Some(e) => e,
        None => {
            eprintln!("error: no matching entry");
            return 1;
        }
    };
    let ssh_pem = match read_ssh_private_key(opts) {
        Ok(pem) => pem,
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };
    // `--password-field-stdin` reads the new password from one stdin line so
    // the secret never appears on the command line (visible to `ps`).
    let password_from_stdin = if opts.item_fields.password_stdin {
        match opts.item_fields.password.clone() {
            Some(_) => {
                eprintln!("error: 不能同时使用 --password-field 和 --password-field-stdin");
                return 2;
            }
            None => {
                let mut line = String::new();
                match io::stdin().read_line(&mut line) {
                    Ok(_) => Some(line.trim().to_string()),
                    Err(e) => {
                        eprintln!("error: {e}");
                        return 1;
                    }
                }
            }
        }
    } else {
        None
    };
    // 同上一段：--otp-stdin 从 stdin 再读一行（若同时用了 --password-field-stdin，
    // 顺序是「先密码行、再 OTP 行」），secret 同样不进命令行。
    let otp_from_stdin = if opts.item_fields.otp_stdin {
        match opts.item_fields.otp.clone() {
            Some(_) => {
                eprintln!("error: 不能同时使用 --otp 和 --otp-stdin");
                return 2;
            }
            None => {
                let mut line = String::new();
                match io::stdin().read_line(&mut line) {
                    Ok(_) => Some(line.trim().to_string()),
                    Err(e) => {
                        eprintln!("error: {e}");
                        return 1;
                    }
                }
            }
        }
    } else {
        None
    };
    let changes = kdbx::EntryChanges {
        title: opts.item_fields.title.clone(),
        username: opts.item_fields.username.clone(),
        password: password_from_stdin.or_else(|| opts.item_fields.password.clone()),
        url: opts.item_fields.url.clone(),
        notes: opts.item_fields.notes.clone(),
        otp: otp_from_stdin.or_else(|| opts.item_fields.otp.clone()),
        group: opts.item_fields.group.clone(),
        machine_id: opts.item_fields.machine_id.clone(),
        ssh_private_key: ssh_pem,
        access_key: ak_stdin.or_else(|| opts.item_fields.access_key.clone()),
        secret_key: sk_stdin.or_else(|| opts.item_fields.secret_key.clone()),
    };
    if changes.title.is_none()
        && changes.username.is_none()
        && changes.password.is_none()
        && changes.url.is_none()
        && changes.notes.is_none()
        && changes.otp.is_none()
        && changes.group.is_none()
        && changes.ssh_private_key.is_none()
        && changes.access_key.is_none()
        && changes.secret_key.is_none()
    {
        eprintln!("error: item edit 至少需要修改一个字段");
        return 2;
    }
    match kdbx::edit_entry(db, entry.id, &changes) {
        Ok(()) => {
            println!("edited {}", entry.title);
            0
        }
        Err(e) => {
            eprintln!("error: {e}");
            1
        }
    }
}

/// Reads the optional `--ssh-private-key <file>` into a PEM string.
fn read_ssh_private_key(opts: &Options) -> Result<Option<String>, String> {
    match &opts.item_fields.ssh_private_key {
        Some(path) => fs::read_to_string(path)
            .map(Some)
            .map_err(|e| format!("无法读取 SSH 私钥 {}: {e}", path.display())),
        None => Ok(None),
    }
}

fn item_delete(db: &mut kdbx::Database, target: &str) -> i32 {
    let entry = match kdbx::find_entry(db, target) {
        Some(e) => e,
        None => {
            eprintln!("error: no matching entry");
            return 1;
        }
    };
    match kdbx::delete_entry(db, entry.id) {
        Ok(()) => {
            println!("deleted {}", entry.title);
            0
        }
        Err(e) => {
            eprintln!("error: {e}");
            1
        }
    }
}

/// `item allow` / `item deny`: set or clear the hidden read-allow field so
/// list/get interfaces pick the entry up (or keep it hidden). Mirrors the
/// switch shown in the app's entry details page.
fn item_set_read_allowed(db: &mut kdbx::Database, target: &str, allowed: bool) -> i32 {
    let info = match kdbx::find_entry(db, target) {
        Some(info) => info,
        None => {
            eprintln!("error: no matching entry: {target}");
            return 1;
        }
    };
    let mut entry = db.entry_mut(info.id).expect("entry exists");
    if allowed {
        entry.set_unprotected(kdbx::READ_ALLOWED_FIELD, "1");
    } else {
        entry.fields.remove(kdbx::READ_ALLOWED_FIELD);
    }
    println!(
        "{} {}",
        if allowed {
            "已允许读取"
        } else {
            "已禁止读取"
        },
        info.title
    );
    0
}

/// Permanently removes every blank/untitled entry (created by a buggy
/// auto-save). Prints how many were deleted.
fn item_delete_empty_titles(db: &mut kdbx::Database) -> i32 {
    match kdbx::delete_empty_title_entries(db) {
        Ok(count) => {
            println!("deleted {count} empty-title entries");
            0
        }
        Err(e) => {
            eprintln!("error: {e}");
            1
        }
    }
}

/// Imports KEY=VALUE pairs from a `.env` file (auto-discovered when no path
/// is given) into the vault as one entry per variable, under `--group`
/// (default `.env`). Existing entries are updated in place, so re-importing
/// never creates duplicates.
fn item_import_env(db: &mut kdbx::Database, opts: &Options) -> i32 {
    let group = opts
        .item_fields
        .group
        .clone()
        .unwrap_or_else(|| ".env".to_string());
    let paths = match &opts.item_target {
        Some(p) => vec![PathBuf::from(p)],
        None => {
            let cwd = match env::current_dir() {
                Ok(d) => d,
                Err(e) => {
                    eprintln!("error: 无法确定当前目录：{e}");
                    return 1;
                }
            };
            match dotenv::find_env(&cwd) {
                Some(paths) => paths,
                None => {
                    eprintln!("error: 未找到 .env 文件（可用位置参数指定路径）");
                    return 1;
                }
            }
        }
    };
    let vars = match dotenv::parse_files(&paths) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("error: {e}");
            return 1;
        }
    };
    if vars.is_empty() {
        let label = paths
            .iter()
            .map(|p| p.display().to_string())
            .collect::<Vec<_>>()
            .join(", ");
        eprintln!("error: {label} 中没有可导入的变量");
        return 1;
    }
    let mut added = 0;
    let mut updated = 0;
    for (key, value) in vars {
        let existing = kdbx::list_entries(db)
            .into_iter()
            .find(|e| e.title == key && e.group == group);
        let result = match &existing {
            Some(e) => kdbx::edit_entry(
                db,
                e.id,
                &kdbx::EntryChanges {
                    password: Some(value),
                    ..Default::default()
                },
            ),
            None => kdbx::add_entry(
                db,
                &kdbx::EntryChanges {
                    title: Some(key.clone()),
                    password: Some(value),
                    group: Some(group.clone()),
                    ..Default::default()
                },
            )
            .map(|_| ()),
        };
        match result {
            Ok(_) => {
                if existing.is_some() {
                    updated += 1;
                } else {
                    added += 1;
                }
            }
            Err(e) => {
                eprintln!("error: 导入 {key} 失败：{e}");
                return 1;
            }
        }
    }
    let label = paths
        .iter()
        .map(|p| p.display().to_string())
        .collect::<Vec<_>>()
        .join(", ");
    println!("imported {added} new, updated {updated} variables from {label}");
    0
}

fn usage() {
    println!(
        "\nopenvalut-cli — read and manage OpenValut credentials

Usage:
  openvalut-cli list [query]
  openvalut-cli get <query> [--field label|group|file]
  openvalut-cli run --env NAME=op://vault/item/field [--env ...] -- <command> [args...]
  openvalut-cli pam-setup
  openvalut-cli [--db <vault.kdbx>] [--key-file <f>] pam-setup
  openvalut-cli [--db <vault.kdbx>] [--key-file <f>] item add|edit|delete <arg> [options]
  openvalut-cli [--db <vault.kdbx>] [--key-file <f>] item import-env [path] [--group <g>]
  openvalut-cli --cloud [--server <url>] --email <e> --secret-key <key> <command>
  openvalut-cli agent list|remove-all
  openvalut-cli [--db <vault.kdbx>|--cloud ...] agent add|remove <query>
  openvalut-cli auth login --email <e> --secret-key <key> [--server <url>]
  openvalut-cli auth login --scan [--server <url>]
  openvalut-cli auth status|logout
  openvalut-cli unlock [--sudo] [--password <pw>]
  openvalut-cli unlock --scan [--server <url>]
  openvalut-cli lock
  openvalut-cli exec [--sudo] [--env K=V ...] -- <command> [args...]

不带桌面 App 也能给脚本供凭据（等价于 App 内的 credential server）：
  openvalut-cli serve [--db <vault.kdbx>] [--key-file <f>] [--port <n>]

Standalone options:
  --db <file>            open a local KDBX file directly
  --key-file <file>      keyfile for the KDBX database
  --cloud                operate on the OpenValut Cloud vault
  --server <url>         cloud server (default https://openvalut.example.com/)
  --email <e>            cloud account email (default: saved by auth login)
  --secret-key <key>     cloud account Secret Key (default: saved by auth login)
  --vault <name|id>      cloud vault to use (default: first vault)
  --password <pw>        master password (alternative: --password-stdin,
                         openvalut_MASTER_PASSWORD, or interactive prompt)

Cloud auth:
  auth login             verify and remember the cloud account so --cloud
                         commands reuse it (email + Secret Key, stored 0600)
  auth login --scan      print a QR code and let the phone (already signed in)
                         confirm: the account is remembered without typing the
                         Secret Key on the PC. The phone's eye must see this
                         terminal, so it is an in-person flow.
  auth status            show the saved cloud account
  auth logout            forget the saved cloud account

Unlock / sudo:
  unlock                 prompt and store the vault master password (never
                         written to disk in plaintext): on Linux it goes to
                         the kernel user keyring — shared by every terminal
                         and SSH login of this user, cleared at reboot — and
                         to the OS keychain for persistence across reboots.
                         Later --cloud/--db commands then run without
                         re-prompting.
  unlock --sudo          store the system sudo password used by `exec --sudo`
  unlock --scan          print a QR code; when the phone that has the vault
                         unlocked scans it, the master password is relayed
                         end-to-end encrypted back to this PC, which stores it
                         exactly like a typed unlock (in-person flow).
  lock                   clear the stored master and sudo passwords
  exec [--sudo] -- ...   run a command; with --sudo the stored sudo password
                         (and the current machine TOTP when --db/--cloud is
                         given) is fed over a PTY, so `sudo cmd` needs no typing
  --sudo                 with unlock/exec: operate on the system sudo password

Item commands (standalone):
  item add <title> [--username <u>] [--password-field <p>] [--url <u>]
                   [--notes <n>] [--otp <otpauth-uri>] [--group <g>]
                   [--ssh-private-key <file>]
                   [--access-key-id <ak>] [--secret-access-key <sk>]
                   （AK/SK 也可从 stdin 来：--ak-stdin / --sk-stdin，各读一行，
                     避免密钥出现在 argv 里被 ps 看到）
  item edit <query> [--title <t>] [--username <u>] [--password-field <p>]
                    [--password-field-stdin]
                    [--url <u>] [--notes <n>] [--otp <uri>] [--otp-stdin] [--group <g>]
                    [--ssh-private-key <file>]
                    [--access-key-id <ak>] [--secret-access-key <sk>]
                                (AK/SK 也可写 --ak / --sk)
  item delete <query>
  item allow <query>            allow CLI/scripts to list/read the entry
  item deny <query>             restore the default (deny CLI/scripts)
  item delete --empty-title
  item import-env [path]        import .env KEY=VALUE pairs as vault entries
                                (auto-search current dir and parents when no
                                path is given; .env.local overrides .env)

SSH agent commands:
  agent list                    list keys currently loaded in the ssh-agent
  agent add <query>             load the entry's SSH private key into ssh-agent
  agent remove <query>          remove the entry's key from the ssh-agent
  agent remove-all              remove all keys from the ssh-agent

Socket mode options (default; talks to the unlocked app):
  --token <path>    override token file path
  --port <n>        override server port (useful for testing)
  --help            show this help

Read access (allow-list):
  list and get are deny-by-default: only entries the owner explicitly allowed
  in the OpenValut app (entry detail switch or the group menu, stored as the
  hidden openvalut.read-allowed=1 field) are listed / returned. Socket list
  JSON also carries an \"allowed\" field on every entry.

Security note:
  read / export / sudo / totp and standalone get printed the password or
  one-time password to the terminal, so they have been removed. Use list for
  non-sensitive metadata, or run / exec to hand values to a process without
  echoing them.

Without --db/--cloud the CLI tries the running app first. If the app is not
running (no credential-server token), list/pam-setup automatically fall back
to the local KDBX remembered by the last successful `--db` run, so the CLI
works standalone without the desktop app."
    );
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;
    use std::net::TcpListener;
    use std::thread;

    #[test]
    fn parses_commands_and_options() {
        let opts = parse_args(&[
            "get".into(),
            "github".into(),
            "--field".into(),
            "json".into(),
            "--token".into(),
            "/tmp/t".into(),
            "--port".into(),
            "9999".into(),
        ])
        .expect("valid args");
        assert_eq!(opts.command.as_deref(), Some("get"));
        assert_eq!(opts.query, "github");
        assert_eq!(opts.field.as_deref(), Some("json"));
        assert_eq!(opts.token, Some(PathBuf::from("/tmp/t")));
        assert_eq!(opts.port.as_deref(), Some("9999"));
        assert!(!opts.help);
        assert!(!opts.cloud);
    }

    #[test]
    fn parses_standalone_options() {
        let opts = parse_args(&[
            "--db".into(),
            "v.kdbx".into(),
            "--cloud".into(),
            "--email".into(),
            "a@b.c".into(),
            "--secret-key".into(),
            "ab".repeat(16),
            "item".into(),
            "add".into(),
            "GitHub".into(),
            "--password-field".into(),
            "x".into(),
        ])
        .expect("valid args");
        assert!(opts.cloud);
        assert_eq!(opts.db, Some(PathBuf::from("v.kdbx")));
        assert_eq!(opts.email.as_deref(), Some("a@b.c"));
        assert_eq!(opts.command.as_deref(), Some("item"));
        assert_eq!(opts.query, "add");
        assert_eq!(opts.item_fields.password.as_deref(), Some("x"));
    }

    #[test]
    fn rejects_bad_usage() {
        assert!(parse_args(&["--unknown".into()]).is_none());
        assert!(parse_args(&["--token".into()]).is_none());
        assert!(parse_args(&["get".into(), "a".into(), "b".into()]).is_none());
    }

    #[test]
    fn help_flag_is_recognized_anywhere() {
        let opts = parse_args(&["list".into(), "--help".into()]).expect("help");
        assert!(opts.help);
    }

    use crate::keychain::KeyStore;
    use std::cell::RefCell;
    use std::collections::HashMap;
    struct FakeKeyStore(RefCell<HashMap<String, String>>);
    impl keychain::KeyStore for FakeKeyStore {
        fn get(&self, id: &str) -> Result<Option<String>, String> {
            Ok(self.0.borrow().get(id).cloned())
        }
        fn set(&self, id: &str, value: &str) -> Result<(), String> {
            self.0
                .borrow_mut()
                .insert(id.to_string(), value.to_string());
            Ok(())
        }
        fn delete(&self, id: &str) -> Result<bool, String> {
            Ok(self.0.borrow_mut().remove(id).is_some())
        }
    }

    #[test]
    fn resolve_password_prefers_explicit_then_unlocked() {
        env::remove_var("openvalut_MASTER_PASSWORD");
        // --password wins even when the keychain has a value.
        let mut opts = Options {
            password: Some("explicit".into()),
            ..Options::default()
        };
        let store = FakeKeyStore(RefCell::new(HashMap::new()));
        assert_eq!(resolve_password_with(&opts, &store).unwrap(), "explicit");

        // No explicit password/env/stdin -> falls back to the unlocked master.
        opts.password = None;
        let store = FakeKeyStore(RefCell::new(HashMap::new()));
        store.set(keychain::MASTER_PASSWORD, "unlocked").unwrap();
        assert_eq!(resolve_password_with(&opts, &store).unwrap(), "unlocked");
    }

    #[test]
    fn unlock_and_lock_toggle_keychain_passwords() {
        // Isolate from any real saved cloud account so a bare `unlock` does
        // not try to validate against the network.
        let tmp = std::env::temp_dir().join(format!("openvalut-unlock-it-{}", std::process::id()));
        let _ = fs::create_dir_all(tmp.join(".config"));
        let old_home = env::var_os("HOME");
        let old_xdg = env::var_os("XDG_CONFIG_HOME");
        env::set_var("HOME", &tmp);
        env::set_var("XDG_CONFIG_HOME", tmp.join(".config"));

        let store = FakeKeyStore(RefCell::new(HashMap::new()));

        let mut opts = Options {
            password: Some("mypass".into()),
            ..Options::default()
        };
        assert_eq!(unlock_command(&opts, &store), 0);
        assert_eq!(
            store.get(keychain::MASTER_PASSWORD).unwrap().as_deref(),
            Some("mypass")
        );

        opts.sudo_mode = true;
        opts.password = Some("sudopass".into());
        assert_eq!(unlock_command(&opts, &store), 0);
        assert_eq!(
            store.get(keychain::SUDO_PASSWORD).unwrap().as_deref(),
            Some("sudopass")
        );

        // lock removes both; a second lock with nothing stored errors.
        assert_eq!(lock_command(&store), 0);
        assert!(store.get(keychain::MASTER_PASSWORD).unwrap().is_none());
        assert!(store.get(keychain::SUDO_PASSWORD).unwrap().is_none());
        assert_eq!(lock_command(&store), 1);

        // Restore the environment.
        match old_home {
            Some(h) => env::set_var("HOME", h),
            None => env::remove_var("HOME"),
        }
        match old_xdg {
            Some(x) => env::set_var("XDG_CONFIG_HOME", x),
            None => env::remove_var("XDG_CONFIG_HOME"),
        }
        let _ = fs::remove_dir_all(&tmp);
    }

    #[test]
    fn unlock_with_saved_account_but_no_secret_key_stores_unverified() {
        // A saved cloud account without a Secret Key used to fail `unlock`
        // *after* the user typed the master password ("--cloud 需要
        // --secret-key"). It must instead store the password unverified: the
        // missing key is a config gap the real --cloud command reports.
        let tmp =
            std::env::temp_dir().join(format!("openvalut-unlock-nokey-{}", std::process::id()));
        let _ = fs::create_dir_all(tmp.join(".config"));
        let old_home = env::var_os("HOME");
        let old_xdg = env::var_os("XDG_CONFIG_HOME");
        env::set_var("HOME", &tmp);
        env::set_var("XDG_CONFIG_HOME", tmp.join(".config"));

        let home = home_dir().expect("home");
        let account_path = app_data_dir(&home).join(auth::ACCOUNT_FILE);
        auth::save_account(
            &account_path,
            &auth::CloudAccount {
                server: "https://openvalut.example.com".to_string(),
                email: "a@b.c".to_string(),
            },
        )
        .expect("save account");

        let store = FakeKeyStore(RefCell::new(HashMap::new()));
        let opts = Options {
            password: Some("mypass".into()),
            ..Options::default()
        };
        assert_eq!(unlock_command(&opts, &store), 0);
        assert_eq!(
            store.get(keychain::MASTER_PASSWORD).unwrap().as_deref(),
            Some("mypass")
        );

        match old_home {
            Some(h) => env::set_var("HOME", h),
            None => env::remove_var("HOME"),
        }
        match old_xdg {
            Some(x) => env::set_var("XDG_CONFIG_HOME", x),
            None => env::remove_var("XDG_CONFIG_HOME"),
        }
        let _ = fs::remove_dir_all(&tmp);
    }

    #[test]
    fn request_round_trips_over_loopback() {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let port = listener.local_addr().unwrap().port();
        let handle = thread::spawn(move || {
            let (mut socket, _) = listener.accept().unwrap();
            let mut reader = BufReader::new(socket.try_clone().unwrap());
            let mut line = String::new();
            reader.read_line(&mut line).unwrap();
            assert!(line.contains("\"token\":\"s3cret-token\""));
            assert!(line.contains("\"method\":\"ping\""));
            socket
                .write_all(b"{\"id\":1,\"ok\":true,\"data\":{\"pong\":true}}\n")
                .unwrap();
            socket.flush().unwrap();
        });
        let params = Map::new();
        let response = request(port, "s3cret-token", "ping", &params).expect("request");
        assert!(response.ok);
        assert_eq!(response.data.unwrap()["pong"], Value::Bool(true));
        handle.join().unwrap();
    }

    #[test]
    fn request_explains_connection_refusal() {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let port = listener.local_addr().unwrap().port();
        drop(listener);

        let error = match request(port, "token", "ping", &Map::new()) {
            Ok(_) => panic!("request unexpectedly succeeded"),
            Err(error) => error,
        };
        assert!(error.contains("Open the app with an unlocked vault"));
    }

    #[test]
    fn resolves_data_directory() {
        let temp = std::env::temp_dir().join("openvalut-cli-app-data-test");
        let _ = fs::remove_dir_all(&temp);
        fs::create_dir_all(temp.join(".openvalut").join("data")).unwrap();
        fs::write(
            temp.join(".openvalut").join("data").join("openvalut.token"),
            "tok",
        )
        .unwrap();

        // Migrates legacy directory to XDG target when target does not exist.
        env::set_var("XDG_CONFIG_HOME", temp.join("xdg-custom"));
        let migrated = temp.join("xdg-custom/openvalut/data");
        assert_eq!(app_data_dir(&temp), migrated);
        assert!(migrated.join("openvalut.token").exists());

        // Existing target is used as-is (no overwrite/migration).
        let existing = temp.join("xdg-custom2/openvalut/data");
        fs::create_dir_all(&existing).unwrap();
        fs::write(existing.join("openvalut.port"), "12345").unwrap();
        env::set_var("XDG_CONFIG_HOME", temp.join("xdg-custom2"));
        assert_eq!(app_data_dir(&temp), existing);

        env::remove_var("XDG_CONFIG_HOME");
        // Defaults to ~/.config/openvalut/data.
        assert_eq!(app_data_dir(&temp), temp.join(".config/openvalut/data"));

        let _ = fs::remove_dir_all(&temp);
    }

    #[cfg(target_os = "macos")]
    #[test]
    fn resolves_macos_sandbox_credential_server_directory() {
        let temp = std::env::temp_dir().join(format!(
            "openvalut-cli-macos-credential-server-test-{}",
            std::process::id()
        ));
        let sandboxed = temp.join(
            "Library/Containers/app.openvalut/Data/Library/Application Support/app.openvalut",
        );
        fs::create_dir_all(&sandboxed).unwrap();
        fs::write(sandboxed.join("openvalut.token"), "token").unwrap();

        assert_eq!(credential_server_data_dir(&temp), sandboxed);

        let _ = fs::remove_dir_all(&temp);
    }
}
