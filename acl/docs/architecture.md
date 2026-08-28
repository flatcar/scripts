# ACL Architecture

## Overview

Azure Container Linux (ACL) is a Microsoft derivative of [Flatcar Container Linux](https://www.flatcar.org/). It replaces the traditional Portage-based build system with **Azure Linux 3.0 RPM packages**, leveraging Microsoft **sovereign supply chain** — every binary in the image is built, scanned, and signed within Microsoft's Azure Linux infrastructure. This means CVE fixes flow through Azure Linux's rapid package rebuild pipeline and can be picked up by ACL without waiting for upstream Flatcar releases, dramatically reducing the time-to-patch for critical vulnerabilities. Leveraging Azure Linux packages also enables first-class NVIDIA GPU support delivered as system extensions (CUDA, vGPU, container toolkit, fabric manager).

ACL currently tracks **Flatcar Linux stable** as its upstream base.

## Relationship with Flatcar

ACL preserves a high degree of parity with Flatcar Linux and enjoys healthy upstream/downstream collaboration: it both pushes its changes upstream and pulls in Flatcar updates on a regular cadence. The core design principles of an immutable, minimal container host with a focus on security and reliability remain intact.

Where ACL aligns with Flatcar:

- The SDK container, board setup, and image build pipeline reuse the Flatcar `build_library` infrastructure.
- The Flatcar update model, partition layout (USR-A/USR-B A/B scheme, OEM, ROOT), and OEM package model are retained.
- Test collateral runs against the same `kola` harness (from the Mantle project) used by upstream Flatcar.

Where ACL diverges (temporarily, with plans to upstream most of these changes):

- Package installation uses RPMs sourced from Azure Linux repositories instead of Portage ebuilds.
- UKI boot mode with `systemd-boot` is the primary boot path (see [Boot, Partitions, and Provisioning](#boot-partitions-and-provisioning) below).
- Partition growing, dm-verity device setup, fstab generation, and the initramfs build all use **upstream systemd tooling** (`systemd-repart`, `systemd-growfs`, `systemd-veritysetup-generator`, `systemd-fstab-generator`) instead of the custom CoreOS/Flatcar bootengine generators, reducing maintenance burden and aligning with conventions that are becoming the industry standard.
- The initramfs is a **single-stage dracut image** instead of Flatcar's two-stage bootengine approach (minimal embedded initrd → squashfs). Flatcar's bootengine is still included for the `/etc` overlay setup and Ignition provisioning, but its verity and `/usr` mount modules are replaced by their systemd equivalents.
- **Boot performance optimizations** — `ldconfig.service` is reordered to run after `systemd-sysext.service` and removed from the `sysinit.target` critical path, reducing first-boot time by ~6 s on Azure VMs.
- The production image does not ship with Docker embedded.

## Image Outputs

The build system produces a base OS image (`acl_production_image.bin`) and then converts it into platform-specific disk images via `image_to_vm.sh`:

- **Azure VHD** — the production output, published to the Azure Compute Gallery. Includes the `oem-azure` package and platform sysexts.
- **QEMU/KVM qcow2** (`qemu_uefi`) — the development and CI target, used for local iteration and automated kola testing.
- **Test image** — a variant of either format that includes additional test dependencies, used as the boot target for kola test runs.

## Boot, Partitions, and Provisioning

### systemd-boot, UKI, and Addons

ACL's primary boot path uses **systemd-boot** with **Unified Kernel Images (UKI)**:

- `ukify` packs the kernel, initramfs, kernel command line (including verity parameters), and an EFI stub into a single signed PE binary installed on the EFI System Partition.
- **systemd-boot** is the UEFI bootloader that discovers and launches UKIs from the ESP.

**Addons** extend UKI behavior without rebuilding the image:

- **First-boot addon** — an addon that triggers Ignition provisioning on the initial boot cycle. After first-boot processing completes, the addon is removed so subsequent boots skip provisioning.
- **OEM selection addon** — injects the `oem_id` and Ignition platform identifier for the target cloud or hypervisor, allowing a single UKI to adapt to different environments.
- **FIPS addon** - activates FIPS mode.
- **kdump addon** - enables kdump support.

### dm-verity for `/usr`

The `/usr` partition (USR-A) is a read-only btrfs filesystem with zstd compression. **dm-verity** provides block-level integrity verification:

- The verity hash tree is appended to the USR partition data.
- At boot, `systemd-veritysetup` activates the verity device using kernel command-line parameters embedded in the UKI: `systemd.verity_usr_data`, `systemd.verity_usr_hash`, and `systemd.verity_usr_options=hash-offset=<N>,panic-on-corruption`.
- Any corruption of `/usr` causes an immediate kernel panic, preventing the system from running a tampered image.

The A/B partition scheme (USR-A / USR-B) enables safe updates: the inactive slot is written, verified, and then atomically switched on reboot.

### `/etc` Overlay from `/usr`

`/etc` is mounted as an **overlayfs** with:

- **Lower (read-only)**: `/usr/share/distro/etc` — defaults shipped in the image.
- **Upper (writable)**: persisted on the ROOT partition.

This allows `/usr` to remain fully immutable and verity-protected while giving services and users a writable `/etc`. The overlay is configured early in boot by Flatcar's BootEngine.

### Ignition

[Ignition](https://coreos.github.io/ignition/) is the first-boot provisioning tool. It processes a JSON configuration delivered through platform metadata (Azure custom data, QEMU `fw_cfg`, etc.) to:

- Write files, create users, and configure SSH keys.
- Set up systemd units, mount points, and network configuration.
- Format and mount additional disks.

In UKI mode, Ignition execution is gated by the first-boot addon described above.

### systemd Partition Growth

The ROOT partition is created at a minimal size in the shipped image. On first boot, **systemd-repart** and **systemd-growfs** automatically expand it to fill all remaining disk space, giving workloads access to the full disk without manual intervention.

### SELinux

ACL ships with **SELinux in enforcing mode by default**. The policy is aligned with Flatcar's upstream SELinux policy, which focuses on strict separation between the host OS and container workloads — host system services run in confined domains while containers are isolated by the `container_t` type. See [SELinux Container Domains](selinux.md) for specialized workload domains and safe configuration examples.
