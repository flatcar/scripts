#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Common validation library for Azure Container Linux (ACL) images.
#
# Provides shared globals, logging, SSH helpers, script execution,
# VM lifecycle dispatchers, argument parsing, and the main entry point.
#
# Sourced by validate_rpm_image.sh alongside validate_qemu.sh and validate_azure.sh.
#

# Guard against double-sourcing
[[ -n "${_VALIDATE_COMMON_LOADED:-}" ]] && return 0
_VALIDATE_COMMON_LOADED=1

set -euo pipefail

SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/..}"
cd "${SCRIPT_DIR}"

# ── Default configuration ──────────────────────────────────────────

BOARD="${BOARD:-amd64-usr}"
GROUP="${GROUP:-production}"
IMG_NAME="${IMG_NAME:-acl_production}"
VM_TYPE="${VM_TYPE:-qemu}"
START_VM=false
VM_NAME="${VM_NAME:-acl}"
OUTPUT_ROOT="${OUTPUT_ROOT:-__build__}"
RUN_SCRIPTS=()  # Scripts to run on VM after boot
RUN_HOST_SCRIPTS=()  # Scripts to run on the host (not inside the VM)
SCRIPT_RESULTS_NAMES=()   # Names of scripts that were executed
SCRIPT_RESULTS_STATUS=()  # Exit status per script: 0=pass, non-zero=fail
VM_SSH_USER="${VM_SSH_USER:-azureuser}"
VM_SSH_KEY="${VM_SSH_KEY:-}"
VM_SSH_TIMEOUT="${VM_SSH_TIMEOUT:-120}"  # Seconds to wait for SSH
VM_SSH_AUTHORIZED_KEYS="${VM_SSH_AUTHORIZED_KEYS:-}"  # SSH public keys to inject (file or string)
VM_PASSWORD="${VM_PASSWORD:-}"  # Password for VM user (optional)
USE_SERIAL_CONSOLE="${USE_SERIAL_CONSOLE:-false}"  # Use serial console instead of SSH
VM_CONSOLE_USER="${VM_CONSOLE_USER:-root}"  # Console login user
VM_CONSOLE_PASSWORD="${VM_CONSOLE_PASSWORD:-}"  # Console login password (empty for no password)
# VM boot timeout is arch-dependent: emulated arm64 (TCG) boots far slower than
# native amd64, so it needs a much higher ceiling. The effective value is chosen
# by resolve_boot_timeout() based on BOARD unless VM_BOOT_TIMEOUT / --boot-timeout
# is set explicitly (an explicit value always wins).
VM_BOOT_TIMEOUT_AMD64="${VM_BOOT_TIMEOUT_AMD64:-100}"  # Native boot: seconds to wait
VM_BOOT_TIMEOUT_ARM64="${VM_BOOT_TIMEOUT_ARM64:-300}"  # Emulated boot: seconds to wait
VM_BOOT_TIMEOUT="${VM_BOOT_TIMEOUT:-}"  # Explicit override; empty = auto-select by arch
SECURE_BOOT_ENABLED="${SECURE_BOOT_ENABLED:-true}"  # Enable secure boot
RUN_KOLA_TESTS=false  # Run kola tests (qemu via run_local_tests.sh, azure via run_azure_tests.sh)
ACG_IMAGE_VERSION_ID=""  # Pre-existing Azure Compute Gallery image version resource ID
REUSE_IMAGE=false  # Reuse the latest published gallery image (skip VHD upload)
KEEP_VM=false  # Keep VM running after scripts complete (write state file)
REUSE_VM=false  # Reuse an already-running VM (read state file)
VM_STATE_FILE="${SCRIPT_DIR}/.vm-state.env"  # State file for VM reuse between invocations
VM_IMAGE_PATH=""  # Explicit VM image path (auto-detected if empty)
USE_TEST_IMAGE=false  # Boot the test VM image instead of the regular image
AZ_VM_ARGS="${AZ_VM_ARGS:-}"  # Additional arguments to pass when starting Azure VMs (e.g., for user-data)
export BOOTLOADER_MODE="${BOOTLOADER_MODE:-uki}"

VM_IP=""

# ── Colors / logging ───────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
debug()   { [[ "${DEBUG:-false}" == "true" ]] && echo -e "${BLUE}[DEBUG]${NC} $*" || true; }
section() { echo -e "\n${GREEN}=========================================${NC}"; echo -e "${GREEN}$*${NC}"; echo -e "${GREEN}=========================================${NC}\n"; }

# ── Script results summary ─────────────────────────────────────────

