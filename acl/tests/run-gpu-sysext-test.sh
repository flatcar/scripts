#!/bin/bash
# Smoke test: install GPU sysexts via ORAS from MCR and verify nvidia-smi.
#
# This script runs ON the GPU VM (via SSH from build_rpm_image.sh).
# It mirrors the GPU sysext installation steps from the ACL alpha release guide:
#   1. Install ORAS CLI
#   2. Pull the selected GPU driver sysext + companion sysexts
#      (nvidia-container-toolkit, nvidia-fabric-manager)
#   3. Deploy .raw files to /etc/extensions/ and refresh systemd-sysext
#   4. Verify nvidia-smi, nvidia-ctk, and nvidia-fabricmanager
#
# Required environment variables:
#   ACL_OS_VERSION       — sysext image tag, e.g. "3.0.20260304" (defaults to auto-detect from os-release)
#
# Optional environment variables:
#   GPU_DRIVER_FLAVOR    — Which driver sysext to install. One of:
#                            cuda-open  → nvidia-driver-cuda-open (NC A100, default)
#                            cuda       → nvidia-driver-cuda      (NC V100 / proprietary)
#                            vgpu       → nvidia-driver-vgpu      (NV A10)
#                          See acl/sysexts.yaml for the canonical list.

set -euo pipefail

ACL_GPU_REPO="${ACL_GPU_REPO:-mcr.microsoft.com/azurelinux/3.0/azure-container-linux}"
SYSEXT_STAGING="/tmp/sysext"

# Resolve and validate the GPU driver flavor. The matrix mirrors the
# `nvidia-driver-*` entries in azure-container-linux/acl/sysexts.yaml — keep
# the two in sync when adding a new driver variant.
GPU_DRIVER_FLAVOR="${GPU_DRIVER_FLAVOR:-cuda-open}"
case "${GPU_DRIVER_FLAVOR}" in
    cuda-open|cuda|vgpu) ;;
    *)
        echo "ERROR: GPU_DRIVER_FLAVOR must be one of: cuda-open, cuda, vgpu (got: ${GPU_DRIVER_FLAVOR})" >&2
        exit 1
        ;;
esac
GPU_DRIVER_SYSEXT="nvidia-driver-${GPU_DRIVER_FLAVOR}"

# Resolve ACL_OS_VERSION from /etc/os-release if not set.
# VERSION_ID in os-release matches the sysext image tag (e.g. "3.0.20260304").
if [[ -z "${ACL_OS_VERSION:-}" ]]; then
    ACL_OS_VERSION=$(. /etc/os-release && echo "${VERSION_ID}")
    echo "[INFO] Auto-detected ACL_OS_VERSION=${ACL_OS_VERSION} from /etc/os-release"
fi

echo "=== GPU Sysext Smoke Test ==="
echo "ACL_OS_VERSION:    ${ACL_OS_VERSION}"
echo "ACL_GPU_REPO:      ${ACL_GPU_REPO}"
echo "GPU_DRIVER_FLAVOR: ${GPU_DRIVER_FLAVOR} (${GPU_DRIVER_SYSEXT})"

# ── Step 1: Check for pre-staged sysexts or install ORAS ────────────────────
# If .raw files are already in the staging directory (e.g. uploaded via SCP
# from the build pipeline), skip ORAS entirely. Otherwise install ORAS and
# pull from the configured registry.
PRESTAGED_COUNT=$(find "${SYSEXT_STAGING}" -name '*.raw' -type f 2>/dev/null | wc -l || true)

if [[ "${PRESTAGED_COUNT}" -gt 0 ]]; then
    echo "[1/6] Found ${PRESTAGED_COUNT} pre-staged sysext file(s) — skipping ORAS"
    find "${SYSEXT_STAGING}" -name '*.raw' -ls
else
    echo "[1/6] Installing ORAS..."
    ORAS_VERSION="1.3.0"
    sudo mkdir -p /opt/oras-install/
    sudo curl -fsSL -o "/opt/oras-install/oras_${ORAS_VERSION}_linux_amd64.tar.gz" \
        "https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_linux_amd64.tar.gz"
    sudo tar -zxf "/opt/oras-install/oras_${ORAS_VERSION}_linux_amd64.tar.gz" -C /opt/oras-install/
    export PATH="/opt/oras-install:${PATH}"
    sudo rm -f "/opt/oras-install/oras_${ORAS_VERSION}_linux_amd64.tar.gz"
    oras version

    # If pulling from a private ACR, log in with the provided access token
    if [[ -n "${ACR_ACCESS_TOKEN:-}" ]]; then
        ACR_HOST="${ACL_GPU_REPO%%/*}"
        echo "[INFO] Logging in to private registry ${ACR_HOST}..."
        oras login "${ACR_HOST}" --username "00000000-0000-0000-0000-000000000000" --password "${ACR_ACCESS_TOKEN}"
    fi

    # ── Step 2: Pull GPU sysext images ─────────────────────────────────────
    echo "[2/6] Pulling GPU sysext images from ${ACL_GPU_REPO}..."
    mkdir -p "${SYSEXT_STAGING}"

    # Mandatory: NVIDIA GPU driver — flavor selected by GPU_DRIVER_FLAVOR.
    # Image name must match what the build pipeline publishes (see
    # publish_sysexts in acl-pipelines acl-stages.yml).
    echo "  Pulling ${GPU_DRIVER_SYSEXT}:${ACL_OS_VERSION}..."
    oras pull -o "${SYSEXT_STAGING}" "${ACL_GPU_REPO}/${GPU_DRIVER_SYSEXT}:${ACL_OS_VERSION}"

    # GPU container usage
    echo "  Pulling nvidia-container-toolkit:${ACL_OS_VERSION}..."
    oras pull -o "${SYSEXT_STAGING}" "${ACL_GPU_REPO}/nvidia-container-toolkit:${ACL_OS_VERSION}"

    # Multi-GPU support
    echo "  Pulling nvidia-fabric-manager:${ACL_OS_VERSION}..."
    oras pull -o "${SYSEXT_STAGING}" "${ACL_GPU_REPO}/nvidia-fabric-manager:${ACL_OS_VERSION}"
