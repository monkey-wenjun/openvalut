//! User-presence check that guards the remembered unlock key.
//!
//! The gate is fail-closed: unless the platform explicitly confirms the user,
//! the caller must fall back to a typed master password.

pub fn verify(language: &str) -> Result<(), String> {
    let prompt = if language.starts_with("zh") {
        "验证身份以解锁 OpenValut"
    } else {
        "Verify your identity to unlock OpenValut"
    };
    verify_with_prompt(prompt)
}

#[cfg(target_os = "windows")]
fn verify_with_prompt(prompt: &str) -> Result<(), String> {
    use std::sync::mpsc;
    use std::thread;
    use std::time::Duration;

    // WinRT hands the completion to an RPC thread-pool worker, so the waiting
    // thread must be MTA; an STA thread that blocks without pumping messages
    // deadlocks a marshalled callback. A dedicated thread also keeps this off
    // the tokio workers, which may already hold a COM apartment.
    let request = prompt.to_string();
    let (sender, receiver) = mpsc::channel();
    thread::spawn(move || {
        let _ = sender.send(blocking_verify(&request));
    });
    // The margin lets the worker's own deadline fire first, so the thread ends
    // by cancelling rather than by being abandoned mid-WinRT-call.
    match receiver.recv_timeout(Duration::from_secs(VERIFY_SECONDS + 5)) {
        Ok(result) => result,
        Err(_) => Err("Windows Hello 验证超时，请输入主密码".to_string()),
    }
}

#[cfg(target_os = "windows")]
const VERIFY_SECONDS: u64 = 180;

#[cfg(target_os = "windows")]
fn blocking_verify(prompt: &str) -> Result<(), String> {
    use std::thread;
    use std::time::{Duration, Instant};

    use windows::core::HSTRING;
    use windows::Security::Credentials::UI::{UserConsentVerificationResult, UserConsentVerifier};
    use windows::Win32::System::Com::{CoInitializeEx, CoUninitialize, COINIT_MULTITHREADED};
    use windows_future::AsyncStatus;

    struct ComGuard;
    impl Drop for ComGuard {
        fn drop(&mut self) {
            unsafe { CoUninitialize() };
        }
    }

    // S_FALSE (already initialized on this thread) is a success-severity code.
    if unsafe { CoInitializeEx(None, COINIT_MULTITHREADED) }.is_err() {
        return Err("无法初始化 COM，请输入主密码".to_string());
    }
    let _com = ComGuard;

    // No CheckAvailabilityAsync pre-flight: on PIN-only machines it reports
    // DeviceNotPresent and the prompt would be skipped entirely.
    let operation = UserConsentVerifier::RequestVerificationAsync(&HSTRING::from(prompt))
        .map_err(|e| format!("无法发起 Windows Hello 验证: {e}"))?;

    // The blocking helper in windows-future sits behind a private trait, so
    // wait the way WinRT callers do: poll the status, then read the result.
    let deadline = Instant::now() + Duration::from_secs(VERIFY_SECONDS);
    loop {
        let status = operation.Status().map_err(|e| format!("Windows Hello 验证失败: {e}"))?;
        if status == AsyncStatus::Completed {
            break;
        }
        if status == AsyncStatus::Canceled {
            return Err("Windows Hello 验证已取消，请输入主密码".to_string());
        }
        if status == AsyncStatus::Error {
            return Err("Windows Hello 验证出错，请输入主密码".to_string());
        }
        if Instant::now() >= deadline {
            let _ = operation.Cancel();
            return Err("Windows Hello 验证超时，请输入主密码".to_string());
        }
        thread::sleep(Duration::from_millis(50));
    }

    let result = operation
        .GetResults()
        .map_err(|e| format!("Windows Hello 验证失败: {e}"))?;
    if result == UserConsentVerificationResult::Verified {
        Ok(())
    } else {
        let why = name(result);
        match hint(result) {
            Some(hint) => Err(format!("Windows Hello 未通过（{why}），{hint}")),
            None => Err(format!("Windows Hello 未通过（{why}），请输入主密码")),
        }
    }
}

/// The two results that mean “this machine cannot do Hello yet” are the ones the
/// user can actually fix, so say where: a machine with no fingerprint/face
/// reader still gets a Hello prompt once a PIN exists, and has none until then.
#[cfg(target_os = "windows")]
fn hint(
    result: windows::Security::Credentials::UI::UserConsentVerificationResult,
) -> Option<&'static str> {
    use windows::Security::Credentials::UI::UserConsentVerificationResult as R;
    if result == R::NotConfiguredForUser || result == R::DeviceNotPresent {
        Some("请先在 Windows 设置 > 账户 > 登录选项 里添加 PIN；本次请输入主密码")
    } else {
        None
    }
}

