#!/bin/bash
# Host-side GPU sysext smoke test orchestrator.
#
# This script runs on the BUILD HOST (not on the VM) and orchestrates the
# full GPU sysext test flow. By default, it generates an OCI registry access
# token using the developer's Azure identity and passes it to the VM so the
# test script can pull sysexts via ORAS.
#
# Alternatively, use --scp-sysexts to SCP local .raw files to the VM
# instead of pulling from a registry.
#
# Modes:
#   Default (ORAS pull from OCI registry):
#     - VM must have outbound network access to ${OCI_REGISTRY}
#     - The host running this script must be able to mint an access
#       token (i.e. have an active `az login` session or run with an MSI
#       that has pull access on the registry).
#     - No local build artifacts are needed.
#
#   --scp-sysexts (SCP push from local build):
#     - SYSEXT_DIR must point at a directory containing the GPU sysext
#       .raw files (e.g. __build__/images/.../latest).
#     - VM does NOT need any registry access, but the SSH user must have
#       passwordless sudo (used to stage files into /tmp/sysext).
#     - Useful when iterating on a local sysext build before publishing
#       it to the registry.
#
# Usage with build_rpm_image.sh --run-host-script:
#   ./acl/build_rpm_image.sh \
#     --start-vm --vm-type=azure \
#     --az-vm-size=Standard_NC24ads_A100_v4 \
#     --run-host-script=./acl/tests/run-gpu-sysext-host.sh
#
# With SCP fallback:
#   SYSEXT_DIR=__build__/images/images/amd64-usr/latest \
#     ./acl/tests/run-gpu-sysext-host.sh --scp-sysexts --ssh-key=~/.ssh/id_ed25519
#
# Or standalone after provisioning a VM:
#   ./acl/tests/run-gpu-sysext-host.sh --ssh-key=~/.ssh/id_ed25519
#
# Environment variables:
#   ACL_GPU_REPO  — Override sysext OCI registry (default: ${OCI_REGISTRY}/azure-container-linux)
#   OCI_REGISTRY  — OCI registry hostname for token generation (must be set via environment)
#   SYSEXT_DIR    — Directory containing GPU sysext .raw files (required with --scp-sysexts)
#   VM_SSH_USER   — Override the default SSH user (default: azureuser; legacy Flatcar images use 'core')
#   GPU_DRIVER_FLAVOR — Driver variant to install on the VM. One of:
#                       cuda-open (default, NC A100)
#                       cuda      (NC V100 / proprietary)
#                       vgpu      (NV A10)
#   SCRIPT_DIR    — Path to azure-container-linux root (set automatically by validate_common.sh)
#
# The VM state (IP, RG, name) is read from .vm-state.env (written by
# build_rpm_image.sh --start-vm).

set -euo pipefail

source "${SCRIPT_DIR:-$(cd "$(dirname "$0")/.." && pwd)/..}/acl/validate/validate_common.sh"

SCP_SYSEXTS=false
GPU_DRIVER_FLAVOR="${GPU_DRIVER_FLAVOR:-cuda-open}"

# Parse args passed by validate_common.sh's host-script runner
while [[ $# -gt 0 ]]; do
    case "$1" in
        --vm-type=*)            VM_TYPE="${1#*=}"; shift ;;
        --ssh-user=*)           VM_SSH_USER="${1#*=}"; shift ;;
        --ssh-key=*)            VM_SSH_KEY="${1#*=}"; shift ;;
        --scp-sysexts)          SCP_SYSEXTS=true; shift ;;
        --gpu-driver-flavor=*)  GPU_DRIVER_FLAVOR="${1#*=}"; shift ;;
        *)                      shift ;;
    esac
done

# Validate driver flavor here so we fail before provisioning anything.
case "${GPU_DRIVER_FLAVOR}" in
    cuda-open|cuda|vgpu) ;;
    *)
        error "--gpu-driver-flavor must be one of: cuda-open, cuda, vgpu (got: ${GPU_DRIVER_FLAVOR})"
        exit 1
        ;;
esac
GPU_DRIVER_SYSEXT="nvidia-driver-${GPU_DRIVER_FLAVOR}"

# Load VM state
VM_STATE_FILE="${SCRIPT_DIR:-$(cd "$(dirname "$0")/.." && pwd)/..}/.vm-state.env"
if [[ -f "${VM_STATE_FILE}" ]]; then
    # shellcheck source=/dev/null
    source "${VM_STATE_FILE}"
fi

if [[ -z "${VM_IP:-}" ]]; then
    error "VM_IP not available — provision a VM first with --start-vm"
    exit 1
fi

SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10)
if [[ -n "${VM_SSH_KEY:-}" ]]; then
    SSH_OPTS+=(-i "${VM_SSH_KEY}")
fi

SSH_USER="${VM_SSH_USER:-azureuser}"

