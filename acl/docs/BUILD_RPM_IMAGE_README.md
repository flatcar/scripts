# RPM-Based Image Build System for Azure Container Linux derivative of Flatcar Linux

This document describes the RPM-based image build system extension for the Flatcar SDK container, which
enables building Azure Container Linux images using packages from Azure Linux
3.0 repositories.

Currently targeting `stable-4459.2.2` of Flatcar Linux upstream. Upstream build is available here: [images](https://bincache.flatcar-linux.net/images/amd64/4459.2.2/), [test results](https://bincache.flatcar-linux.net/testing/4459.2.2/amd64/qemu/).

## Overview

The build system has been extended to support package source modes:

- **PORTAGE**: (default) Traditional Flatcar build using only Portage packages
- **RPM**: (new) Azure Container Linux build using Azure Linux RPM packages

This RPM approach provides:

- Faster builds (pre-built RPM binaries vs. compiling from source)
- Better alignment with Azure Linux & Fedora ecosystem
- Maintained compatibility with Flatcar-specific tooling

While majority of the RPM logic is agnostic to Azure Linux RPMs, additional work would be needed to support other RPM-based distros due to differences in package naming, dependencies, and repository structure. The current implementation is tailored for Azure Linux 3.0 packages and repositories.

## Prerequisites

### Required Tools

- **Docker**: For SDK container management
- **libvirt/KVM**: For VM testing (optional but recommended)
- **virsh**: VM management CLI
- **expect**: For serial console automation (VM testing)
- **curl**: For downloading RPMs
- **createrepo_c**: For creating local RPM repository metadata
- **Azure CLI**: Only for Azure VM testing

Install on Ubuntu/Debian (22.04, 24.04, 26.04 LTS):

```bash
sudo apt-get install docker.io qemu-system-x86 libvirt-daemon-system libvirt-clients \
  bridge-utils expect curl createrepo-c golang-1.23 rpm genisoimage ovmf

# For Azure VM testing, also install Azure CLI:
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

**Note**: `golang-1.23` is explicitly pinned because the default `golang` metapackage maps to different Go versions across Ubuntu releases (1.18 on 22.04, 1.22 on 24.04, 1.26 on 26.04). The `rpm` package provides `rpmkeys` needed by the build system. The `genisoimage` package is needed for Ignition ISO creation. The `ovmf` package provides UEFI firmware for VM testing.

**Note**: `docker.io` is used because it is available from the default Ubuntu repositories on all LTS versions. `docker-ce` requires adding Docker's third-party apt source. The `qemu-system-x86` package is preferred over the `qemu-kvm` transitional package for forward compatibility.

Install on Azure Linux:

```bash
sudo tdnf install -y moby-engine docker-cli qemu-kvm libvirt libvirt-client expect curl createrepo_c edk2-ovmf cdrkit swtpm make golang-1.24.3 acl rpm-build azure-cli
```

**Note**: Go 1.24.3 is explicitly pinned. Go 1.25+ on Azure Linux uses `systemcrypto` which requires `CGO_ENABLED=1`, but the Azure Linux toolkit currently only supports `CGO_ENABLED=0`.

**Important**: On Azure Linux, `moby-engine` does not include the Docker CLI - you must install `docker-cli` separately.

### Start Services and Configure Groups (Azure Linux)

After installation, start required services:

```bash
sudo systemctl start docker libvirtd
sudo systemctl enable docker libvirtd
```

Add your user to the required groups:

```bash
sudo usermod -aG docker,libvirt $USER
```

**Note**: Group membership requires logout/login or reboot to take effect.

### SSH Key Setup (Required for VM Access)

The build script uses Ignition to provision SSH keys into the VM. Generate an SSH keypair if you don't have one:

```bash
[ ! -f ~/.ssh/id_ed25519 ] && ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
```

The script will automatically use keys from `~/.ssh/id_*.pub` when starting the VM.

### Azure Authentication (Required for Azure VM Testing)

For testing on an Azure VM, you must be authenticated to Azure CLI:

```bash
# Login to Azure (interactive browser-based login)
az login
```

> **Note:** For CI/automation, prefer managed identity or workload identity
> federation over service principal secrets. See
> [Azure authentication best practices](https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli).

### System Requirements

- **Disk Space**: 50GB+ for SDK container, RPMs, and build artifacts
- **RAM**: 8GB+ recommended
- **Network**: Access to Azure Linux package repositories (`packages.microsoft.com` — publicly available, no credentials required)

### SDK Container

The build system requires an extended Flatcar SDK container, which includes all build tools.

## Complete Build Workflow

### Phase 1: SDK Container Setup

#### Rebuild SDK Container

```bash
# Rebuild SDK container with updated tools or dependencies
./acl/build_rpm_image.sh --build-sdk-container
```

**When to rebuild SDK:**

- First time setup
- After updating SDK dependencies
- When RPM/dnf5 tools need updates
- If SDK container is corrupted

### Phase 2: Build Custom RPM Packages

Build custom RPM packages using the Azure Linux toolkit:

```bash
# Build custom RPMs and add them to staging
./acl/build_rpm_image.sh --build-rpms

# Clean staging and build RPM directories before rebuilding custom RPMs
./acl/build_rpm_image.sh --clean --build-rpms
```

This step:

- Clones Azure Linux 3.0 toolkit if not present
- Builds packages defined in `acl/SPECS/`
- Copies built RPMs to the staging directory
- Updates repository metadata automatically

**Build output:** Custom RPMs are added to `__build__/rpm-staging/`.

### Phase 3: Build the Image

Build the Flatcar production image using RPM package sources.

```bash
# Build image
./acl/build_rpm_image.sh --rebuild
```

**Build output location:** `__build__/images/images/amd64-usr/latest/`

### Phase 4: Build VM Image (Optional)

Convert the production image to a VM-ready format. The script supports building two different types of images:

- QEMU image (default)
- Azure VHD

```bash
# Build a QEMU VM image after main image build
./acl/build_rpm_image.sh --build-vm-image --vm-type=qemu

# To support backward compatibility, when --vm-type is NOT specified, the tool will build a QEMU image, by default
./acl/build_rpm_image.sh --build-vm-image

# Build an Azure VHD image
./acl/build_rpm_image.sh --build-vm-image --vm-type=azure
```

#### Build Test VM Image (Optional)

The `--build-test-image` flag builds a test VM image that includes the docker sysext, which is required for running kola tests.

> **Note:** The test image expects `kola`-tagged standalone sysexts to be already
> built. Run `--build-standalone-sysexts=kola` before (or alongside) `--build-test-image`.

```bash
# Build a QEMU test VM image
./acl/build_rpm_image.sh --build-test-image --vm-type=qemu

# Build an Azure VHD test VM image
./acl/build_rpm_image.sh --build-test-image --vm-type=azure

# When --vm-type is not specified, QEMU is used by default
./acl/build_rpm_image.sh --build-test-image
```

#### Build Standalone Sysexts (Optional)

Standalone sysexts are squashfs images (`.raw`) activated at runtime via `systemd-sysext`.
They are defined in `acl/sysexts.yaml` and built alongside the ACL image.

```bash
# Build all standalone sysexts
./acl/build_rpm_image.sh --build-standalone-sysexts

# Build only sysexts tagged "kola" (e.g., docker)
./acl/build_rpm_image.sh --build-standalone-sysexts=kola

# Build sysexts matching any of several tags (OR logic)
./acl/build_rpm_image.sh --build-standalone-sysexts=kola,gpu

# Build only GPU-related sysexts
./acl/build_rpm_image.sh --build-standalone-sysexts=gpu

# Build only the LISA testing sysext
./acl/build_rpm_image.sh --build-standalone-sysexts=lisa
```

Sysext `.raw` files are written to:

```
__build__/images/images/<arch>-usr/latest/<name>.raw
```

Available tags (see `acl/sysexts.yaml` for the full list):

| Tag    | Sysexts                                                                      |
|--------|------------------------------------------------------------------------------|
| `kola` | docker                                                                       |
| `gpu`  | nvidia-driver-cuda-open, nvidia-driver-cuda, nvidia-driver-vgpu, nvidia-container-toolkit, nvidia-fabric-manager |
| `lisa` | lisa-testing                                                                 |

#### VM Image Output

- QEMU:

```bash
__build__/images/images/<arch>-usr/latest/acl_production_qemu_uefi_image.img
```

- Azure:

```bash
__build__/images/images/<arch>-usr/latest/acl_production_azure_image.vhd
```

- QEMU Test Image:

```bash
__build__/images/images/<arch>-usr/latest/acl_production_qemu_uefi_test_image.img
```

- Azure Test Image:

```bash
__build__/images/images/<arch>-usr/latest/acl_production_azure_test_image.vhd
```

### Phase 5: Start VM and Run Tests

The `acl/build_rpm_image.sh` script can be used to start an ACL VM and run integrated tests on it. The script supports starting a VM of two different types:

- QEMU image (default)
- Azure VHD

1. **Start a QEMU VM**

The script automatically configures libvirt (default network, URI) on Azure Linux 3. On Ubuntu, libvirt's networking works out-of-the-box.

```bash
# Just start the VM and observe the boot sequence, get access to interactive console.
./acl/build_rpm_image.sh --start-vm

# Start VM without secure boot (e.g. for UKI bootloader mode)
./acl/build_rpm_image.sh --start-vm --no-secure-boot

# Boot the test image (with docker sysext) instead of the regular image
./acl/build_rpm_image.sh --start-vm --use-test-image

# Start VM and run inline command via SSH
./acl/build_rpm_image.sh --start-vm --run-script="cat /etc/os-release"

# Run test script on VM (this script is included and used for a basic smoke test for now)
./acl/build_rpm_image.sh --start-vm \
  --run-script=./acl/tests/run-container-test.sh

# Run multiple test scripts
./acl/build_rpm_image.sh --start-vm \
  --run-script=./acl/tests/run-secureboot-test.sh \
  --run-script=./acl/tests/run-container-test.sh \
  --run-script=./acl/tests/run-systemd-health-test.sh \
  --run-script=./acl/tests/run-dmesg-io-error-test.sh \
  --run-script=./acl/tests/run-selinux-avc-test.sh
```

Subsequent runs will clean up the VM automatically. To manually clean up the VM:

```bash
# Stop VM
virsh destroy acl

# Remove VM
virsh undefine --nvram acl
```

1. **Start an Azure VM**

For Azure VM testing, ensure that you have Azure CLI downloaded and are authenticated into Azure. The script automatically validates and if necessary, creates the required Azure infrastructure. Resources are created inside default Azure subscription and region. To override, use `--az-sub-id` and `--az-region` as outlined below.

By default, before starting a new Azure VM, all the pre-existing resource groups and VMs created by the current user earlier are scheduled for deletion. If you want to keep your older VMs, override this behavior with `--no-cleanup`.

```bash
# Basic Azure VM testing
./acl/build_rpm_image.sh --start-vm --vm-type=azure

# Override Azure subscription, region, and storage account for uploading the Azure VHD
./acl/build_rpm_image.sh --start-vm --vm-type=azure \
  --az-sub-id=<custom-subscription-id> \
  --az-region=<custom-region> \
  --az-storage-account=<custom-storage-account-name>

# Start a new Azure VM while preserving pre-existing VMs
./acl/build_rpm_image.sh --start-vm --vm-type=azure --no-cleanup
```

You can also use the `--run-script` flag to run tests on the Azure VM, just like with the QEMU VM.

#### Access the VM

**SSH Access**

- The script generates an Ignition ISO with your SSH public keys from `~/.ssh/id_*.pub`
- SSH user: `azureuser` (default) - customize with `--ssh-user=USER`
- Ignition runs on first boot only

#### GPU Smoke Testing (Azure Only)

Test NVIDIA GPU sysexts on an Azure GPU VM. The script parameterizes the
SKU and driver flavor so all three `nvidia-driver-*` sysexts shipped by ACL
can be exercised. Requires Azure CLI authentication and quota in the
selected region.

| Driver flavor | Default SKU | Notes |
| --- | --- | --- |
| `cuda-open` | `Standard_NC24ads_A100_v4` (NC A100) | open-source kernel module |
| `cuda` | `Standard_NC6s_v3` (NC V100) | proprietary kernel module |
| `vgpu` | `Standard_NV6ads_A10_v5` (NV A10) | virtual-GPU kernel module |

`nvidia-fabricmanager` start-up is only validated on multi-GPU NVLink SKUs
(ND-series). On the single-GPU SKUs above, fabric-manager is install-validated
only.

**Default mode (ORAS/ACR)** — pulls sysexts from ACR using your Azure identity:

```bash
# Provision GPU VM, keep it running
./acl/build_rpm_image.sh --start-vm --vm-type=azure \
  --az-vm-size=Standard_NC24ads_A100_v4 --keep-vm

# Run GPU smoke test (cuda-open / NC A100 — the default)
./acl/tests/run-gpu-sysext-host.sh --ssh-key=~/.ssh/id_ed25519

# Or test the proprietary cuda driver on a V100 VM
./acl/build_rpm_image.sh --start-vm --vm-type=azure \
  --az-vm-size=Standard_NC6s_v3 --keep-vm
./acl/tests/run-gpu-sysext-host.sh --ssh-key=~/.ssh/id_ed25519 \
  --gpu-driver-flavor=cuda

# Or test the vGPU driver on an NV A10 VM
./acl/build_rpm_image.sh --start-vm --vm-type=azure \
  --az-vm-size=Standard_NV6ads_A10_v5 --keep-vm
./acl/tests/run-gpu-sysext-host.sh --ssh-key=~/.ssh/id_ed25519 \
  --gpu-driver-flavor=vgpu
```

Or end-to-end with `--run-host-script`:

```bash
./acl/build_rpm_image.sh \
  --start-vm --vm-type=azure \
  --az-vm-size=Standard_NC24ads_A100_v4 \
  --run-host-script=./acl/tests/run-gpu-sysext-host.sh
```

**SCP mode** — uploads locally-built sysext `.raw` files instead of pulling from ACR:

```bash
# Build sysexts first (Phase 4), then:
SYSEXT_DIR=__build__/images/images/amd64-usr/latest \
  ./acl/tests/run-gpu-sysext-host.sh --scp-sysexts --ssh-key=~/.ssh/id_ed25519 \
    --gpu-driver-flavor=cuda-open
```

The test verifies:
- `nvidia-smi` detects the GPU
- `nvidia-modprobe -u -c0` loads kernel module and creates device nodes
- `nvidia-ctk` (container toolkit) is available
- `nvidia-fabricmanager` starts (multi-GPU VMs only)

**Which sysexts does ORAS mode pull?**

By default, the script pulls from the OCI registry configured via `OCI_REGISTRY`
using the VM's OS version as the tag (e.g., `3.0.20260428`). The pipeline's
`publish_sysexts` stage pushes GPU sysexts to the registry for every build.

- **Pre-built image + test:** Use the default ORAS mode. The sysexts
  in the registry match the CI-built image.
- **Rebuild + test local changes:** Use `--scp-sysexts` with
  `SYSEXT_DIR=__build__/images/images/amd64-usr/latest` to test your locally-built
  sysexts instead of pulling from the registry.


To override the OCI repo or tag (e.g., testing against a different build):

```bash
OCI_REGISTRY=your-registry.azurecr.io \
ACL_GPU_REPO=${OCI_REGISTRY}/azure-container-linux \
  ./acl/tests/run-gpu-sysext-host.sh --ssh-key=~/.ssh/id_ed25519
```

Environment variables:
- `ACL_GPU_REPO` — override sysext OCI registry (default: `${OCI_REGISTRY}/azure-container-linux`)
- `OCI_REGISTRY` — OCI registry hostname for token generation (must be set via environment)
- `SYSEXT_DIR` — directory containing `.raw` files (required with `--scp-sysexts`)

### Phase 6: Run Kola E2E Tests (Optional)

Run the Flatcar/ACL kola E2E test suite against QEMU or Azure images.

#### Kola Prerequisites

The prerequisite for running kola tests is to build the customized `mantle` container. Clone the `azure-container-linux-mantle` repository next to the `azure-container-linux` repository:

```bash
git clone https://github.com/microsoft/azure-container-linux-mantle.git
```

Then build the `mantle` container with ACL support:

```bash
cd azure-container-linux-mantle && docker build -t mantle .
```

#### Environment Variables

| Variable | Description | Default |
| --- | --- | --- |
| `PACKAGE_SOURCE_MODE` | Set to `RPM` for ACL images | `PORTAGE` |
| `MAX_RUNS` | Number of retry attempts for flaky tests | `1` |
| `KOLA_DEBUG` | Set to `true` for verbose kola output | (unset) |

#### Running QEMU Kola Tests

Requires: QEMU test image built (`--build-test-image --vm-type=qemu`, see Phase 4).

```bash
# Run the full E2E test suite (~4 hours)
./acl/build_rpm_image.sh --run-kola-tests

# Run a specific test
PACKAGE_SOURCE_MODE=RPM ./run_local_tests.sh amd64 2 cl.sysext.fallbackdownload
```

**Output:**

- `results-qemu_uefi.md`, `results-qemu_uefi.tap` — summary
- `results-qemu_uefi-detailed.md`, `results-qemu_uefi-detailed.tap` — detailed
- `__TESTS__/qemu-uefi/` — per-run TAP files and logs

#### Running Azure Kola Tests

Requires:

- Azure VHD test image built (`--build-test-image --vm-type=azure`, see Phase 4)
- Azure CLI installed and logged in (`az login`)
- An Azure subscription with available quota
- `AZURE_TOKEN_CREDENTIALS=AzureCLICredential` set (required on most devboxes)

```bash
# Run specific tests on Azure
PACKAGE_SOURCE_MODE=RPM \
AZURE_SUBSCRIPTION_ID="<your-subscription-id>" \
AZURE_TOKEN_CREDENTIALS=AzureCLICredential \
  ./run_azure_tests.sh amd64 2 cl.ignition.v1.once coreos.ignition.once
```

**Arguments:**

- `amd64` or `arm64` — target architecture
- `2` — number of parallel test instances
- Remaining args — kola test patterns to run (e.g., `cl.ignition.v1.once`, `docker.base`)

**Azure-specific environment variables:**

| Variable | Description | Default |
| --- | --- | --- |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription to use for test resources | Default az subscription |
| `AZURE_TOKEN_CREDENTIALS` | Set to `AzureCLICredential` to use az CLI auth | (SDK default) |
| `AZURE_LOCATION` | Azure region for test VMs | `westus2` |
| `AZURE_amd64_MACHINE_SIZE` | VM size for amd64 tests | `Standard_D2s_v6` |
| `AZURE_arm64_MACHINE_SIZE` | VM size for arm64 tests | (default) |

**Output:**

- `results-azure.md`, `results-azure.tap` — summary
- `results-azure-detailed.md`, `results-azure-detailed.tap` — detailed
- `__TESTS__/azure/` — per-run TAP files and logs

#### Kola Troubleshooting

- **`preferred subscription ... is not a part of available subscriptions`**: Set `export AZURE_TOKEN_CREDENTIALS=AzureCLICredential` before running. This ensures kola uses your Azure CLI credentials rather than SDK defaults.
- **Multiple subscriptions**: Explicitly set `AZURE_SUBSCRIPTION_ID` to the subscription ID (not name) you want to use.

## Common Workflows

### Development Iteration

Efficient workflow for iterative development:

```bash
# Quick rebuild after packaging/script changes
./acl/build_rpm_image.sh --rebuild

# Build custom RPMs and rebuild image
./acl/build_rpm_image.sh --build-rpms --rebuild

# Rebuild and retest
./acl/build_rpm_image.sh --rebuild --build-vm-image --start-vm \
  --run-script=./acl/tests/run-container-test.sh

# Or use the short cut of the command above (runs additional tests as well):
./acl/build_rpm_image.sh --rebuild-and-test
```

## Troubleshooting

### Common Issues

- **Issue**: VM fails to boot with UKI bootloader mode
  **Cause**: UKI images are not yet signed; secure boot rejects them.
  **Solution**: Use `--no-secure-boot` flag (this is done automatically when `BOOTLOADER_MODE=uki`):

  ```bash
  ./acl/build_rpm_image.sh --start-vm --no-secure-boot
  ```

- **Issue**: Red block preceded by: `sudo: rpm: command not found`
  **Solution**: Ensure SDK container is rebuilt with RPM tools:

  ```bash
  ./acl/build_rpm_image.sh --build-sdk-container
  ```

- **Issue**: VM startup fails with `tpm-emulator: could not send INIT` (Azure Linux 3)
  **Cause**: swtpm on some Azure Linux 3 builds crashes due to SECCOMP blocking the `clone3` syscall.
  **Solution**: Create a wrapper script that disables SECCOMP:

  ```bash
  # Create wrapper script
  cat << 'EOF' | sudo tee /usr/local/bin/swtpm-wrapper
  #!/bin/bash
  exec /usr/bin/swtpm.orig "$@" --seccomp action=none
  EOF
  sudo chmod +x /usr/local/bin/swtpm-wrapper

  # Replace swtpm with wrapper
  sudo mv /usr/bin/swtpm /usr/bin/swtpm.orig
  sudo ln -s /usr/local/bin/swtpm-wrapper /usr/bin/swtpm
  ```