/// The WinRT enum has no `Display`, and the number alone means nothing in a log.
#[cfg(target_os = "windows")]
fn name(result: windows::Security::Credentials::UI::UserConsentVerificationResult) -> &'static str {
    use windows::Security::Credentials::UI::UserConsentVerificationResult as R;
    if result == R::Verified {
        "已验证"
    } else if result == R::DeviceNotPresent {
        "没有可用的 Hello 设备"
    } else if result == R::NotConfiguredForUser {
        "该用户未配置 Hello"
    } else if result == R::DisabledByPolicy {
        "组策略已禁用 Hello"
    } else if result == R::DeviceBusy {
        "设备繁忙"
    } else if result == R::RetriesExhausted {
        "重试次数用尽"
    } else if result == R::Canceled {
        "已取消"
    } else {
        "未知结果"
    }
}

#[cfg(target_os = "linux")]
fn verify_with_prompt(_prompt: &str) -> Result<(), String> {
    use std::process::{Command, Stdio};
    use std::time::{Duration, Instant};

    // Polkit waits for an agent that may never answer, so the child is reaped
    // against a deadline instead of with status(): a blocking status() here
    // freezes the unlock button for as long as the dialog stays unanswered.
    let child = Command::new("pkexec")
        .arg("/usr/bin/true")
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()
        .map_err(|e| format!("无法启动 pkexec: {e}"))?;
    reap(child, Instant::now() + Duration::from_secs(180))
}

/// Wait for the presence helper and treat anything short of an explicit success
/// as a refusal. Split out from the spawn so the deadline and the fail-closed
/// mapping can be exercised without asking polkit to put a dialog on screen.
#[cfg(target_os = "linux")]
fn reap(mut child: std::process::Child, deadline: std::time::Instant) -> Result<(), String> {
    use std::thread;
    loop {
        let status = child
            .try_wait()
            .map_err(|e| format!("无法等待 pkexec: {e}"))?;
        match status {
            Some(status) if status.success() => return Ok(()),
            Some(_) => return Err("身份验证未通过，请输入主密码".to_string()),
            None => {
                if std::time::Instant::now() >= deadline {
                    let _ = child.kill();
                    let _ = child.wait();
                    return Err("身份验证超时，请输入主密码".to_string());
                }
                thread::sleep(std::time::Duration::from_millis(200));
            }
        }
    }
}

#[cfg(not(any(target_os = "windows", target_os = "linux")))]
fn verify_with_prompt(_prompt: &str) -> Result<(), String> {
    Err("该平台没有用户在场校验，请输入主密码".to_string())
}

/// The gate is the only thing between the keychain and whoever is sitting at the
/// machine, so every answer except an explicit success has to refuse — and
/// refusing has to say "type the master password" rather than hang. These drive
/// real short-lived processes instead of pkexec, so no polkit dialog appears.
#[cfg(all(test, target_os = "linux"))]
mod presence_tests {
    use super::reap;
    use std::process::{Command, Stdio};
    use std::time::{Duration, Instant};

    fn sh(script: &str) -> std::process::Child {
        Command::new("sh")
            .arg("-c")
            .arg(script)
            .stdin(Stdio::null())
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .spawn()
            .expect("failed to spawn the helper process")
    }

    #[test]
    fn only_an_explicit_success_grants_presence() {
        let soon = Instant::now() + Duration::from_secs(5);
        assert!(reap(sh("exit 0"), soon).is_ok());
        assert!(reap(sh("exit 1"), soon).is_err());
        // Killed by a signal is not a confirmation either.
        assert!(reap(sh("kill -9 $$"), soon).is_err());
    }

    #[test]
    fn an_unanswered_prompt_refuses_on_the_deadline_and_reaps_the_child() {
        let started = Instant::now();
        let error = reap(sh("sleep 30"), started + Duration::from_millis(100))
            .expect_err("a helper that never answers must not grant access");
        assert!(error.contains("主密码"), "refusal should fall back to a typed password, got: {error}");
        assert!(
            started.elapsed() < Duration::from_secs(10),
            "the deadline has to cut the wait off, not the helper exiting on its own"
        );
    }

    #[test]
    fn a_helper_that_dies_before_the_deadline_is_not_a_timeout() {
        // Distinct from the timeout path: the refusal here comes from the exit
        // status, so the message must not claim the user simply never answered.
        let error = reap(sh("exit 127"), Instant::now() + Duration::from_secs(5))
            .expect_err("a failing helper is not a confirmation");
        assert!(!error.contains("超时"), "got: {error}");
    }
}
