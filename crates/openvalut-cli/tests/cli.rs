// End-to-end tests: run the real binary against a mock credential server.
use std::fs;
use std::io::{BufRead, BufReader, Read, Write};
use std::net::TcpListener;
use std::path::PathBuf;
use std::process::{Command, Output};
use std::sync::{Arc, Mutex};
use std::thread;

struct MockServer {
    port: u16,
    request: Arc<Mutex<Option<String>>>,
    handle: thread::JoinHandle<()>,
}

impl MockServer {
    fn spawn(response: &str) -> MockServer {
        let listener = TcpListener::bind("127.0.0.1:0").expect("bind");
        let port = listener.local_addr().unwrap().port();
        let request = Arc::new(Mutex::new(None));
        let captured = Arc::clone(&request);
        let response = response.to_string();
        let handle = thread::spawn(move || {
            let (mut socket, _) = listener.accept().expect("accept");
            let mut reader = BufReader::new(socket.try_clone().expect("clone"));
            let mut line = String::new();
            reader.read_line(&mut line).expect("read request");
            *captured.lock().unwrap() = Some(line);
            socket
                .write_all(response.as_bytes())
                .expect("write response");
            socket.write_all(b"\n").expect("write newline");
            socket.flush().expect("flush");
        });
        MockServer {
            port,
            request,
            handle,
        }
    }

    fn join(self) -> String {
        self.handle.join().expect("server thread panicked");
        self.request
            .lock()
            .unwrap()
            .clone()
            .expect("no request captured")
    }
}

/// Serves a scripted sequence of responses over one connection per request
/// (the CLI opens a fresh TCP connection for every `resolve` call).
struct MockServerSeq {
    port: u16,
    requests: Arc<Mutex<Vec<String>>>,
    handle: thread::JoinHandle<()>,
}

impl MockServerSeq {
    fn spawn(responses: &[&str]) -> MockServerSeq {
        let listener = TcpListener::bind("127.0.0.1:0").expect("bind");
        let port = listener.local_addr().unwrap().port();
        let requests = Arc::new(Mutex::new(Vec::new()));
        let captured = Arc::clone(&requests);
        let responses: Vec<String> = responses.iter().map(|s| s.to_string()).collect();
        let handle = thread::spawn(move || {
            for response in responses {
                let (mut socket, _) = listener.accept().expect("accept");
                let mut reader = BufReader::new(socket.try_clone().expect("clone"));
                let mut line = String::new();
                reader.read_line(&mut line).expect("read request");
                captured.lock().unwrap().push(line);
                socket
                    .write_all(response.as_bytes())
                    .expect("write response");
                socket.write_all(b"\n").expect("write newline");
                socket.flush().expect("flush");
            }
        });
        MockServerSeq {
            port,
            requests,
            handle,
        }
    }

    fn join(self) -> Vec<String> {
        self.handle.join().expect("server thread panicked");
        self.requests.lock().unwrap().clone()
    }
}

/// Minimal one-shot HTTP/1.1 responder: answers each accepted connection with
/// the next scripted `(status, json_body)`. Used to exercise the QR-code login
/// flow (`POST /api/login/scan` then `GET /api/login/scan/{id}`).
struct MockHttpServer {
    port: u16,
    requests: Arc<Mutex<Vec<String>>>,
    handle: thread::JoinHandle<()>,
}