print_script_results_summary() {
    if [[ ${#SCRIPT_RESULTS_NAMES[@]} -eq 0 ]]; then
        return
    fi

    local passed=0 failed=0 total=${#SCRIPT_RESULTS_NAMES[@]}

    for status in "${SCRIPT_RESULTS_STATUS[@]}"; do
        if [[ "$status" -eq 0 ]]; then
            ((passed++)) || true
        else
            ((failed++)) || true
        fi
    done

    echo ""
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN} Script Execution Summary${NC}"
    echo -e "${GREEN}=========================================${NC}"
    printf "  %-50s %s\n" "SCRIPT" "RESULT"
    printf "  %-50s %s\n" "------" "------"

    for i in "${!SCRIPT_RESULTS_NAMES[@]}"; do
        local name="${SCRIPT_RESULTS_NAMES[$i]}"
        local status="${SCRIPT_RESULTS_STATUS[$i]}"
        if [[ "$status" -eq 0 ]]; then
            printf "  %-50s ${GREEN}%s${NC}\n" "$name" "PASSED"
        else
            printf "  %-50s ${RED}%s${NC}\n" "$name" "FAILED"
        fi
    done

    echo -e "  ${GREEN}-----------------------------------------${NC}"
    printf "  Total: %d  |  " "$total"
    if [[ $passed -gt 0 ]]; then
        printf "${GREEN}Passed: %d${NC}  |  " "$passed"
    else
        printf "Passed: %d  |  " "$passed"
    fi
    if [[ $failed -gt 0 ]]; then
        printf "${RED}Failed: %d${NC}\n" "$failed"
    else
        printf "Failed: %d\n" "$failed"
    fi
    echo -e "${GREEN}=========================================${NC}"
    echo ""
}

# ── SDK / TTY helpers ──────────────────────────────────────────────

get_sdk_image() {
    if [[ -n "${ACL_SDK_IMAGE:-}" ]]; then
        echo "${ACL_SDK_IMAGE}"
        return
    fi
    source "${SCRIPT_DIR}/sdk_lib/sdk_container_common.sh"
    local sdk_version
    sdk_version=$(get_sdk_version_from_versionfile)
    local docker_sdk_vernum
    docker_sdk_vernum=$(vernum_to_docker_image_version "$sdk_version")
    echo "${sdk_container_common_registry}/flatcar-sdk-all:${docker_sdk_vernum}"
}

get_tty_flag() {
    if [[ "${NO_TTY:-false}" == "true" ]]; then
        echo ""
    else
        echo "-t"
    fi
}

# ── SSH key helpers ────────────────────────────────────────────────

get_ssh_private_key() {
    if [[ -n "$VM_SSH_KEY" ]]; then
        echo "$VM_SSH_KEY"
        return 0
    fi
    for keyfile in ~/.ssh/id_rsa.pub ~/.ssh/id_ed25519.pub ~/.ssh/id_ecdsa.pub; do
        if [[ -f "$keyfile" ]]; then
            local private_key="${keyfile%.pub}"
            if [[ -f "$private_key" ]]; then
                echo "$private_key"
                return 0
            fi
        fi
    done
    echo ""
    return 1
}

# ── Platform detection ─────────────────────────────────────────────

is_azure_linux_3() {
    [[ -f /etc/os-release ]] && grep -q 'ID=azurelinux' /etc/os-release && grep -q 'VERSION_ID="3' /etc/os-release
}

# ── SSH / connect helpers ──────────────────────────────────────────

wait_for_ssh() {
    local ip="$1"
    local timeout="$2"
    local ssh_opts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -o BatchMode=yes"
    ssh_opts+=" -i $VM_SSH_KEY"
    info "Waiting for SSH to become available on $ip (timeout: ${timeout}s)..."
    local start_time=$(date +%s)
    local end_time=$((start_time + timeout))
    while [[ $(date +%s) -lt $end_time ]]; do
        if ssh $ssh_opts "${VM_SSH_USER}@${ip}" "echo 'SSH ready'" &>/dev/null; then
            info "SSH connection established!"
            return 0
        fi
        sleep 5
    done
    error "Timeout waiting for SSH on $ip"
    return 1
}

connect_vm_ssh() {
    local ip="$1"
    local ssh_opts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    ssh_opts="$ssh_opts -i $VM_SSH_KEY"
    info "Connecting to ${VM_SSH_USER}@${ip}..."
    ssh $ssh_opts "${VM_SSH_USER}@${ip}"
}

# ── Script execution (SSH) ─────────────────────────────────────────

run_scripts_on_vm() {
    local ip="$1"
    shift
    local scripts=("$@")
    local failed=0

    local ssh_opts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"
    ssh_opts+=" -i $VM_SSH_KEY"

    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            info "Running script: $script"
            local remote_script="/tmp/$(basename "$script")"
            if ! scp $ssh_opts "$script" "${VM_SSH_USER}@${ip}:${remote_script}"; then
                error "Failed to copy script: $script"
                SCRIPT_RESULTS_NAMES+=("$script")
                SCRIPT_RESULTS_STATUS+=(1)
                failed=1
                continue
            fi
            if ! ssh $ssh_opts "${VM_SSH_USER}@${ip}" "chmod +x ${remote_script} && sudo ${remote_script}"; then
                error "Script failed: $script"
                SCRIPT_RESULTS_NAMES+=("$script")
                SCRIPT_RESULTS_STATUS+=(1)
                failed=1
            else
                info "Script completed: $script"
                SCRIPT_RESULTS_NAMES+=("$script")
                SCRIPT_RESULTS_STATUS+=(0)
            fi
        elif [[ "$script" == *";"* ]] || [[ "$script" == *"&&"* ]] || [[ "$script" =~ ^[a-zA-Z] ]]; then
            info "Running command: $script"
            if ! ssh $ssh_opts "${VM_SSH_USER}@${ip}" "sudo bash -c '$script'"; then
                error "Command failed: $script"
                SCRIPT_RESULTS_NAMES+=("$script")
                SCRIPT_RESULTS_STATUS+=(1)
                failed=1
            else
                info "Command completed"
                SCRIPT_RESULTS_NAMES+=("$script")
                SCRIPT_RESULTS_STATUS+=(0)
            fi
        else
            warn "Script not found and not a valid command: $script"
            SCRIPT_RESULTS_NAMES+=("$script")
            SCRIPT_RESULTS_STATUS+=(1)
            failed=1
        fi
    done

    return $failed
}

# ── Script execution (serial console — dispatches to platform) ─────

run_scripts_via_console() {
    local vm_name="$1"
    shift
    local scripts=("$@")
    local failed=0

    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            info "Running script via console: $script"
            local script_content
            script_content=$(cat "$script")

            if [[ "$VM_TYPE" == "azure" ]]; then
                if ! run_command_vm_azure "$VM_RG" "$vm_name" "$script_content"; then
                    error "Script failed: $script"
                    SCRIPT_RESULTS_NAMES+=("$script")
                    SCRIPT_RESULTS_STATUS+=(1)
                    failed=1
                else
                    info "✓ Script completed successfully: $script"
                    SCRIPT_RESULTS_NAMES+=("$script")
                    SCRIPT_RESULTS_STATUS+=(0)
                fi
            else
                local encoded
                encoded=$(base64 -w0 "$script")
                local remote_cmd="echo '$encoded' | base64 -d > /tmp/script.sh && chmod +x /tmp/script.sh && /tmp/script.sh; echo \"SCRIPT_EXIT_CODE:\$?\""

                if ! run_command_via_console_qemu "$vm_name" "$remote_cmd" "$VM_CONSOLE_USER" "$VM_CONSOLE_PASSWORD"; then
                    error "Script failed: $script"
                    SCRIPT_RESULTS_NAMES+=("$script")
                    SCRIPT_RESULTS_STATUS+=(1)
                    failed=1
                else
                    info "✓ Script completed successfully: $script"
                    SCRIPT_RESULTS_NAMES+=("$script")
                    SCRIPT_RESULTS_STATUS+=(0)
                fi
            fi
        elif [[ "$script" == *";"* ]] || [[ "$script" == *"&&"* ]] || [[ "$script" =~ ^[a-zA-Z] ]]; then
            if [[ "$VM_TYPE" == "azure" ]]; then
                info "Running command on Azure VM: $script"
                if ! run_command_vm_azure "$VM_RG" "$vm_name" "$script"; then
                    error "Command failed: $script"
                    SCRIPT_RESULTS_NAMES+=("$script")
                    SCRIPT_RESULTS_STATUS+=(1)
                    failed=1
                else
                    info "Command completed"
                    SCRIPT_RESULTS_NAMES+=("$script")
                    SCRIPT_RESULTS_STATUS+=(0)
                fi
            else
                info "Running command via console: $script"
                if ! run_command_via_console_qemu "$vm_name" "$script" "$VM_CONSOLE_USER" "$VM_CONSOLE_PASSWORD"; then
                    error "Command failed: $script"
                    SCRIPT_RESULTS_NAMES+=("$script")
                    SCRIPT_RESULTS_STATUS+=(1)
                    failed=1
                else
                    info "Command completed"
                    SCRIPT_RESULTS_NAMES+=("$script")
                    SCRIPT_RESULTS_STATUS+=(0)
                fi
            fi
        else
            warn "Script not found and not a valid command: $script"
            SCRIPT_RESULTS_NAMES+=("$script")
            SCRIPT_RESULTS_STATUS+=(1)
            failed=1
        fi
    done

    return $failed
}

# ── VM lifecycle dispatchers ───────────────────────────────────────

start_vm() {
    local vm_image_path="$1"
    local board="$2"
    remove_old_vm
    section "Starting a ${VM_TYPE} VM '${VM_NAME}' Board: '${BOARD}'"
    case "$VM_TYPE" in
        qemu)
            start_vm_qemu "$vm_image_path" "$board"
            ;;
        azure)
            start_vm_azure "$vm_image_path"
            ;;
        *)
            error "Unsupported VM type: $VM_TYPE"
            exit 1
            ;;
    esac
}

