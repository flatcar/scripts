# Testing

ACL reuses the Flatcar **Mantle/Kola** test framework:

- **Kola** is the test harness that boots images and runs test cases against them.
- **Mantle** is the container that packages kola along with platform-specific plumbing (QEMU, cloud SDKs, etc.).

## Test Categories

- `cl.basic` — fundamental OS health checks
- `cl.verity` — dm-verity integrity validation
- `cl.ignition.*` — Ignition provisioning scenarios
- `cl.cloudinit.*` — cloud-init configuration
- `cl.update.*` — A/B update lifecycle
- `sysext.*` — sysext activation and runtime behavior

## Enforcing Tests

**`kola_enforcing.yaml`** — a structured allowlist of kola test names that must pass before any image is published, with per-platform exception rules.

Results are emitted in TAP format and converted to Markdown summaries.

## ACL-Specific Tests

Additional tests live in `acl/tests/`:

- Secure Boot verification (`run-secureboot-test.sh`)
- systemd service health (`run-systemd-health-test.sh`)
- Disk I/O error detection (`run-dmesg-io-error-test.sh`)
- Container runtime smoke tests (`run-container-test.sh`)
- SELinux AVC check (`run-selinux-avc-test.sh`)