impl MockHttpServer {
    fn spawn(responses: Vec<(u16, String)>) -> MockHttpServer {
        let listener = TcpListener::bind("127.0.0.1:0").expect("bind");
        let port = listener.local_addr().unwrap().port();
        let requests = Arc::new(Mutex::new(Vec::new()));
        let captured = Arc::clone(&requests);
        let handle = thread::spawn(move || {
            for (status, response_body) in responses {
                let (mut socket, _) = listener.accept().expect("accept");
                let mut reader = BufReader::new(socket.try_clone().expect("clone"));
                // Read the request line + headers, then the Content-Length body.
                let mut head = String::new();
                loop {
                    let mut line = String::new();
                    if reader.read_line(&mut line).unwrap_or(0) == 0 {
                        break;
                    }
                    if line == "\r\n" || line == "\n" {
                        break;
                    }
                    head.push_str(&line);
                }
                let content_length = head
                    .lines()
                    .find_map(|l| {
                        let (key, value) = l.split_once(':')?;
                        key.eq_ignore_ascii_case("content-length")
                            .then(|| value.trim().parse::<usize>().ok())
                            .flatten()
                    })
                    .unwrap_or(0);
                if content_length > 0 {
                    let mut body = vec![0u8; content_length];
                    let _ = reader.read_exact(&mut body);
                }
                captured.lock().unwrap().push(head);
                let response = format!(
                    "HTTP/1.1 {status} Status\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{response_body}",
                    response_body.len()
                );
                socket
                    .write_all(response.as_bytes())
                    .expect("write response");
                socket.flush().expect("flush");
            }
        });
        MockHttpServer {
            port,
            requests,
            handle,
        }
    }

    fn join(self) -> Vec<String> {
        self.handle.join().expect("server thread panicked");
        self.requests.lock().unwrap().clone()
    }
}

fn token_file(token: &str) -> PathBuf {
    let path = std::env::temp_dir().join(format!(
        "openvalut-cli-it-{}-{}.token",
        std::process::id(),
        token
    ));
    fs::write(&path, format!("{token}\n")).expect("write token file");
    path
}

fn run_cli_with_port(port: &str, token: &str, args: &[&str]) -> Output {
    let token_path = token_file(token);
    let output = Command::new(env!("CARGO_BIN_EXE_openvalut-cli"))
        .arg("--token")
        .arg(&token_path)
        .arg("--port")
        .arg(port)
        .args(args)
        .output()
        .expect("run cli");
    let _ = fs::remove_file(&token_path);
    output
}

fn run_cli(port: u16, token: &str, args: &[&str]) -> Output {
    run_cli_with_port(&port.to_string(), token, args)
}

fn stdout(output: &Output) -> String {
    String::from_utf8_lossy(&output.stdout).into_owned()
}

fn stderr(output: &Output) -> String {
    String::from_utf8_lossy(&output.stderr).into_owned()
}

#[test]
fn list_filters_and_formats_rows() {
    let server = MockServer::spawn(
        r#"{"id":1,"ok":true,"data":{"entries":[{"uuid":"1","label":"GitHub","username":"alice","group":"Dev","file":"vault.kdbx"},{"uuid":"2","label":"Mail","username":"bob","group":"Mail","file":"vault.kdbx"}]}}"#,
    );
    let output = run_cli(server.port, "tok-list", &["list", "github"]);
    let request = server.join();

    assert!(output.status.success());
    assert_eq!(stdout(&output), "GitHub\talice\tDev\tvault.kdbx\n");
    assert!(request.contains("\"method\":\"list\""));
    assert!(request.contains("\"query\":\"github\""));
    assert!(request.contains("\"token\":\"tok-list\""));
}

#[test]
fn list_without_query_prints_all_rows() {
    let server = MockServer::spawn(
        r#"{"id":1,"ok":true,"data":{"entries":[{"uuid":"1","label":"GitHub","username":"alice","group":"Dev","file":"vault.kdbx"},{"uuid":"2","label":"Mail","username":"bob","group":"Mail","file":"vault.kdbx"}]}}"#,
    );
    let output = run_cli(server.port, "tok-list-all", &["list"]);
    server.join();

    assert!(output.status.success());
    assert_eq!(
        stdout(&output),
        "GitHub\talice\tDev\tvault.kdbx\nMail\tbob\tMail\tvault.kdbx\n"
    );
}

#[test]
fn read_command_is_removed() {
    // `read` used to print the secret / OTP to the terminal; it must now be
    // rejected without contacting the credential server.
    let output = run_cli(
        1,
        "tok-read-removed",
        &["read", "op://Personal/GitHub/password"],
    );
    assert_eq!(output.status.code(), Some(2));
    assert!(stderr(&output).contains("已移除"));
}

