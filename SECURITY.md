# Security Policy

## Reporting

Do not publish suspected credential disclosure issues in a public issue. Report
them privately to the repository maintainers with affected versions,
reproduction steps, and impact.

## Dependency Exceptions

`cargo audit` runs in CI and must exit successfully. Exceptions are recorded in
`.cargo/audit.toml` with an explanation; every other RustSec vulnerability is
release-blocking.

### RUSTSEC-2026-0459 (`libsqlite3-sys` 0.37, CVE-2026-119375)

Accepted until `sqlx` allows `libsqlite3-sys` >= 0.39.

SQLite before 3.54.0 can return uninitialized page-cache memory when it opens a
database together with a sibling `-wal` file that declares a different page
size. Only `openvalut-server` links SQLite, and it creates and owns its database
file. Exploiting this requires a local attacker who can already write files next
to that database, i.e. the same access that lets them read the database
directly. The CLI and desktop clients do not use SQLite at all.

The exception disappears as soon as `sqlx` publishes a release that accepts
`libsqlite3-sys` 0.39; CI will then report the advisory again if it is still
pinned.

Notes on previously affected crates:

- `rsa` 0.9 (RUSTSEC-2023-0071) was replaced by `rsa` 0.10, which contains the
  fix. RSA is only used for the QR-code login handshake, where the private half
  is ephemeral and never leaves the machine.
- `ssh-agent-client-rs` was removed. The SSH agent wire protocol is now
  implemented in `crates/openvalut-cli/src/ssh_agent.rs` on top of `ssh-key`,
  so no third-party agent client sits in the dependency tree.

### Unmaintained `serial` 0.4

Resolved by upgrading `portable-pty` from 0.8 to 0.9, which uses `serial2`.
