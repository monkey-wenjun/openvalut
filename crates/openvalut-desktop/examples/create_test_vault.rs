//! Create a throwaway vault for end-to-end verification: `cargo run -p
//! openvalut-desktop --example create_test_vault -- <path> <password>`,
//! then point openvalut-cli at the same file to confirm both clients read
//! the same data.

use openvalut_core::{CreateEntryRequest, Vault, VaultKey};

fn main() {
    let mut args = std::env::args().skip(1);
    let path = args.next().unwrap_or_else(|| "/tmp/openvalut-e2e.kdbx".into());
    let password = args.next().unwrap_or_else(|| "test-master-pw".into());

    let mut vault = Vault::create_new("E2E 测试库").expect("create");
    let examples = [
        CreateEntryRequest {
            title: "GitHub".into(),
            username: "octocat".into(),
            password: "correct horse battery staple".into(),
            url: "https://github.com".into(),
            notes: "工作账号".into(),
            group: Some("工作/开发".into()),
            otp: Some("otpauth://totp/GitHub:octocat?secret=JBSWY3DPEHPK3PXP&issuer=GitHub".into()),
            ssh_private_key: None,
            machine_id: None,
            custom: vec![
                ("access-key".into(), "AKIATEST".into()),
                ("openvalut.read-allowed".into(), "1".into()),
            ],
        },
        CreateEntryRequest {
            title: "家庭路由器".into(),
            username: "admin".into(),
            password: "router-pw-123".into(),
            url: "http://192.0.2.1".into(),
            notes: String::new(),
            group: Some("家庭".into()),
            otp: None,
            ssh_private_key: None,
            machine_id: None,
            custom: vec![],
        },
    ];
    for request in &examples {
        vault.add_entry(request).expect("add entry");
    }

    let key = VaultKey::with_password(&password);
    let bytes = vault.save(&key).expect("save");
    std::fs::write(&path, bytes).expect("write file");
    println!("wrote {path} ({} entries)", vault.entries().len());
}