remove_old_vm() {
    case "$VM_TYPE" in
        qemu)
            info "Removing qemu VM '${VM_NAME}' if present..."
            virsh destroy "${VM_NAME}" 2>/dev/null || true
            virsh undefine --nvram "${VM_NAME}" 2>/dev/null || true
            ;;
        azure)
            remove_vm_azure
            ;;
        *)
            error "Unsupported VM type: $VM_TYPE"
            exit 1
            ;;
    esac
}

# ── VM state persistence ──────────────────────────────────────────

write_vm_state() {
    cat > "$VM_STATE_FILE" <<EOF
VM_IP=${VM_IP}
VM_NAME=${VM_NAME}
VM_TYPE=${VM_TYPE}
EOF
    if [[ "$VM_TYPE" == "azure" ]]; then
        echo "VM_RG=${VM_RG}" >> "$VM_STATE_FILE"
    fi
    info "VM state written to ${VM_STATE_FILE}"
}

read_vm_state() {
    if [[ ! -f "$VM_STATE_FILE" ]]; then
        error "--reuse-vm requires a running VM, but no state file found at ${VM_STATE_FILE}"
        error "Provision a VM first with --keep-vm"
        exit 1
    fi
    # shellcheck disable=SC1090
    source "$VM_STATE_FILE"
    info "Loaded VM state from ${VM_STATE_FILE}"
    info "  IP:   ${VM_IP}"
    info "  Name: ${VM_NAME}"
    info "  Type: ${VM_TYPE}"
    if [[ "$VM_TYPE" == "azure" ]]; then
        info "  RG:   ${VM_RG}"
    fi
}

