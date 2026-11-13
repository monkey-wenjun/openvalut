//! Identity of the current boot / logon session.
//!
//! Remembered unlock credentials are tagged with this id so the master password
//! is only skipped while the machine keeps running: after a reboot (or a logoff)
//! the tag no longer matches and the master password has to be typed again.
//! Mirrors `currentBootId()` in the Flutter app
//! (openvalut/lib/utils/system_auth_io.dart), with the Windows logon session
//! added because Fast Startup can preserve the boot counters.

use std::sync::OnceLock;

static BOOT_ID: OnceLock<Option<String>> = OnceLock::new();

/// Stable identifier for the session this process runs in, or `None` when the
/// platform exposes nothing usable.
///
/// Cached: it cannot change while the process is alive, and every caller would
/// otherwise hit the filesystem / registry / a child process again.
pub fn current_boot_id() -> Option<&'static str> {
    BOOT_ID.get_or_init(read_boot_id).as_deref()
}

#[cfg(target_os = "linux")]
fn read_boot_id() -> Option<String> {
    let raw = std::fs::read_to_string("/proc/sys/kernel/random/boot_id").ok()?;
    let id = raw.trim();
    if id.is_empty() {
        None
    } else {
        Some(format!("linux-{id}"))
    }
}

#[cfg(target_os = "macos")]
fn read_boot_id() -> Option<String> {
    let out = std::process::Command::new("sysctl")
        .args(["-n", "kern.boottime"])
        .output()
        .ok()?;
    if !out.status.success() {
        return None;
    }
    let text = String::from_utf8_lossy(&out.stdout);
    let sec = text.split("sec =").nth(1)?.split(',').next()?.trim();
    if sec.is_empty() {
        None
    } else {
        Some(format!("mac-{sec}"))
    }
}

/// The logon session comes first because it is the only marker that changes
/// when the user really means "shut down".
///
/// Windows Fast Startup (hiberboot) makes a shutdown a hibernate/resume of the
/// kernel, so boot counters and boot times can survive it - a PIN would then
/// keep working across the very reboot this feature exists to catch. Logging on
/// always allocates a fresh LUID, so it changes on both a warm and a fast
/// startup, and stays put for as long as the user is logged in.
#[cfg(windows)]
fn read_boot_id() -> Option<String> {
    logon_session_id()
        .or_else(prefetch_boot_id)
        .or_else(last_boot_time)
        .or_else(tick_boot_id)
}

/// `AuthenticationId` of this process's logon session. Unique per logon, and it
/// also rotates when the user logs off and back on - stricter than a reboot
/// check, never looser.
#[cfg(windows)]
fn logon_session_id() -> Option<String> {
    use windows::Win32::Foundation::{CloseHandle, HANDLE};
    use windows::Win32::Security::{
        GetTokenInformation, TokenStatistics, TOKEN_QUERY, TOKEN_STATISTICS,
    };
    use windows::Win32::System::Threading::{GetCurrentProcess, OpenProcessToken};

    // SAFETY: the handle is owned here and closed on every path; the buffer is
    // `TOKEN_STATISTICS` and the length passed matches its size.
    unsafe {
        let mut handle = HANDLE::default();
        OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &mut handle).ok()?;
        let mut stats = TOKEN_STATISTICS::default();
        let mut written = 0u32;
        let read = GetTokenInformation(
            handle,
            TokenStatistics,
            Some(&mut stats as *mut TOKEN_STATISTICS as *mut core::ffi::c_void),
            std::mem::size_of::<TOKEN_STATISTICS>() as u32,
            &mut written,
        );
        let _ = CloseHandle(handle);
        read.ok()?;
        let luid = stats.AuthenticationId;
        Some(format!(
            "win-logon-{:08x}{:08x}",
            luid.HighPart as u32, luid.LowPart
        ))
    }
}

/// The prefetcher's `BootId` is a counter Windows bumps on every boot. Systems
/// with prefetch disabled may not have it, hence the chain above.
#[cfg(windows)]
fn prefetch_boot_id() -> Option<String> {
    const PREFETCH: &str =
        r"SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters";
    if let Ok(id) = windows_registry::LOCAL_MACHINE
        .open(PREFETCH)
        .and_then(|key| key.get_u32("BootId"))
    {
        return Some(format!("win-reg-{id}"));
    }
    None
}

/// `LastBootUpTime` from WMI, the same source the Flutter client uses. Reported
/// as 100ns intervals since 1601 so the value does not depend on how the text
/// is formatted.
#[cfg(windows)]
fn last_boot_time() -> Option<String> {
    use std::os::windows::process::CommandExt;
    /// Do not flash a console window for a query that runs once per process.
    const CREATE_NO_WINDOW: u32 = 0x0800_0000;

    let out = std::process::Command::new("powershell")
        .args([
            "-NoProfile",
            "-NonInteractive",
            "-Command",
            "(Get-CimInstance Win32_OperatingSystem).LastBootUpTime.ToFileTimeUtc()",
        ])
        .creation_flags(CREATE_NO_WINDOW)
        .output()
        .ok()?;
    if !out.status.success() {
        return None;
    }
    let text = String::from_utf8_lossy(&out.stdout);
    let value = text.trim();
    if value.is_empty() || !value.chars().all(|c| c.is_ascii_digit()) {
        return None;
    }
    Some(format!("win-boot-{value}"))
}

/// Wall-clock instant of this boot, derived from the time since boot.
///
/// Bucketed to ten minutes so ordinary NTP corrections do not move the value,
/// and compared exactly. A machine that corrects its clock by more than that
/// mid-session asks for the master password again - fail closed, never open.
/// The registry value above is present on every supported Windows, so this is
/// the last resort.
#[cfg(windows)]
fn tick_boot_id() -> Option<String> {
    use windows::Win32::System::SystemInformation::GetTickCount64;

    // SAFETY: reads a monotonically increasing counter; no pointers involved.
    let tick = unsafe { GetTickCount64() };
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .ok()?
        .as_millis() as u64;
    let boot = now.checked_sub(tick)?;
    Some(format!("win-tick-{}", boot / 600_000))
}

#[cfg(not(any(target_os = "linux", target_os = "macos", windows)))]
fn read_boot_id() -> Option<String> {
    None
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_boot_id_is_stable_within_the_process() {
        assert_eq!(current_boot_id(), current_boot_id());
    }

    #[cfg(target_os = "linux")]
    #[test]
    fn linux_reports_the_kernel_boot_id() {
        let expected = std::fs::read_to_string("/proc/sys/kernel/random/boot_id")
            .unwrap()
            .trim()
            .to_owned();
        assert_eq!(
            current_boot_id(),
            Some(format!("linux-{expected}").as_str())
        );
    }
}
