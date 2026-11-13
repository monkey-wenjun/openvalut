//! 自动化往返测试：临时测试密码库 创建 → 保存 → 解锁 → 查询 → TOTP。
//! 约定：不使用任何真实密码库 / 真实主密码；这里只有测试专用密码。

use openvalut_core::kdbx::{CreateEntryRequest, Vault, VaultKey};
use openvalut_core::totp::{generate_totp, parse_otp_auth};

fn test_password() -> &'static str {
    "openvalut-ui-test-only-2026"
}

#[test]
fn create_save_open_query_roundtrip() {
    let dir = std::env::temp_dir().join("openvalut-ui-test-roundtrip");
    let _ = std::fs::remove_dir_all(&dir);
    std::fs::create_dir_all(&dir).unwrap();
    let path = dir.join("test.kdbx");
    let key = VaultKey::with_password(test_password());

    let mut vault = Vault::create_new("测试库").unwrap();
    let uuid = vault
        .add_entry(&CreateEntryRequest {
            title: "示例网站".into(),
            username: "demo@example.com".into(),
            password: "entry-secret-for-test".into(),
            url: "https://example.com".into(),
            notes: "自动化测试条目".into(),
            otp: Some("otpauth://totp/Example:demo?secret=JBSWY3DPEHPK3PXP&issuer=Example".into()),
            ssh_private_key: None,
            machine_id: None,
            group: Some("网络/测试".into()),
            custom: Vec::new(),
        })
        .unwrap();
    let bytes = vault.save(&key).unwrap();
    std::fs::write(&path, &bytes).unwrap();

    // 重新从磁盘打开并校验字段。
    let reopened = Vault::open(&std::fs::read(&path).unwrap(), &key).unwrap();
    let entries = reopened.entries();
    assert_eq!(entries.len(), 1);
    let entry = &entries[0];
    assert_eq!(entry.uuid, uuid);
    assert_eq!(entry.title, "示例网站");
    assert_eq!(entry.username, "demo@example.com");
    assert_eq!(entry.group, "网络/测试");

    // TOTP 解析与生成（30 秒周期内能产出 6 位数字即可）。
    let otp = entry
        .custom
        .iter()
        .find(|(k, _)| k == "OTPAuth")
        .map(|(_, v)| v.as_str())
        .expect("OTP field should exist");
    let auth = parse_otp_auth(otp).unwrap();
    let (code, remaining, period) = generate_totp(&auth, None).unwrap();
    assert_eq!(code.len(), 6);
    assert!(code.bytes().all(|b| b.is_ascii_digit()));
    assert!(remaining <= period);

    let _ = std::fs::remove_dir_all(&dir);
}