remove_vm_state() {
    if [[ -f "$VM_STATE_FILE" ]]; then
        rm -f "$VM_STATE_FILE"
        info "Removed VM state file"
    fi
}

# ── Image size summary ────────────────────────────────────────────

print_size_summary() {
    section "Image Size Summary"

    local BUILD_IMAGE_DIR="${OUTPUT_ROOT}/images/images/${BOARD}/latest"
    if [[ -d "${BUILD_IMAGE_DIR}" ]]; then
        info "Build directory: ${BUILD_IMAGE_DIR}"
        echo

        if [[ -f "${BUILD_IMAGE_DIR}/${IMG_NAME}_image.bin" ]]; then
            local usr_size
            usr_size=$(du -h "${BUILD_IMAGE_DIR}/${IMG_NAME}_image.bin" | cut -f1)
            info "USR Image:    ${usr_size}  (${BUILD_IMAGE_DIR}/${IMG_NAME}_image.bin)"
        fi

        if ls "${BUILD_IMAGE_DIR}"/rootfs-included-sysexts/*.raw &>/dev/null; then
            echo
            info "Sysext Images:"
            for sysext in "${BUILD_IMAGE_DIR}"/rootfs-included-sysexts/*.raw; do
                if [[ -f "$sysext" ]]; then
                    local sysext_size sysext_name
                    sysext_size=$(du -h "$sysext" | cut -f1)
                    sysext_name=$(basename "$sysext")
                    info "  - ${sysext_name}: ${sysext_size}"
                fi
            done
        fi

        if [[ -f "${BUILD_IMAGE_DIR}/${IMG_NAME}_image.bin" ]]; then
            echo
            local full_size
            full_size=$(du -h "${BUILD_IMAGE_DIR}/${IMG_NAME}_image.bin" | cut -f1)
            info "Full Image:   ${full_size}  (total disk image)"
        fi
    else
        warn "Build directory not found: ${BUILD_IMAGE_DIR}"
    fi
    echo
}

# ── Cleanup helpers ────────────────────────────────────────────────

cleanup_containers() {
    local filter="${1:-name=flatcar-sdk-}"
    info "Cleaning up old containers..."
    docker ps -a --filter "${filter}" --format "{{.ID}} {{.Names}}" | while read -r id name; do
        info "  Removing container: $name ($id)"
        docker rm -f "$id" 2>/dev/null || true
    done
}

# ── Prerequisites check ───────────────────────────────────────────

check_vm_prerequisites() {
    section "Checking VM Prerequisites"

    local warnings=0

    # Check swtpm on Azure Linux 3 if QEMU VM operations are planned
    # (swtpm is a software TPM emulator, only relevant for QEMU — Azure VMs use hardware vTPM)
    if [[ "$VM_TYPE" == "qemu" ]] && [[ "$START_VM" == "true" ]]; then
        check_swtpm_azure_linux
    fi

    # Check libvirt/virsh when starting a QEMU VM or running kola tests
    if [[ "$VM_TYPE" == "qemu" ]] && ([[ "$START_VM" == "true" ]] || [[ "$RUN_KOLA_TESTS" == "true" ]]); then
        if ! command -v virsh &>/dev/null; then
            error "virsh not found - required for VM operations and kola tests"
            if is_azure_linux_3; then
                error "Install with: sudo tdnf install -y libvirt libvirt-client qemu-kvm"
            else
                error "Install with: sudo apt-get install -y libvirt-clients libvirt-daemon-system qemu-kvm"
            fi
            exit 1
        fi
        info "✓ virsh found"
        if ! ensure_libvirt_network; then
            warnings=$((warnings + 1))
        fi
    fi

    # Check Azure CLI when starting an Azure VM or running azure kola tests
    if [[ "$VM_TYPE" == "azure" ]] && ([[ "$START_VM" == "true" ]] || [[ "$RUN_KOLA_TESTS" == "true" ]]); then
        if ! check_azure_prereqs; then
            error "Azure prerequisites not met"
            exit 1
        fi
        if [[ "$USE_SERIAL_CONSOLE" == "true" ]]; then
            if ! az extension show --name serial-console &>/dev/null 2>&1; then
                info "Installing Azure CLI serial-console extension..."
                if ! az extension add --name serial-console; then
                    error "Failed to install serial-console extension"
                    exit 1
                fi
                info "✓ Azure CLI serial-console extension installed"
            else
                info "✓ Azure CLI serial-console extension found"
            fi
        fi
    fi

    # Check expect when starting a QEMU VM
    if [[ "$START_VM" == "true" ]] && [[ "$VM_TYPE" == "qemu" ]]; then
        if ! command -v expect &>/dev/null; then
            error "expect not found - required for VM serial console automation"
            if is_azure_linux_3; then
                error "Install with: sudo tdnf install -y expect"
            else
                error "Install with: sudo apt-get install -y expect"
            fi
            exit 1
        fi
        info "✓ expect found"
    fi

    # Check SSH key when running kola tests or using SSH for scripts
    if [[ "$RUN_KOLA_TESTS" == "true" ]] || [[ "$USE_SERIAL_CONSOLE" == "false" ]]; then
        local ssh_key_path
        ssh_key_path=$(get_ssh_private_key)
        if [[ -z "$ssh_key_path" || ! -f "$ssh_key_path" ]]; then
            error "SSH private key not found"
            error "Generate one with: ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa"
            error "Or specify with: --ssh-key=PATH"
            exit 1
        fi
        if [[ ! -f "${ssh_key_path}.pub" ]]; then
            error "SSH public key not found at: ${ssh_key_path}.pub"
            exit 1
        fi
        VM_SSH_KEY="$ssh_key_path"
        info "✓ SSH key found at $ssh_key_path"
    fi

    if [[ $warnings -gt 0 ]]; then
        warn "$warnings warning(s) detected - some operations may fail"
        echo
    fi

    info "✓ VM prerequisites met"
}

# ── VM image path resolution ─────────────────────────────────────

# Resolve the VM image path from VM_IMAGE_PATH, USE_TEST_IMAGE, and VM_TYPE.
# Prints the resolved path to stdout.
resolve_vm_image_path() {
    if [[ -n "$VM_IMAGE_PATH" ]]; then
        echo "$VM_IMAGE_PATH"
        return
    fi
    local suffix="image"
    [[ "$USE_TEST_IMAGE" == "true" ]] && suffix="test_image"
    case "$VM_TYPE" in
        qemu)  echo "__build__/images/images/${BOARD}/latest/${IMG_NAME}_qemu_uefi_${suffix}.img" ;;
        azure) echo "__build__/images/images/${BOARD}/latest/${IMG_NAME}_azure_${suffix}.vhd" ;;
    esac
}

# ── Argument parsing ──────────────────────────────────────────────

parse_validate_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --board=*)
                BOARD="${1#*=}"
                shift ;;
            --img-name=*)
                IMG_NAME="${1#*=}"
                shift ;;
            --vm-type=*)
                VM_TYPE="${1#*=}"
                if [[ "$VM_TYPE" != "azure" ]] && [[ "$VM_TYPE" != "qemu" ]]; then
                    error "Invalid VM type: $VM_TYPE (must be 'azure' or 'qemu')"
                    exit 1
                fi
                shift ;;
            --start-vm)
                START_VM=true
                shift ;;
            --vm-name=*)
                VM_NAME="${1#*=}"
                shift ;;
            --vm-image-path=*)
                VM_IMAGE_PATH="${1#*=}"
                shift ;;
            --use-test-image)
                USE_TEST_IMAGE=true
                shift ;;
            --run-script=*)
                RUN_SCRIPTS+=("${1#*=}")
                START_VM=true
                shift ;;
            --run-script)
                RUN_SCRIPTS+=("$2")
                START_VM=true
                shift 2 ;;
            --run-host-script=*)
                RUN_HOST_SCRIPTS+=("${1#*=}")
                START_VM=true
                shift ;;
            --run-host-script)
                RUN_HOST_SCRIPTS+=("$2")
                START_VM=true
                shift 2 ;;
            --ssh-user=*)
                VM_SSH_USER="${1#*=}"
                shift ;;
            --ssh-key=*)
                VM_SSH_KEY="${1#*=}"
                shift ;;
            --ssh-timeout=*)
                VM_SSH_TIMEOUT="${1#*=}"
                shift ;;
            --ssh-authorized-keys=*)
                VM_SSH_AUTHORIZED_KEYS="${1#*=}"
                shift ;;
            --use-serial)
                USE_SERIAL_CONSOLE=true
                shift ;;
            --use-ssh)
                USE_SERIAL_CONSOLE=false
                shift ;;
            --console-user=*)
                VM_CONSOLE_USER="${1#*=}"
                shift ;;
            --console-password=*)
                VM_CONSOLE_PASSWORD="${1#*=}"
                shift ;;
            --boot-timeout=*)
                VM_BOOT_TIMEOUT="${1#*=}"
                shift ;;
            --keep-vm)
                KEEP_VM=true
                NO_CLEANUP=true
                shift ;;
            --reuse-vm)
                REUSE_VM=true
                START_VM=true
                NO_CLEANUP=true
                shift ;;
            --reuse-image)
                REUSE_IMAGE=true
                START_VM=true
                shift ;;
            --no-cleanup)
                NO_CLEANUP=true
                shift ;;
            --run-kola-tests)
                RUN_KOLA_TESTS=true
                shift ;;
            --tag=*)
                RESOURCE_TAGS+=("${1#*=}")
                shift ;;
            --acg-gallery-name=*)
                AZ_ACG="${1#*=}"
                shift ;;
            --acg-image-version-id=*)
                ACG_IMAGE_VERSION_ID="${1#*=}"
                START_VM=true
                shift ;;
            --az-storage-account=*)
                AZ_STORAGE_ACC="${1#*=}"
                shift ;;
            --az-sub-id=*)
                AZ_SUB_ID="${1#*=}"
                shift ;;
            --az-region=*)
                AZ_REGION="${1#*=}"
                shift ;;
            --az-vm-size=*)
                AZ_VM_SIZE="${1#*=}"
                shift ;;
            --az-backup-regions=*)
                AZ_BACKUP_REGIONS="${1#*=}"
                shift ;;
            --az-storage-rg=*)
                AZ_STORAGE_RG="${1#*=}"
                shift ;;
            --az-gallery-rg=*)
                AZ_GALLERY_RG="${1#*=}"
                shift ;;
            --az-vm-image-def=*)
                AZ_VM_IMAGE_DEF="${1#*=}"
                shift ;;
            --az-storage-container=*)
                AZ_STORAGE_CONTAINER="${1#*=}"
                shift ;;
            --build-id=*)
                BUILD_ID="${1#*=}"
                shift ;;
            --az-vm-args=*)
                AZ_VM_ARGS="${1#*=}"
                shift ;;
            --no-secure-boot)
                SECURE_BOOT_ENABLED=false
                shift ;;
            --help)
                echo "Usage: $0 [options]"
                echo ""
                echo "Validate an ACL image by starting a VM and running test scripts."
                echo ""
                echo "Options:"
                echo "  --board=BOARD              Target board (default: amd64-usr)"
                echo "  --boot-timeout=SECS        Timeout waiting for VM boot (default: arch-based — amd64 ${VM_BOOT_TIMEOUT_AMD64}s, arm64 ${VM_BOOT_TIMEOUT_ARM64}s)"

                echo "  --console-password=PASS    Serial console login password"
                echo "  --console-user=USER        Serial console login user (default: root)"
                echo "  --help                     Show this help message"
                echo "  --img-name=NAME            Image name prefix (default: acl_production)"
                echo "  --keep-vm                  Keep VM running after scripts complete"
                echo "  --no-cleanup               Skip cleanup of existing VM resource groups"
                echo "  --reuse-image              Reuse the latest published gallery image (skip VHD upload)"
                echo "  --reuse-vm                 Reuse an already-running VM"
                echo "  --run-kola-tests           Run kola tests"
                echo "  --run-script=PATH          Run script on VM (can specify multiple)"
                echo "  --run-host-script=PATH     Run script on the host with VM state (can specify multiple)"
                echo "  --ssh-key=PATH             SSH private key for VM access"
                echo "  --ssh-timeout=SECS         Timeout waiting for SSH (default: 120)"
                echo "  --ssh-user=USER            SSH user (default: core)"
                echo "  --start-vm                 Start the VM"
                echo "  --tag=KEY=VALUE            Add a resource tag"
                echo "  --use-serial               Use serial console"
                echo "  --use-ssh                  Use SSH"
                echo "  --use-test-image           Boot the test VM image (with docker sysext)"
                echo "  --vm-image-path=PATH       Path to VM image"
                echo "  --az-vm-args=ARGS          Additional arguments to pass when starting Azure VMs"
                echo "  --vm-name=NAME             VM name (default: acl)"
                echo "  --vm-type=TYPE             VM type: azure|qemu (default: qemu)"
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    if [[ "$START_VM" == "true" ]] && [[ "$REUSE_VM" != "true" ]]; then
        local auto_vm_path
        auto_vm_path="$(resolve_vm_image_path)"
        # Don't auto-build if image already exists or using ACG image
        if [[ -n "${ACG_IMAGE_VERSION_ID}" ]] || [[ "${REUSE_IMAGE}" == "true" ]] || [[ -f "$auto_vm_path" ]]; then
            : # Image exists or using gallery image, no need to build
        fi
    fi
}

# ── Main entry point ──────────────────────────────────────────────

# Select an arch-appropriate VM boot timeout when the caller hasn't pinned one.
# Emulated arm64 boots take far longer than native amd64; a single fixed timeout
# is either too tight for arm64 (flaky boot failures) or wastefully loose for amd64.
resolve_boot_timeout() {
    [[ -n "${VM_BOOT_TIMEOUT}" ]] && return 0  # explicit env / --boot-timeout wins

    local arch="${BOARD%%-*}"  # arm64-usr -> arm64, amd64-usr -> amd64
    case "$arch" in
        arm64|aarch64) VM_BOOT_TIMEOUT="${VM_BOOT_TIMEOUT_ARM64}" ;;
        *)             VM_BOOT_TIMEOUT="${VM_BOOT_TIMEOUT_AMD64}" ;;
    esac
    info "Using VM boot timeout for ${arch}: ${VM_BOOT_TIMEOUT}s"
}

validate_main() {
    parse_validate_args "$@"
    resolve_boot_timeout

    # Source platform module now that VM_TYPE is known from arg parsing
    case "$VM_TYPE" in
        qemu)
            # shellcheck source=acl/validate/validate_qemu.sh
            source "${_VALIDATE_MODULE_DIR}/validate_qemu.sh"
            ;;
        azure)
            # shellcheck source=acl/validate/validate_azure.sh
            source "${_VALIDATE_MODULE_DIR}/validate_azure.sh"
            resolve_azure_defaults
            ;;
    esac

    section "Azure Container Linux Image Validator"

    # Load VM state early so check_vm_prerequisites validates the correct VM_TYPE
    if [[ "$REUSE_VM" == "true" ]]; then
        read_vm_state
    fi

    check_vm_prerequisites

    # Resolve VM image path
    local vm_image_path
    vm_image_path="$(resolve_vm_image_path)"

    # Start VM and run scripts / connect interactively
    if [[ "$START_VM" == "true" ]]; then

        if [[ "$REUSE_VM" == "true" ]]; then
            # Re-fetch IP if state file had an empty IP (written before boot completed)
            if [[ -z "${VM_IP:-}" ]] && [[ "$VM_TYPE" == "qemu" ]]; then
                info "VM_IP empty in state file — re-fetching from libvirt..."
                if wait_for_vm_ip_qemu "${VM_NAME}" 30; then
                    info "Re-fetched VM IP: $VM_IP"
                    write_vm_state
                else
                    error "Could not re-fetch VM IP. SSH execution requires a valid IP."
                    exit 1
                fi
            fi
            # Verify VM is still running before proceeding
            if [[ "$VM_TYPE" == "qemu" ]]; then
                local vm_state
                vm_state=$(virsh domstate "${VM_NAME}" 2>/dev/null || echo "unknown")
                if [[ "$vm_state" != "running" ]]; then
                    error "VM '${VM_NAME}' is not running (state: $vm_state). Cannot reuse."
                    exit 1
                fi
                info "VM '${VM_NAME}' is running — reusing"
            fi
        else
            if [[ -n "${ACG_IMAGE_VERSION_ID}" ]] && [[ "$VM_TYPE" == "azure" ]]; then
                info "Using pre-existing ACG image version — skipping local image check"
            elif [[ "${REUSE_IMAGE}" == "true" ]] && [[ "$VM_TYPE" == "azure" ]]; then
                info "Reusing latest gallery image — skipping local image check"
            elif ! [[ -f "$vm_image_path" ]]; then
                error "VM image not found at expected path: $vm_image_path"
                error "Build a VM image first with '--build-vm-image'"
                exit 1
            fi

            start_vm "${vm_image_path}" "${BOARD}"

            # Write VM state for reuse by subsequent --reuse-vm invocations
            if [[ "$KEEP_VM" == "true" ]]; then
                write_vm_state
            fi
        fi

        # Run scripts on VM
        if [[ ${#RUN_SCRIPTS[@]} -gt 0 ]]; then
            section "Running Scripts on VM"

            if [[ "$USE_SERIAL_CONSOLE" == "true" ]]; then
                info "Using serial console for script execution"

                if [[ "$VM_TYPE" == "qemu" ]] && [[ "$REUSE_VM" != "true" ]]; then
                    info "Waiting for QEMU VM to boot..."
                    if ! wait_for_vm_boot_qemu "${VM_NAME}" "$VM_BOOT_TIMEOUT"; then
                        error "VM failed to boot within timeout"
                        exit 1
                    fi
                fi

                if run_scripts_via_console "${VM_NAME}" "${RUN_SCRIPTS[@]}"; then
                    print_script_results_summary
                    info "All scripts completed successfully!"
                else
                    print_script_results_summary
                    error "One or more scripts failed"
                    exit 1
                fi
            else
                info "Using SSH for script execution"

                if [[ "$VM_TYPE" == "qemu" ]] && [[ "$REUSE_VM" != "true" ]]; then
                    info "Waiting for QEMU VM to boot..."
                    if ! wait_for_vm_boot_qemu "${VM_NAME}" "$VM_BOOT_TIMEOUT"; then
                        error "VM failed to boot within timeout"
                        exit 1
                    fi
                    if ! wait_for_vm_ip_qemu "${VM_NAME}" 60; then
                        warn "You can still connect manually: virsh console ${VM_NAME}"
                        exit 1
                    fi
                fi

                if wait_for_ssh "$VM_IP" "$VM_SSH_TIMEOUT"; then
                    if run_scripts_on_vm "$VM_IP" "${RUN_SCRIPTS[@]}"; then
                        print_script_results_summary
                        info "All scripts completed successfully!"
                    else
                        print_script_results_summary
                        error "One or more scripts failed"
                        exit 1
                    fi
                else
                    error "SSH not available - cannot run scripts"
                    warn "Try using --use-serial for serial console execution"
                    warn "You can still connect manually:"
                    if [[ "$VM_TYPE" == "qemu" ]]; then
                        warn "  virsh console ${VM_NAME}"
                    else
                        warn "  az vm run-command invoke --command-id RunShellScript --name ${VM_NAME} --resource-group ${VM_RG} --scripts 'echo Hello'"
                    fi
                fi
            fi
            # Nginx curl test for container test (QEMU only)
            if [[ "$VM_TYPE" != "azure" ]] && [[ ${#RUN_SCRIPTS[@]} -gt 0 ]] && [[ "${RUN_SCRIPTS[-1]}" == *"run-container-test.sh" ]]; then
                if [[ -z "${VM_IP:-}" ]]; then
                    VM_IP=$(get_vm_ip_qemu "${VM_NAME}")
                fi
                # Verify nginx responds (any HTTP response proves the container runtime works)
                curl --connect-timeout 10 --max-time 30 --silent --output /dev/null --write-out '%{http_code}' http://$VM_IP | grep -q "^[2-4]"
            fi
            print_size_summary
        fi

        # Run host-side scripts (e.g. tests that need to orchestrate from outside the VM)
        if [[ ${#RUN_HOST_SCRIPTS[@]} -gt 0 ]]; then
            # Ensure state file exists so host scripts can read VM info.
            # Write it temporarily if --keep-vm was not specified.
            local _wrote_tmp_state=false
            if [[ ! -f "$VM_STATE_FILE" ]]; then
                write_vm_state
                _wrote_tmp_state=true
            fi

            section "Running Host-Side Scripts"
            local host_failed=0
            for script in "${RUN_HOST_SCRIPTS[@]}"; do
                info "Running host script: $script"
                local host_args=("--vm-type=${VM_TYPE}" "--ssh-user=${VM_SSH_USER}")
                [[ -n "${VM_SSH_KEY:-}" ]] && host_args+=("--ssh-key=${VM_SSH_KEY}")
                if SCRIPT_DIR="${SCRIPT_DIR}" bash "$script" "${host_args[@]}"; then
                    info "Host script completed: $script"
                    SCRIPT_RESULTS_NAMES+=("$script")
                    SCRIPT_RESULTS_STATUS+=(0)
                else
                    error "Host script failed: $script"
                    SCRIPT_RESULTS_NAMES+=("$script")
                    SCRIPT_RESULTS_STATUS+=(1)
                    host_failed=1
                fi
            done

            # Clean up temporary state file
            if [[ "$_wrote_tmp_state" == "true" ]]; then
                remove_vm_state
            fi

            if [[ $host_failed -ne 0 ]]; then
                print_script_results_summary
                error "One or more host scripts failed"
                exit 1
            fi
            print_script_results_summary
            info "All host scripts completed successfully!"
        fi

        if [[ ${#RUN_SCRIPTS[@]} -eq 0 ]] && [[ ${#RUN_HOST_SCRIPTS[@]} -eq 0 ]]; then
            # No scripts — interactive mode
            if [[ "$VM_TYPE" == "qemu" ]]; then
                echo
                info "Waiting for VM to boot (showing console output)..."
                if ! wait_for_vm_boot_qemu "${VM_NAME}" "$VM_BOOT_TIMEOUT"; then
                    warn "Boot detection timed out"
                fi
                if ! wait_for_vm_ip_qemu "${VM_NAME}" 60; then
                    error "Could not get VM IP"
                    exit 1
                fi
            fi

            if [[ "$USE_SERIAL_CONSOLE" == "true" ]]; then
                if [[ "$VM_TYPE" == "qemu" ]]; then
                    connect_vm_console_qemu "${VM_NAME}"
                elif [[ "$VM_TYPE" == "azure" ]]; then
                    connect_vm_console_azure "$VM_RG" "${VM_NAME}"
                fi
            else
                info "VM is ready! Connecting via SSH..."
                if [[ "$VM_TYPE" == "qemu" ]]; then
                    if wait_for_vm_ip_qemu "${VM_NAME}" 60 && wait_for_ssh "$VM_IP" "$VM_SSH_TIMEOUT"; then
                        connect_vm_ssh "$VM_IP"
                    else
                        warn "SSH not available, falling back to console"
                        connect_vm_console_qemu "${VM_NAME}"
                    fi
                elif [[ "$VM_TYPE" == "azure" ]]; then
                    if [[ -n "${VM_IP:-}" ]] && wait_for_ssh "$VM_IP" "$VM_SSH_TIMEOUT"; then
                        connect_vm_ssh "$VM_IP"
                    else
                        warn "SSH not available, falling back to console"
                        connect_vm_console_azure "$VM_RG" "${VM_NAME}"
                    fi
                fi
            fi
        fi

    elif [[ "$VM_TYPE" == "qemu" ]]; then
        echo
        info "To deploy to libvirt, run:"
        echo "  virsh destroy ${VM_NAME} || true"
        echo "  virsh undefine --nvram ${VM_NAME} || true"
        echo "  virt-install --name ${VM_NAME} --memory 2048 --vcpus 2 --os-variant generic --import --disk ${vm_image_path} --network default --machine q35 --boot uefi --noautoconsole"
        echo "  virsh console ${VM_NAME}"
    else
        echo
        info "To deploy to Azure, run:"
        echo "  az vm create --resource-group <rg-name> --name <vm-name> --image <image-id> --admin-username <username> --ssh-key-values <ssh-key-file> --size Standard_D2s_v5 --security-type TrustedLaunch --enable-secure-boot true --enable-vtpm true"
        echo "  az vm boot-diagnostics enable --name <vm-name> --resource-group <rg-name>"
        echo "  az vm show -d -g <rg-name> -n <vm-name> --query publicIps -o tsv"
    fi

    # Run kola tests if requested
    if [[ "$RUN_KOLA_TESTS" == "true" ]]; then
        section "Running Kola Tests"
        cleanup_containers "name=flatcar-tests-"
        local kola_arch="${BOARD%%-*}"  # arm64-usr → arm64, amd64-usr → amd64
        if [[ "$VM_TYPE" == "azure" ]]; then
            info "Running kola tests via run_azure_tests.sh (arch=${kola_arch})..."
            if "${SCRIPT_DIR}/run_azure_tests.sh" "${kola_arch}"; then
                info "Azure kola tests completed successfully!"
            else
                error "Azure kola tests failed"
                exit 1
            fi
        else
            info "Running kola tests via run_local_tests.sh (arch=${kola_arch})..."
            if "${SCRIPT_DIR}/run_local_tests.sh" "${kola_arch}"; then
                info "Kola tests completed successfully!"
            else
                error "Kola tests failed"
                exit 1
            fi
        fi
    fi
}