info "GPU Sysext Host Test"
info "  VM IP:        ${VM_IP}"
info "  SSH User:     ${SSH_USER}"
info "  Driver:       ${GPU_DRIVER_FLAVOR} (${GPU_DRIVER_SYSEXT})"
info "  Mode:         $(if ${SCP_SYSEXTS}; then echo "SCP (local files)"; else echo "ORAS (OCI pull)"; fi)"

# ── Build env vars to pass to the VM test script ─────────────────────────
VM_ENV="GPU_DRIVER_FLAVOR=${GPU_DRIVER_FLAVOR}"

if ${SCP_SYSEXTS}; then
    # ── SCP mode: upload .raw files to VM staging directory ───────────────
    if [[ -z "${SYSEXT_DIR:-}" ]]; then
        error "SYSEXT_DIR is required with --scp-sysexts"
        exit 1
    fi
    if [[ ! -d "${SYSEXT_DIR}" ]]; then
        error "SYSEXT_DIR does not exist: ${SYSEXT_DIR}"
        exit 1
    fi

    # Upload only the selected driver flavor + companion sysexts. Skipping
    # the unused driver variants keeps the VM staging directory minimal
    # and avoids accidentally activating a conflicting kernel module.
    GPU_SYSEXTS=("${GPU_DRIVER_SYSEXT}" "nvidia-container-toolkit" "nvidia-fabric-manager")
    STAGING="/tmp/sysext"

    info "Uploading GPU sysexts to VM..."
    ssh "${SSH_OPTS[@]}" "${SSH_USER}@${VM_IP}" "sudo mkdir -p ${STAGING} && sudo chmod 777 ${STAGING}"

    UPLOADED=0
    for name in "${GPU_SYSEXTS[@]}"; do
        raw_file=$(find "${SYSEXT_DIR}" -name "${name}.raw" -type f | head -1)
        if [[ -z "${raw_file}" ]]; then
            warn "${name}.raw not found in ${SYSEXT_DIR}"
            continue
        fi
        info "  ${name}.raw → ${VM_IP}:${STAGING}/"
        scp "${SSH_OPTS[@]}" "${raw_file}" "${SSH_USER}@${VM_IP}:${STAGING}/${name}.raw"
        UPLOADED=$((UPLOADED + 1))
    done
    info "Uploaded ${UPLOADED} sysext file(s)"
    if [[ ${UPLOADED} -eq 0 ]]; then
        error "No GPU sysext files found in ${SYSEXT_DIR} — aborting"
        exit 1
    fi
else
    # ── ORAS mode: generate ACR token using dev identity ──────────────────
    # Token generation uses `az acr login` — only ACR login servers are supported.
    OCI_REGISTRY="${OCI_REGISTRY:?OCI_REGISTRY must be set to an ACR login server (e.g., myregistry.azurecr.io)}"
    if [[ "${OCI_REGISTRY}" != *.azurecr.io ]]; then
        error "OCI_REGISTRY must be an Azure Container Registry login server (got: ${OCI_REGISTRY})"
        exit 1
    fi
    ACL_GPU_REPO="${ACL_GPU_REPO:-${OCI_REGISTRY}/azure-container-linux}"
    ACR_NAME="${OCI_REGISTRY%%.*}"
    info "Generating ACR access token for ${OCI_REGISTRY}..."
    ACR_ACCESS_TOKEN=$(az acr login --name "${ACR_NAME}" --expose-token --query accessToken -o tsv)
    VM_ENV="${VM_ENV} ACL_GPU_REPO=${ACL_GPU_REPO} ACR_ACCESS_TOKEN=${ACR_ACCESS_TOKEN}"
    info "ACR token generated, VM will pull ${GPU_DRIVER_SYSEXT} from ${ACL_GPU_REPO}"
fi

# ── Run the GPU sysext smoke test on the VM ──────────────────────────────
info "Running GPU sysext smoke test on VM..."

TEST_SCRIPT="${SCRIPT_DIR:-$(cd "$(dirname "$0")/.." && pwd)/..}/acl/tests/run-gpu-sysext-test.sh"
scp "${SSH_OPTS[@]}" "${TEST_SCRIPT}" "${SSH_USER}@${VM_IP}:/tmp/run-gpu-sysext-test.sh"

# Capture the ssh exit code without tripping `set -e` so we can emit a
# PASS/FAIL summary before propagating the status to the caller.
if ssh "${SSH_OPTS[@]}" "${SSH_USER}@${VM_IP}" \
       "chmod +x /tmp/run-gpu-sysext-test.sh && sudo ${VM_ENV} /tmp/run-gpu-sysext-test.sh"; then
    GPU_EXIT=0
    info "GPU sysext smoke test PASSED"
else
    GPU_EXIT=$?
    error "GPU sysext smoke test FAILED (exit code: ${GPU_EXIT})"
fi

exit ${GPU_EXIT}
