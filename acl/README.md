<!-- Copyright (c) Microsoft Corporation. Licensed under the MIT License. -->

# Azure Container Linux (ACL)

Azure Container Linux (ACL) is a Microsoft derivative of [Flatcar Container Linux](https://www.flatcar.org/). It replaces the traditional Portage-based build system with **Azure Linux 3.0 RPM packages**, giving Microsoft a **sovereign supply chain** — every binary in the image is built, scanned, and signed within Microsoft's Azure Linux infrastructure.

ACL currently tracks **Flatcar Linux stable** as its upstream base.

## Documentation

See [`acl/docs/`](docs/) for detailed guides:

- [Architecture](docs/architecture.md) — overview, Flatcar relationship, boot flow, dm-verity, Ignition, SELinux
- [System Extensions](docs/sysexts.md) — base and standalone sysexts, GPU drivers
- [Platforms](docs/platforms.md) — supported platforms and OEM packages
- [Testing](docs/testing.md) — Kola/Mantle framework, enforcing tests
- [Build RPM Image](docs/BUILD_RPM_IMAGE_README.md) — building ACL images from RPMs