#[test]
fn get_returns_metadata_only() {
    let server = MockServer::spawn(r#"{"id":1,"ok":true,"data":"GitHub"}"#);
    let output = run_cli(
        server.port,
        "tok-get-label",
        &["get", "github", "--field", "label"],
    );
    let request = server.join();

    assert!(output.status.success());
    assert_eq!(stdout(&output), "GitHub\n");
    assert!(request.contains("\"field\":\"label\""));
}

#[test]
fn get_password_field_is_rejected() {
    let server = MockServer::spawn(
        r#"{"id":1,"ok":false,"error":"get only returns non-sensitive metadata; use resolve with a Secret Reference for password"}"#,
    );
    let output = run_cli(
        server.port,
        "tok-get-password",
        &["get", "github", "--field", "password"],
    );
    server.join();

    assert_eq!(output.status.code(), Some(1));
    assert!(stderr(&output).contains("use resolve"));
}

#[test]
fn totp_command_is_removed() {
    let output = run_cli(1, "tok-totp-removed", &["totp", "github"]);

    assert_eq!(output.status.code(), Some(2));
    assert!(stderr(&output).contains("已移除"));
}

#[test]
fn run_requires_command() {
    let output = run_cli(
        1,
        "tok-run-no-cmd",
        &["run", "--env", "PASS=op://Personal/GitHub/password"],
    );

    assert_eq!(output.status.code(), Some(2));
    assert!(stderr(&output).contains("run"));
}

#[test]
fn run_injects_resolved_secret_into_subprocess() {
    let server = MockServer::spawn(r#"{"id":1,"ok":true,"data":"s3cret"}"#);
    let output = run_cli(
        server.port,
        "tok-run",
        &[
            "run",
            "--env",
            "PASS=op://Personal/GitHub/password",
            "--",
            "sh",
            "-c",
            "test -n \"$PASS\" && echo injected",
        ],
    );
    let request = server.join();

    assert!(output.status.success(), "{}", stderr(&output));
    assert_eq!(stdout(&output), "injected\n");
    assert!(request.contains("\"method\":\"resolve\""));
    assert!(request.contains("\"reference\":\"op://Personal/GitHub/password\""));
}

#[test]
fn run_rejects_printenv_dump_of_secret() {
    // `printenv PASS` would print the resolved secret; it must be rejected
    // before the credential server is even contacted.
    let output = run_cli(
        1,
        "tok-run-printenv",
        &[
            "run",
            "--env",
            "PASS=op://Personal/GitHub/password",
            "--",
            "printenv",
            "PASS",
        ],
    );
    assert_eq!(output.status.code(), Some(2));
    assert!(stderr(&output).contains("拒绝"));
}

#[test]
fn run_rejects_shell_echo_of_injected_secret() {
    let output = run_cli(
        1,
        "tok-run-echo",
        &[
            "run",
            "--env",
            "PASS=op://Personal/GitHub/password",
            "--",
            "sh",
            "-c",
            "echo \"$PASS\"",
        ],
    );
    assert_eq!(output.status.code(), Some(2));
    assert!(stderr(&output).contains("拒绝"));
}

#[test]
fn run_allows_echo_that_does_not_mention_secret() {
    // `echo hello` prints nothing secret, so it stays allowed (output
    // forwarding is still a legitimate use of `run`).
    let server = MockServer::spawn(r#"{"id":1,"ok":true,"data":"s3cret"}"#);
    let output = run_cli(
        server.port,
        "tok-run-echo-hello",
        &[
            "run",
            "--env",
            "PASS=op://Personal/GitHub/password",
            "--",
            "echo",
            "hello",
        ],
    );
    server.join();
    assert!(output.status.success(), "{}", stderr(&output));
    assert_eq!(stdout(&output), "hello\n");
}

#[test]
fn run_silent_child_never_echoes_secret() {
    // The resolved secret travels server -> CLI -> child environment. The CLI
    // itself must print nothing to stdout/stderr while doing so.
    let server = MockServer::spawn(r#"{"id":1,"ok":true,"data":"s3cret-UNIQUE-9f3a"}"#);
    let output = run_cli(
        server.port,
        "tok-run-silent",
        &[
            "run",
            "--env",
            "PASS=op://Personal/GitHub/password",
            "--",
            "true",
        ],
    );
    server.join();

    assert!(output.status.success());
    assert_eq!(stdout(&output), "");
    assert_eq!(stderr(&output), "");
}

#[test]
fn run_secret_reaches_env_but_not_any_argv() {
    // The child greps its parent (the CLI) cmdline for the resolved secret:
    // the value must travel only through the environment, never argv.
    let secret = "s3cret-UNIQUE-9f3a";
    let server = MockServer::spawn(&format!(r#"{{"id":1,"ok":true,"data":"{secret}"}}"#));
    let script = "if grep -q \"$PASS\" /proc/$PPID/cmdline 2>/dev/null; then echo ARGV-LEAK; exit 1; else echo CLEAN; fi";
    let output = run_cli(
        server.port,
        "tok-run-argv",
        &[
            "run",
            "--env",
            "PASS=op://Personal/GitHub/password",
            "--",
            "sh",
            "-c",
            script,
        ],
    );
    server.join();

    assert!(output.status.success(), "{}", stderr(&output));
    assert_eq!(stdout(&output), "CLEAN\n");
    assert!(!stderr(&output).contains(secret));
}

#[test]
fn run_injects_multiple_references_without_leak() {
    let server = MockServerSeq::spawn(&[
        r#"{"id":1,"ok":true,"data":"first-secret"}"#,
        r#"{"id":1,"ok":true,"data":"second-secret"}"#,
    ]);
    let output = run_cli(
        server.port,
        "tok-run-multi",
        &[
            "run",
            "--env",
            "A=op://Personal/GitHub/password",
            "--env",
            "B=op://Personal/Mail/password",
            "--",
            "sh",
            "-c",
            "test -n \"$A\" && test -n \"$B\" && echo multi-ok",
        ],
    );
    let requests = server.join();

    assert!(output.status.success(), "{}", stderr(&output));
    assert_eq!(stdout(&output), "multi-ok\n");
    assert_eq!(requests.len(), 2);
    assert!(requests[0].contains("\"reference\":\"op://Personal/GitHub/password\""));
    assert!(requests[1].contains("\"reference\":\"op://Personal/Mail/password\""));
}

#[test]
fn run_partial_resolve_failure_does_not_leak_earlier_secret() {
    // A resolves fine, B fails: the CLI must report the failing reference and
    // must not print A's already-resolved secret anywhere.
    let secret = "s3cret-UNIQUE-9f3a";
    let server = MockServerSeq::spawn(&[
        &format!(r#"{{"id":1,"ok":true,"data":"{secret}"}}"#),
        r#"{"id":1,"ok":false,"error":"no matching entry"}"#,
    ]);
    let output = run_cli(
        server.port,
        "tok-run-partial",
        &[
            "run",
            "--env",
            "A=op://Personal/GitHub/password",
            "--env",
            "B=op://Personal/Mail/password",
            "--",
            "true",
        ],
    );
    server.join();

    assert_eq!(output.status.code(), Some(1));
    assert!(stderr(&output).contains("op://Personal/Mail/password"));
    assert!(!stdout(&output).contains(secret));
    assert!(!stderr(&output).contains(secret));
}

#[test]
fn run_propagates_child_exit_code_without_echoing_secret() {
    let secret = "s3cret-UNIQUE-9f3a";
    let server = MockServer::spawn(&format!(r#"{{"id":1,"ok":true,"data":"{secret}"}}"#));
    let output = run_cli(
        server.port,
        "tok-run-exit",
        &[
            "run",
            "--env",
            "PASS=op://Personal/GitHub/password",
            "--",
            "sh",
            "-c",
            "exit 7",
        ],
    );
    server.join();

    assert_eq!(output.status.code(), Some(7));
    assert!(!stdout(&output).contains(secret));
    assert!(!stderr(&output).contains(secret));
}

#[test]
fn run_forwards_child_output_without_mixing_in_secret() {
    // Child output that is not the secret is passed through untouched; the CLI
    // must not dump the resolved environment alongside it.
    let secret = "s3cret-UNIQUE-9f3a";
    let server = MockServer::spawn(&format!(r#"{{"id":1,"ok":true,"data":"{secret}"}}"#));
    let output = run_cli(
        server.port,
        "tok-run-out",
        &[
            "run",
            "--env",
            "PASS=op://Personal/GitHub/password",
            "--",
            "echo",
            "hello",
        ],
    );
    server.join();

    assert!(output.status.success());
    assert_eq!(stdout(&output), "hello\n");
    assert!(!stdout(&output).contains(secret));
}

#[test]
fn export_and_sudo_commands_are_removed() {
    let export = run_cli(1, "tok-export-removed", &["export"]);
    assert_eq!(export.status.code(), Some(2));
    assert!(stderr(&export).contains("已移除"));

    let sudo = run_cli(1, "tok-sudo-removed", &["sudo"]);
    assert_eq!(sudo.status.code(), Some(2));
    assert!(stderr(&sudo).contains("已移除"));
}

#[test]
fn server_error_is_reported_with_exit_code_1() {
    let server = MockServer::spawn(r#"{"id":1,"ok":false,"error":"no matching entry"}"#);
    let output = run_cli(server.port, "tok-err", &["get", "nope"]);
    server.join();

    assert_eq!(output.status.code(), Some(1));
    assert_eq!(stderr(&output), "error: no matching entry\n");
    assert!(stdout(&output).is_empty());
}

#[test]
fn missing_token_file_reports_server_not_running() {
    let missing = std::env::temp_dir().join(format!(
        "openvalut-cli-it-{}-missing.token",
        std::process::id()
    ));
    let fake_home = std::env::temp_dir().join(format!(
        "openvalut-cli-it-{}-empty-home",
        std::process::id()
    ));
    fs::create_dir_all(&fake_home).expect("mkdir fake home");
    let output = Command::new(env!("CARGO_BIN_EXE_openvalut-cli"))
        .arg("--token")
        .arg(&missing)
        .arg("--port")
        .arg("1")
        .arg("list")
        .env("HOME", &fake_home)
        .env("XDG_CONFIG_HOME", fake_home.join(".config"))
        .output()
        .expect("run cli");
    let _ = fs::remove_dir_all(&fake_home);

    assert_eq!(output.status.code(), Some(1));
    assert!(stderr(&output).contains("OpenValut credential server is not running"));
}

#[test]
fn corrupt_port_is_reported() {
    let output = run_cli_with_port("abc", "tok-corrupt-port", &["list"]);
    assert_eq!(output.status.code(), Some(1));
    assert_eq!(stderr(&output), "error: corrupt port file abc\n");
}

#[test]
fn connection_refused_is_reported() {
    let listener = TcpListener::bind("127.0.0.1:0").unwrap();
    let port = listener.local_addr().unwrap().port();
    drop(listener);

    let output = run_cli(port, "tok-refused", &["list"]);
    assert_eq!(output.status.code(), Some(1));
    assert!(stderr(&output).starts_with("error:"));
}

#[test]
fn help_prints_usage_without_connecting() {
    let output = Command::new(env!("CARGO_BIN_EXE_openvalut-cli"))
        .arg("--help")
        .output()
        .expect("run cli");
    assert_eq!(output.status.code(), Some(0));
    let text = stdout(&output);
    assert!(text.contains("openvalut-cli — read and manage OpenValut credentials"));
    assert!(text.contains("Usage:"));
}

#[test]
fn unknown_flag_and_unknown_command_exit_2() {
    let output = run_cli(1, "tok-bad-flag", &["--nope"]);
    assert_eq!(output.status.code(), Some(2));
    assert!(stdout(&output).contains("Usage:"));

    let output = run_cli(1, "tok-bad-cmd", &["frobnicate"]);
    assert_eq!(output.status.code(), Some(2));
    assert!(stdout(&output).contains("Usage:"));
}

#[test]
fn bare_cloud_without_command_errors_before_prompting_for_password() {
    // A bare `--cloud` must fail fast with a clear message: it should not
    // prompt for the master password (which would block the test) nor dump the
    // full usage/help before reporting what is missing.
    let output = Command::new(env!("CARGO_BIN_EXE_openvalut-cli"))
        .arg("--cloud")
        .output()
        .expect("run cli");

    assert_eq!(output.status.code(), Some(2));
    assert!(stderr(&output).contains("未指定命令"));
    assert!(stdout(&output).is_empty());
}

/// Runs the standalone binary with an isolated HOME/XDG config dir so auth
/// state (or its absence) never touches the real user config.
fn run_isolated(args: &[&str]) -> (Output, std::path::PathBuf) {
    let dir = std::env::temp_dir().join(format!(
        "openvalut-cli-auth-it-{}-{}",
        std::process::id(),
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_nanos()
    ));
    fs::create_dir_all(dir.join(".config")).expect("mkdir");
    let output = Command::new(env!("CARGO_BIN_EXE_openvalut-cli"))
        .env("HOME", &dir)
        .env("XDG_CONFIG_HOME", dir.join(".config"))
        // Isolate the keychain too: the real Secret Service may hold a stale
        // Secret Key (which would fail assertions and be deleted by logout).
        .env("OPENVALUT_TEST_KEYCHAIN_DIR", dir.join("keychain"))
        .args(args)
        .output()
        .expect("run cli");
    (output, dir)
}

#[test]
fn auth_status_without_account_exits_1() {
    let (output, dir) = run_isolated(&["auth", "status"]);
    let _ = fs::remove_dir_all(&dir);
    assert_eq!(output.status.code(), Some(1));
    assert!(stderr(&output).contains("auth login"));
}

#[test]
fn auth_logout_without_account_exits_1() {
    let (output, dir) = run_isolated(&["auth", "logout"]);
    let _ = fs::remove_dir_all(&dir);
    assert_eq!(output.status.code(), Some(1));
    assert!(stderr(&output).contains("没有已保存的云账号"));
}

#[test]
fn auth_unknown_subcommand_exits_2() {
    let (output, dir) = run_isolated(&["auth", "bogus"]);
    let _ = fs::remove_dir_all(&dir);
    assert_eq!(output.status.code(), Some(2));
    assert!(stderr(&output).contains("login / status / logout"));
}

#[test]
fn auth_login_scan_stores_account_without_echoing_secret() {
    // The 32-char account UUID doubles as the Secret Key; the QR flow must
    // persist it but never print it.
    const SECRET: &str = "0123456789abcdef0123456789abcdef";
    let server = MockHttpServer::spawn(vec![
        (
            201,
            r#"{"sessionId":"sess-1","qrContent":"openvalut://scan-login/sess-1","sessionSecret":"aabbcc"}"#
                .to_string(),
        ),
        (
            200,
            format!(
                r#"{{"status":"confirmed","token":"tok-1","username":"scan@example.com","userId":"{SECRET}"}}"#
            ),
        ),
    ]);
    let server_url = format!("http://127.0.0.1:{}", server.port);

    let (output, dir) = run_isolated(&["auth", "login", "--scan", "--server", &server_url]);
    let requests = server.join();

    let code = output.status.code();
    let out = stdout(&output);
    let err = stderr(&output);
    let stored =
        fs::read_to_string(dir.join("keychain/cloud-secret-key.secret")).unwrap_or_default();
    let account = fs::read_to_string(dir.join(".config/openvalut/data/cloud-account.json"))
        .unwrap_or_default();
    let _ = fs::remove_dir_all(&dir);

    assert_eq!(code, Some(0), "stdout={out}\nstderr={err}");
    assert!(out.contains("已登录"), "stdout={out}");
    // The Secret Key must never appear on either stream.
    assert!(
        !out.contains(SECRET) && !err.contains(SECRET),
        "secret leaked: stdout={out} stderr={err}"
    );
    // ... but it is stored, together with the account email.
    assert_eq!(stored, SECRET);
    assert!(account.contains("scan@example.com"), "account={account}");
    // One create call, then one poll carrying the one-time secret.
    assert_eq!(requests.len(), 2);
    assert!(
        requests[0].starts_with("POST /api/login/scan"),
        "{}",
        requests[0]
    );
    assert!(
        requests[1].starts_with("GET /api/login/scan/sess-1"),
        "{}",
        requests[1]
    );
    assert!(requests[1].to_lowercase().contains("x-scan-secret"));
}

#[test]
fn unlock_scan_reports_missing_relayed_password() {
    // A confirmed session without a relayed master password (phone had no open
    // vault) must fail clearly instead of storing an empty password.
    let server = MockHttpServer::spawn(vec![
        (
            201,
            r#"{"sessionId":"sess-2","qrContent":"openvalut://scan-login/sess-2","sessionSecret":"ddee"}"#
                .to_string(),
        ),
        (
            200,
            r#"{"status":"confirmed","token":"tok-2","username":"scan@example.com","userId":"0123456789abcdef0123456789abcdef"}"#
                .to_string(),
        ),
    ]);
    let server_url = format!("http://127.0.0.1:{}", server.port);

    let (output, dir) = run_isolated(&["unlock", "--scan", "--server", &server_url]);
    let _ = server.join();
    let code = output.status.code();
    let err = stderr(&output);
    let stored =
        fs::read_to_string(dir.join("keychain/master-password.secret")).unwrap_or_default();
    let _ = fs::remove_dir_all(&dir);

    assert_eq!(code, Some(1), "stderr={err}");
    assert!(err.contains("未回传主密码"), "stderr={err}");
    assert!(stored.is_empty(), "no password should be stored");
}

#[test]
fn cloud_without_credentials_hints_auth_login() {
    // `--cloud list` without --email/--secret-key and no saved account must
    // point the user at `auth login` rather than confusingly asking for the
    // master password once and then failing on a missing Secret Key.
    let (output, dir) = run_isolated(&["--cloud", "--password", "x", "list"]);
    let _ = fs::remove_dir_all(&dir);
    assert_eq!(output.status.code(), Some(1));
    assert!(stderr(&output).contains("auth login"));
}

#[test]
fn standalone_local_crud_round_trip() {
    let dir = std::env::temp_dir().join(format!(
        "openvalut-cli-it-{}-standalone",
        std::process::id()
    ));
    fs::create_dir_all(&dir).expect("mkdir");
    let db_path = dir.join("vault.kdbx");

    fn run(db_path: &PathBuf, args: &[&str]) -> Output {
        let mut cmd = Command::new(env!("CARGO_BIN_EXE_openvalut-cli"));
        // Isolate HOME/XDG (and the test keychain) so this test never touches
        // the real user config — opening a vault with --db remembers it in
        // cli-default.json, which used to clobber the developer's own vault.
        if let Some(dir) = db_path.parent() {
            cmd.env("HOME", dir)
                .env("XDG_CONFIG_HOME", dir.join(".config"))
                .env("OPENVALUT_TEST_KEYCHAIN_DIR", dir.join("keychain"));
        }
        cmd.arg("--db")
            .arg(db_path)
            .arg("--password")
            .arg("testpass");
        cmd.args(args);
        cmd.output().expect("run cli")
    }

    // Create a vault.
    let out = run(&db_path, &["vault", "create", "TestVault"]);
    assert!(out.status.success(), "{}", stderr(&out));
    assert!(stdout(&out).starts_with("created vault TestVault"));

    // Add and list an item.
    let out = run(
        &db_path,
        &[
            "item",
            "add",
            "GitHub",
            "--username",
            "alice",
            "--password-field",
            "s3cret",
        ],
    );
    assert!(out.status.success(), "{}", stderr(&out));
    let out = run(&db_path, &["item", "allow", "GitHub"]);
    assert!(out.status.success(), "{}", stderr(&out));
    let out = run(&db_path, &["list"]);
    assert_eq!(stdout(&out), "GitHub\talice\t\tTestVault\n");

    // A standalone `get` no longer prints the secret; it reports removal.
    let out = run(&db_path, &["get", "GitHub"]);
    assert_eq!(out.status.code(), Some(2));
    assert!(stderr(&out).contains("已移除"));

    // Edit and delete.
    let out = run(
        &db_path,
        &["item", "edit", "GitHub", "--password-field", "newpass"],
    );
    assert!(out.status.success(), "{}", stderr(&out));
    let out = run(&db_path, &["item", "delete", "GitHub"]);
    assert!(out.status.success(), "{}", stderr(&out));
    let out = run(&db_path, &["list"]);
    assert_eq!(stdout(&out), "");

    let _ = fs::remove_dir_all(&dir);
}