fi

echo "  Sysext files:"
find "${SYSEXT_STAGING}" -name '*.raw' -ls

# ── Step 3: Deploy sysexts ─────────────────────────────────────────────────
echo "[3/6] Deploying sysexts to /etc/extensions/..."
sudo mkdir -p /etc/extensions
sudo find "${SYSEXT_STAGING}" -name '*.raw' -exec mv {} /etc/extensions/ \;
[[ -n "${SYSEXT_STAGING}" ]] && rm -rf "${SYSEXT_STAGING}"

echo "  Installed extensions:"
ls -la /etc/extensions/*.raw

# ── Step 4: Refresh systemd-sysext ─────────────────────────────────────────
echo "[4/6] Refreshing systemd-sysext..."
sudo systemd-sysext refresh
sudo systemd-sysext status

# ── Step 5: Verify nvidia-smi ──────────────────────────────────────────────
echo "[5/6] Verifying nvidia-smi..."

# GPU driver may take a moment to initialize after sysext refresh.
MAX_RETRIES=20
RETRY_DELAY=15
for attempt in $(seq 1 "$MAX_RETRIES"); do
    if sudo nvidia-smi > /dev/null 2>&1; then
        echo "  nvidia-smi succeeded on attempt ${attempt}"
        sudo nvidia-smi
        break
    fi
    if [[ "$attempt" -eq "$MAX_RETRIES" ]]; then
        echo "ERROR: nvidia-smi failed after ${MAX_RETRIES} attempts" >&2
        sudo nvidia-smi 2>&1 || true
        exit 1
    fi
    echo "  nvidia-smi not ready (attempt ${attempt}/${MAX_RETRIES}), retrying in ${RETRY_DELAY}s..."
    sleep "$RETRY_DELAY"
done

# Verify nvidia-modprobe can load the kernel module and create device nodes.
# This is the step where SELinux issues caused GPU provisioning failures in
# AKS (AgentBaker configGPUDrivers flow).
echo "[5b/6] Verifying nvidia-modprobe..."
sudo nvidia-modprobe -u -c0
echo "  nvidia-modprobe: OK"

# ── Step 6: Verify nvidia-ctk and fabric manager ──────────────────────────
echo "[6/6] Verifying nvidia-container-toolkit and fabric manager..."

# nvidia-ctk should be available after sysext refresh
if command -v nvidia-ctk > /dev/null 2>&1; then
    nvidia-ctk --version
    echo "  nvidia-ctk: OK"
else
    echo "ERROR: nvidia-ctk not found in PATH after sysext refresh" >&2
    exit 1
fi

# Enable and start nvidia-fabricmanager for multi-GPU validation.
# Fabric manager is only needed for multi-GPU NVLink/NVSwitch topologies
# (ND-series). On single-GPU VMs (NC-series) it will fail to start — this
# is expected, so we only verify it was installed, not that it's running.
GPU_COUNT=$(sudo nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | wc -l)
sudo systemctl enable nvidia-fabricmanager

if [[ "${GPU_COUNT}" -gt 1 ]]; then
    echo "  Multi-GPU detected (${GPU_COUNT} GPUs), starting fabric manager..."
    sudo systemctl start nvidia-fabricmanager

    # Give the service a moment to stabilize
    sleep 5

    if systemctl is-active --quiet nvidia-fabricmanager; then
        echo "  nvidia-fabricmanager: active"
    else
        echo "ERROR: nvidia-fabricmanager failed to start on multi-GPU VM" >&2
        systemctl status nvidia-fabricmanager || true
        exit 1
    fi
else
    echo "  Single GPU detected — skipping fabric manager start (not needed for NC-series)"
    echo "  nvidia-fabricmanager sysext: installed"
fi

echo "=== GPU Sysext Smoke Test PASSED ==="
