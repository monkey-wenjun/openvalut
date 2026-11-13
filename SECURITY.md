# Security Policy

## Reporting

Do not publish suspected credential disclosure issues in a public issue. Report
them privately to the repository maintainers with affected versions,
reproduction steps, and impact.

## Dependency Exceptions

### RUSTSEC-2023-0071 (`rsa` 0.9.x)

Status: temporarily accepted until 2027-03-01.

No patched stable `rsa` release is currently available. The dependency enters
OpenValut through:

- `sqlx-mysql`, where RSA is used by MySQL authentication. Production MySQL
  must be reached over a trusted local connection or TLS with certificate
  verification; untrusted plaintext MySQL connections are unsupported.
- `ssh-agent-client-rs`/`ssh-key`, where OpenValut parses and forwards SSH keys
  to a local agent. OpenValut does not expose an RSA decryption oracle over the
  network.

CI ignores only this advisory by ID. All other RustSec vulnerabilities remain
release-blocking. The exception must be removed when a compatible stable fix is
available, or replaced with a backend that does not use the affected crate.

### Unmaintained `serial` 0.4

Resolved by upgrading `portable-pty` from 0.8 to 0.9, which uses `serial2`.
