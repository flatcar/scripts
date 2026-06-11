#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Build Azure Container Linux (ACL) Image - Complete workflow
#
# This script builds an Azure Container Linux (ACL) image using Azure Linux RPMs and Flatcar SDK container.
#
# Usage:
#   ./build_rpm_image.sh [options]
#
# Options:
#   --acg-gallery-name=NAME              Azure Compute Gallery name to override default (for start-vm --vm-type=azure)
#   --acg-image-version-id=ID            Azure Compute Gallery image version resource ID. When set,
#                                        skip VHD upload and image creation; use this image directly
#                                        (for start-vm --vm-type=azure)
#   --az-storage-account=NAME            Azure storage account name to override default (for start-vm --vm-type=azure)
#   --az-storage-container=NAME          Azure storage container name for VHDs (for start-vm --vm-type=azure)
#   --az-storage-rg=NAME                 Resource group containing the storage account (for start-vm --vm-type=azure)
#   --az-gallery-rg=NAME                 Resource group containing the Azure Compute Gallery (for start-vm --vm-type=azure)
#   --az-sub-id=ID                       Azure subscription ID to override default (for start-vm --vm-type=azure)
#   --az-region=REGION                   Azure region to override default (for start-vm --vm-type=azure)
#   --az-vm-size=SIZE                    Azure VM size (default: Standard_D2s_v5)
#   --board=BOARD                        Target board (default: amd64-usr)
#   --boot-timeout=SECS                  Timeout waiting for VM boot (default: 180)
#   --build-rpms                         Build custom RPM packages using Azure Linux toolkit (runs acl/build.sh)
#   --build-sdk-container                Update/rebuild SDK container with RPM tools (can run standalone)
#   --build-standalone-sysexts[=TAG,...]  Build standalone sysexts (all, or only those matching any given tag)
#   --build-test-image                   Build a test VM image (includes docker sysext) for kola testing
#   --build-vm-image                     Build VM images after creating base image (no docker sysext)
#   --clean                              Clean staging and build RPM directories before download
#   --console-password=PASS              Serial console login password (empty for passwordless)
#   --console-user=USER                  Serial console login user (default: root)
#   --download-rpms                      [no-op] Kept for pipeline compatibility
#   --group=GROUP                        Image group: developer|production|prod (default: production)
#   --help                               Show this help message
#   --img-name=NAME                      Base image name prefix (default: acl_production)
#                                        Final image will be NAME_image.bin, VM image will be NAME_qemu_uefi_image.img
#   --keep-vm                            Keep VM running after scripts complete (write state to .vm-state.env)
#   --no-cleanup                         Skip cleanup of existing VM resource groups (for start-vm --vm-type=azure)
#   --output=DIR                         Output directory for images
#   --reuse-vm                           Reuse an already-running VM (reads IP/RG from .vm-state.env)
#   --tag=KEY=VALUE                      Add a resource tag to Azure VMs/RGs (can specify multiple times)
#                                        Default tag: createdBy=<current user>
#   --rebuild                            Force rebuild even if image exists
#   --retry=N                            Retry build steps up to N times with exponential backoff
#                                        (default backoff: 15s initial, 5min max). Clears intermediate
#                                        build caches between retries but preserves toolchain, azurelinux
#                                        clone, and rpm-staging.
#   --rebuild-and-test                   Rebuild image and run smoke tests (equivalent to
#                                        --rebuild --build-vm-image --run-tests)
#   --run-tests                          Start a VM and run a series of predefined tests on the VM after boot
#                                        (includes run-secureboot-test.sh, run-container-test.sh,
#                                        run-systemd-health-test.sh, run-dmesg-io-error-test.sh,
#                                        run-selinux-avc-test.sh)
#   --run-script=PATH                    Run script on VM after boot (can specify multiple times)
#                                        Can be a file path or inline command. Implies --start-vm
#   --run-kola-tests                     Run kola tests after building (qemu or azure, based on --vm-type)
#   --ssh-authorized-keys=KEYS           SSH public keys for VM access (file path or key string)
#   --skip-standalone-sysexts            Skip building standalone sysexts (to speed up rebuilds)
#   --ssh-key=PATH                       SSH private key for VM access
#   --ssh-timeout=SECS                   Timeout waiting for SSH (default: 120)
#   --ssh-user=USER                      SSH user for VM scripts (default: core)
#   --start-vm                           Start the VM after building (implies --build-vm-image)
#   --use-serial                         Use serial console for script execution (no SSH/ignition needed)
#   --use-ssh                            Use SSH for script execution (default, requires working ignition/SSH keys)
#   --use-test-image                     Boot the test VM image (with docker sysext) instead of the regular image
#   --vm-name=NAME                       Name for the VM (default: acl)
#   --vm-type=TYPE                       VM type when building VM images: azure|qemu (default: qemu)
#   --az-vm-args=ARGS                    Additional arguments to pass to vm start command, esp azure vms
#                                        Space separated list ('--az-vm-args="<key><space><value><space>"')
#                                        ex: --az-vm-args="--user-data <path-to-ignition-file> --enable-vtpm true"
#
# Examples:
#   # Build and run a test script on the VM via serial console
#   ./build_rpm_image.sh --run-script=./tests/smoke_test.sh
#
#   # Run inline command via serial console
#   ./build_rpm_image.sh --run-script="cat /etc/os-release"
#
#   # Run multiple scripts
#   ./build_rpm_image.sh --run-script=./setup.sh --run-script=./test.sh
#
#   # Use SSH instead of serial console (requires ignition/SSH setup)
#   ./build_rpm_image.sh --use-ssh --run-script="systemctl status docker"
#
#   # Run with specific console user
#   ./build_rpm_image.sh --console-user=core --run-script="whoami"
#
# Environment Variables:
#   ACL_SDK_IMAGE           Override SDK container image (e.g., <your-registry>/sdk:<release>)
#                           Bypasses auto-detection from version.txt when set
#   NO_TTY                  Set to "true" to disable TTY allocation (for CI pipelines)
#   RPM_REPO_URL            Azure Linux repository URL
#   RPM_ARCH                Target architecture (default: x86_64)
#   BUILD_ID                Build identifier for versioning
#   USE_SERIAL_CONSOLE      Use serial console (true) or SSH (false) - default: true
#   VM_CONSOLE_USER         Serial console login user (default: root)
#   VM_CONSOLE_PASSWORD     Serial console login password
#   VM_BOOT_TIMEOUT         Boot timeout in seconds (default: 180)
#   VM_SSH_KEY              SSH private key path
#   VM_SSH_TIMEOUT          SSH connection timeout in seconds (default: 120)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

# Auto-source internal environment config if present (gitignored)
if [[ -f "${SCRIPT_DIR}/acl/acl.internal.env" ]]; then
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/acl/acl.internal.env"
fi

# shellcheck source=../build_library/retry_with_backoff.sh
source "${SCRIPT_DIR}/build_library/retry_with_backoff.sh"
source "${SCRIPT_DIR}/build_library/standalone_sysext_util.sh"
cd "${SCRIPT_DIR}"

# Default configuration
BOARD="${BOARD:-amd64-usr}"
GROUP="${GROUP:-production}"
BUILD_SDK_CONTAINER=false
BUILD_RPMS=false
CLEAN_DIRS=false
FORCE_REBUILD=false
BUILD_IMAGE=false
IMG_NAME="${IMG_NAME:-acl_production}"
BUILD_VM_IMAGE=false
VM_TYPE="${VM_TYPE:-qemu}"
START_VM=false
VM_NAME="${VM_NAME:-acl}"
OUTPUT_ROOT="${OUTPUT_ROOT:-__build__}"
STAGING_DIR="${SCRIPT_DIR}/__build__/rpm-staging"
DISK_LAYOUT="${DISK_LAYOUT:-vm}"  # Use 'vm' layout for larger ROOT partition (needed for RPM mode)
RUN_SCRIPTS=()  # Scripts to run on VM after boot
RUN_HOST_SCRIPTS=()  # Scripts to run on the host (not inside the VM)
VM_SSH_KEY="${VM_SSH_KEY:-}"
VM_SSH_TIMEOUT="${VM_SSH_TIMEOUT:-120}"  # Seconds to wait for SSH
VM_SSH_AUTHORIZED_KEYS="${VM_SSH_AUTHORIZED_KEYS:-}"  # SSH public keys to inject (file or string)
VM_PASSWORD="${VM_PASSWORD:-}"  # Password for VM user (optional)
USE_SERIAL_CONSOLE="${USE_SERIAL_CONSOLE:-false}"  # Use serial console instead of SSH
VM_CONSOLE_USER="${VM_CONSOLE_USER:-root}"  # Console login user
VM_CONSOLE_PASSWORD="${VM_CONSOLE_PASSWORD:-}"  # Console login password (empty for no password)
VM_BOOT_TIMEOUT="${VM_BOOT_TIMEOUT:-180}"  # Seconds to wait for VM boot
RUN_KOLA_TESTS=false  # Run kola tests (qemu via run_local_tests.sh, azure via run_azure_tests.sh)
ACG_IMAGE_VERSION_ID=""  # Pre-existing Azure Compute Gallery image version resource ID (bypasses VHD upload)
REUSE_IMAGE=false  # Reuse the latest published gallery image (skip VHD upload)
KEEP_VM=false  # Keep VM running after scripts complete (write state file)
REUSE_VM=false  # Reuse an already-running VM (read state file)
BUILD_STANDALONE_SYSEXTS=false  # Build standalone sysexts: false, true (all), or comma-separated tags to filter
STANDALONE_SYSEXTS_TAG=""      # Optional tag filter for --build-standalone-sysexts=TAG,TAG,...
BUILD_TEST_IMAGE=false  # Build a test VM image with docker sysext for kola testing
USE_TEST_IMAGE=false  # Boot the test VM image instead of the regular image
AZ_VM_ARGS="${AZ_VM_ARGS:-}"  # Additional arguments to pass to start azure VM

# Sysext definitions — maintained in a YAML config for easy extension.
# See acl/sysexts.yaml for schema, arch support, and how-to-add.
SYSEXTS_YAML="${SCRIPT_DIR}/acl/sysexts.yaml"
RETRY_ATTEMPTS=0  # Number of retry attempts (0 = no retry)

# Set envi var-s required for RPM mode
export PACKAGE_SOURCE_MODE=RPM
export RPM_STAGING_DIR="${STAGING_DIR}"
# Bootloader mode: 'uki' (default, systemd-boot + UKI) or 'grub'
export BOOTLOADER_MODE="${BOOTLOADER_MODE:-uki}"
# Forward ACL version overrides into run_sdk_container → docker container
export IMAGE_VERSION="${IMAGE_VERSION:-}"
export IMAGE_VERSION_ID="${IMAGE_VERSION_ID:-}"
export IMAGE_BUILD_ID="${IMAGE_BUILD_ID:-}"
# Extra kernel cmdline args baked into a UKI debug addon (e.g., for boot profiling)
export EXTRA_KERNEL_CMDLINE="${EXTRA_KERNEL_CMDLINE:-}"

# Pipeline build identifier — used for deterministic gallery image versions in CI.
BUILD_ID="${BUILD_ID:-}"

# Tags applied to Azure resources (VMs, RGs, public IPs) for identification and cleanup.
RESOURCE_TAGS=("createdBy=$(whoami)")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
debug()   { [[ "${DEBUG:-false}" == "true" ]] && echo -e "${BLUE}[DEBUG]${NC} $*" || true; }
section() { echo -e "\n${GREEN}=========================================${NC}"; echo -e "${GREEN}$*${NC}"; echo -e "${GREEN}=========================================${NC}\n"; }

# Get SDK container image to use for builds
# If ACL_SDK_IMAGE is set, use it directly (allows CI to specify pre-built SDK)
# Otherwise, auto-detect from version.txt
get_sdk_image() {
    if [[ -n "${ACL_SDK_IMAGE:-}" ]]; then
        echo "${ACL_SDK_IMAGE}"
        return
    fi

    # Auto-detect from version.txt
    source "${SCRIPT_DIR}/sdk_lib/sdk_container_common.sh"
    local sdk_version
    sdk_version=$(get_sdk_version_from_versionfile)
    local docker_sdk_vernum
    docker_sdk_vernum=$(vernum_to_docker_image_version "$sdk_version")
    echo "${sdk_container_common_registry}/flatcar-sdk-all:${docker_sdk_vernum}"
}

# Get TTY flag for run_sdk_container
# Returns "-t" for local dev (TTY available), empty for CI pipelines
get_tty_flag() {
    if [[ "${NO_TTY:-false}" == "true" ]]; then
        echo ""
    else
        echo "-t"
    fi
}

# Detect if running on Azure Linux 3
is_azure_linux_3() {
    [[ -f /etc/os-release ]] && grep -q 'ID=azurelinux' /etc/os-release && grep -q 'VERSION_ID="3' /etc/os-release
}

# Show usage information
show_help() {
    head -30 "$0" | grep -E "^#" | sed 's/^# *//'
    exit 0
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --board=*)
                BOARD="${1#*=}"
                shift
                ;;
            --board)
                BOARD="$2"
                shift 2
                ;;
            --group=*)
                GROUP="${1#*=}"
                shift
                ;;
            --group)
                GROUP="$2"
                shift 2
                ;;
            --img-name=*)
                IMG_NAME="${1#*=}"
                shift
                ;;
            --img-name)
                IMG_NAME="$2"
                shift 2
                ;;
            --build-sdk-container)
                BUILD_SDK_CONTAINER=true
                shift
                ;;
            --build-rpms)
                BUILD_RPMS=true
                shift
                ;;
            --build-rpms-qemu|--build-rpms-edk2-aarch64)
                # Deprecated: edk2 and qemu are now installed from PMC.
                echo "WARNING: $1 is deprecated. edk2/qemu packages are now installed from PMC repos."
                shift
                ;;
            --download-rpms)
                # no-op: kept for pipeline compatibility
                shift
                ;;
            --clean)
                CLEAN_DIRS=true
                shift
                ;;
            --retry)
                if [[ $# -lt 2 ]]; then
                    error "--retry requires a value (number of attempts)"
                    exit 1
                fi
                RETRY_ATTEMPTS="$2"
                shift 2
                ;;
            --retry=*)
                RETRY_ATTEMPTS="${1#*=}"
                shift
                ;;
            --rebuild)
                FORCE_REBUILD=true
                BUILD_IMAGE=true
                shift
                ;;
            --rebuild-and-test)
                FORCE_REBUILD=true
                BUILD_IMAGE=true
                BUILD_VM_IMAGE=true
                # Passthrough
                ;&
            --run-tests)
                START_VM=true
                RUN_TESTS=true
                RUN_SCRIPTS+=("./acl/tests/run-secureboot-test.sh")
                RUN_SCRIPTS+=("./acl/tests/run-container-test.sh")
                RUN_SCRIPTS+=("./acl/tests/run-systemd-health-test.sh")
                RUN_SCRIPTS+=("./acl/tests/run-dmesg-io-error-test.sh")
                RUN_SCRIPTS+=("./acl/tests/run-selinux-avc-test.sh")
                shift
                ;;
            --build-image)
                BUILD_IMAGE=true
                shift
                ;;
            --build-vm-image)
                BUILD_VM_IMAGE=true
                shift
                ;;
            --build-test-image)
                BUILD_TEST_IMAGE=true
                shift
                ;;
            --use-test-image)
                USE_TEST_IMAGE=true
                shift
                ;;
            --vm-type=*)
                VM_TYPE="${1#*=}"
                shift
                ;;
            --vm-type)
                VM_TYPE="$2"
                shift 2
                ;;
            --start-vm)
                START_VM=true
                shift
                ;;
            --vm-name=*)
                VM_NAME="${1#*=}"
                shift
                ;;
            --vm-name)
                VM_NAME="$2"
                shift 2
                ;;
            --output=*)
                OUTPUT_ROOT="${1#*=}"
                shift
                ;;
            --output)
                OUTPUT_ROOT="$2"
                shift 2
                ;;
            --disk-layout=*)
                DISK_LAYOUT="${1#*=}"
                shift
                ;;
            --disk-layout)
                DISK_LAYOUT="$2"
                shift 2
                ;;
            --debug)
                DEBUG=true
                shift
                ;;
            --run-script=*)
                RUN_SCRIPTS+=("${1#*=}")
                START_VM=true
                shift
                ;;
            --run-script)
                RUN_SCRIPTS+=("$2")
                START_VM=true
                shift 2
                ;;
            --run-host-script=*)
                RUN_HOST_SCRIPTS+=("${1#*=}")
                START_VM=true
                shift
                ;;
            --run-host-script)
                RUN_HOST_SCRIPTS+=("$2")
                START_VM=true
                shift 2
                ;;
            --ssh-user=*)
                export VM_SSH_USER="${1#*=}"
                shift
                ;;
            --ssh-key=*)
                VM_SSH_KEY="${1#*=}"
                shift
                ;;
            --ssh-timeout=*)
                VM_SSH_TIMEOUT="${1#*=}"
                shift
                ;;
            --ssh-authorized-keys=*)
                VM_SSH_AUTHORIZED_KEYS="${1#*=}"
                shift
                ;;
            --ssh-authorized-keys)
                VM_SSH_AUTHORIZED_KEYS="$2"
                shift 2
                ;;
            --vm-password=*)
                VM_PASSWORD="${1#*=}"
                shift
                ;;
            --vm-password)
                VM_PASSWORD="$2"
                shift 2
                ;;
            --use-serial|--serial)
                USE_SERIAL_CONSOLE=true
                shift
                ;;
            --use-ssh|--no-serial)
                USE_SERIAL_CONSOLE=false
                shift
                ;;
            --console-user=*)
                VM_CONSOLE_USER="${1#*=}"
                shift
                ;;
            --console-user)
                VM_CONSOLE_USER="$2"
                shift 2
                ;;
            --console-password=*)
                VM_CONSOLE_PASSWORD="${1#*=}"
                shift
                ;;
            --console-password)
                VM_CONSOLE_PASSWORD="$2"
                shift 2
                ;;
            --boot-timeout=*)
                VM_BOOT_TIMEOUT="${1#*=}"
                shift
                ;;
            --no-secure-boot)
                export SECURE_BOOT_ENABLED=false
                shift
                ;;
            --az-sub-id=*)
                AZ_SUB_ID="${1#*=}"
                shift
                ;;
            --az-sub-id)
                AZ_SUB_ID="$2"
                shift 2
                ;;
            --az-region=*)
                AZ_REGION="${1#*=}"
                shift
                ;;
            --az-region)
                AZ_REGION="$2"
                shift 2
                ;;
            --az-storage-account=*)
                AZ_STORAGE_ACC="${1#*=}"
                shift
                ;;
            --az-storage-account)
                AZ_STORAGE_ACC="$2"
                shift 2
                ;;
            --az-storage-rg=*)
                AZ_STORAGE_RG="${1#*=}"
                shift
                ;;
            --az-storage-rg)
                AZ_STORAGE_RG="$2"
                shift 2
                ;;
            --az-storage-container=*)
                AZ_STORAGE_CONTAINER="${1#*=}"
                shift
                ;;
            --az-storage-container)
                AZ_STORAGE_CONTAINER="$2"
                shift 2
                ;;
            --az-gallery-rg=*)
                AZ_GALLERY_RG="${1#*=}"
                shift
                ;;
            --az-gallery-rg)
                AZ_GALLERY_RG="$2"
                shift 2
                ;;
            --az-acg=*)
                AZ_ACG="${1#*=}"
                shift
                ;;
            --az-acg)
                AZ_ACG="$2"
                shift 2
                ;;
            --acg-gallery-name=*)
                AZ_ACG="${1#*=}"
                shift
                ;;
            --acg-gallery-name)
                AZ_ACG="$2"
                shift 2
                ;;
            --acg-image-version-id=*)
                ACG_IMAGE_VERSION_ID="${1#*=}"
                shift
                ;;
            --acg-image-version-id)
                ACG_IMAGE_VERSION_ID="$2"
                shift 2
                ;;
            --az-vm-size=*)
                AZ_VM_SIZE="${1#*=}"
                shift
                ;;
            --az-vm-size)
                AZ_VM_SIZE="$2"
                shift 2
                ;;
            --az-backup-regions=*)
                AZ_BACKUP_REGIONS="${1#*=}"
                shift
                ;;
            --az-backup-regions)
                AZ_BACKUP_REGIONS="$2"
                shift 2
                ;;
            --no-cleanup)
                NO_CLEANUP=true
                shift
                ;;
            --build-standalone-sysexts)
                BUILD_STANDALONE_SYSEXTS=true
                shift
                ;;
            --build-standalone-sysexts=*)
                BUILD_STANDALONE_SYSEXTS=true
                STANDALONE_SYSEXTS_TAG="${1#*=}"
                shift
                ;;
            --skip-standalone-sysexts)
                BUILD_STANDALONE_SYSEXTS=false
                shift
                ;;
            --keep-vm)
                KEEP_VM=true
                NO_CLEANUP=true
                shift
                ;;
            --reuse-vm)
                REUSE_VM=true
                START_VM=true
                NO_CLEANUP=true
                shift
                ;;
            --reuse-image)
                REUSE_IMAGE=true
                START_VM=true
                shift
                ;;
            --tag=*)
                RESOURCE_TAGS+=("${1#*=}")
                shift
                ;;
            --tag)
                RESOURCE_TAGS+=("$2")
                shift 2
                ;;
            --run-kola-tests)
                RUN_KOLA_TESTS=true
                shift
                ;;
            --az-vm-args=*)
                AZ_VM_ARGS="${1#*=}"
                shift
                ;;
            --az-vm-args)
                AZ_VM_ARGS="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                ;;
            *)
                error "Unknown option: $1"
                error "Use --help to see available options."
                exit 1
                ;;
        esac
    done

    # Validate --retry value
    if [[ "$RETRY_ATTEMPTS" != "0" ]]; then
        if ! [[ "$RETRY_ATTEMPTS" =~ ^[1-9][0-9]*$ ]]; then
            error "--retry requires a positive integer, got: '$RETRY_ATTEMPTS'"
            exit 1
        fi
        if [[ "$RETRY_ATTEMPTS" -gt 10 ]]; then
            error "--retry value too large (max 10), got: '$RETRY_ATTEMPTS'"
            exit 1
        fi
    fi

    # Normalize group name
    case "$GROUP" in
        prod|production)
            GROUP="production"
            ;;
        dev|developer)
            GROUP="developer"
            ;;
    esac

    # Validate VM type if building VM images
    if [[ "$BUILD_VM_IMAGE" == "true" ]] || [[ "$START_VM" == "true" ]]; then
        case "$VM_TYPE" in
            azure|qemu)
                # Valid VM type
                ;;
            *)
                error "Invalid VM type: $VM_TYPE"
                error "Valid options: azure, qemu"
                exit 1
                ;;
        esac
    fi

    # Add platform-specific host-side tests when --run-tests is used.
    if [[ "${RUN_TESTS:-false}" == "true" ]] && [[ "$VM_TYPE" == "azure" ]]; then
        RUN_HOST_SCRIPTS+=("./acl/tests/run-selinux-toggle-test.sh")
    fi

    if [[ "$REUSE_IMAGE" == "true" ]]; then
        if [[ "$VM_TYPE" != "azure" ]]; then
            error "--reuse-image can only be used with VM_TYPE=azure"
            exit 1
        fi
    fi

    # Ensure only one of ACG_IMAGE_VERSION_ID or REUSE_IMAGE is set to avoid ambiguity
    if [[ -n "$ACG_IMAGE_VERSION_ID" && "$REUSE_IMAGE" == "true" ]]; then
        error "Cannot set both ACG_IMAGE_VERSION_ID and REUSE_IMAGE. Please choose one."
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    section "Checking Prerequisites"

    local missing=()

    # Check for required commands
    local required_cmds=(docker)
    if [[ "$BUILD_STANDALONE_SYSEXTS" == "true" ]] || [[ "$BUILD_RPMS" == "true" ]]; then
        required_cmds+=(yq)
    fi
    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    # Azure Linux specific: check for docker-cli
    if is_azure_linux_3 && ! command -v docker &>/dev/null; then
        error "Docker CLI not found. On Azure Linux, install with:"
        error "  sudo tdnf install -y moby-engine docker-cli"
        exit 1
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required commands: ${missing[*]}"
        error "Please install them and try again."
        exit 1
    fi

    # Check Docker is running
    if ! docker info &>/dev/null; then
        error "Docker is not running. Please start Docker and try again."
        exit 1
    fi

    # Check for SDK container script
    if [[ ! -f "${SCRIPT_DIR}/run_sdk_container" ]]; then
        error "run_sdk_container script not found"
        exit 1
    fi

    # Check for build_image script
    if [[ ! -f "${SCRIPT_DIR}/build_image" ]]; then
        error "build_image script not found"
        exit 1
    fi

    # Check arm64 cross-build prerequisites (qemu-user-static for binfmt_misc)
    if [[ "$BOARD" == "arm64-usr" ]]; then
        if [[ "$BUILD_IMAGE" == "true" ]] && ! command -v qemu-aarch64-static &>/dev/null; then
            error "qemu-aarch64-static not found — required for arm64 cross-builds."
            error "  AzL3:   sudo tdnf install -y qemu-user-static-aarch64"
            error "  Ubuntu: sudo apt-get install -y qemu-user-static"
            exit 1
        fi
        if [[ "$START_VM" == "true" ]] && [[ "$VM_TYPE" == "qemu" ]]; then
            if ! command -v qemu-system-aarch64 &>/dev/null; then
                error "qemu-system-aarch64 not found — required for arm64 QEMU VM boot."
                error "  AzL3:   sudo tdnf install -y qemu-system-aarch64 edk2-aarch64"
                error "  Ubuntu: sudo apt-get install -y qemu-system-arm qemu-efi-aarch64"
                exit 1
            fi
        fi
    fi

    info "✓ All build prerequisites met"
}

# Creates or updates repository metadata for the staging directory.
create_repo() {
    info "Creating repository metadata..."
    
    if ! command -v createrepo_c &>/dev/null; then
        error "createrepo_c not found - required to create repository metadata"
        error "  Install with: sudo dnf install createrepo_c or sudo apt install createrepo-c"
        exit 1
    fi

    if ! createrepo_c --update "${STAGING_DIR}" >/dev/null 2>&1; then
        error "Failed to create repository metadata"
        exit 1
    fi

    if [[ -f "${STAGING_DIR}/repodata/repomd.xml" ]]; then
        info "✓ Repository metadata created/updated successfully"
    else
        error "Repository metadata not found after createrepo_c"
        exit 1
    fi
}

# Cleans up old Docker containers matching a filter pattern.
cleanup_containers() {
    local filter="${1:-name=flatcar-sdk-}"

    info "Cleaning up old containers..."
    docker ps -a --filter "${filter}" --format "{{.ID}} {{.Names}}" | while read -r id name; do
        info "  Removing container: $name ($id)"
        docker rm -f "$id" 2>/dev/null || true
    done
}

# Updates/rebuilds the SDK container with RPM tools.
update_sdk_container() {
    section "Updating SDK Container"

    info "Rebuilding SDK container with RPM/dnf5 tools..."

    # Source SDK common functions to get version info
    source "${SCRIPT_DIR}/sdk_lib/sdk_container_common.sh"

    # Restore original version file and read base SDK version
    git restore sdk_container/.repo/manifests/version.txt 2>/dev/null || true
    source sdk_container/.repo/manifests/version.txt
    local base_sdk_version="${FLATCAR_SDK_VERSION}"
    local rpm_sdk_version="${base_sdk_version}-rpm"

    info "Base SDK version: ${base_sdk_version}"
    info "RPM SDK version:  ${rpm_sdk_version}"

    # Ensure base SDK container exists
    info "Ensuring base SDK container is available..."
    ./run_sdk_container $(get_tty_flag) hostname

    # Update SDK container with RPM tools
    info "Installing RPM/dnf5 tools in SDK container..."
    ./update_sdk_container_image "${rpm_sdk_version}"

    # Clean up old SDK containers
    cleanup_containers "name=flatcar-sdk-"

    # Get updated SDK version
    local sdk_version=$(get_sdk_version_from_versionfile)
    local docker_sdk_vernum=$(vernum_to_docker_image_version "$sdk_version")
    local sdk_image="${sdk_container_common_registry}/flatcar-sdk-all:${docker_sdk_vernum}"

    info "✓ SDK container updated successfully"
    info "  Image: ${sdk_image}"
    echo
}

# Builds custom RPM packages using Azure Linux toolkit.
build_rpms() {
    section "Building Custom RPM Packages"

    local build_script="${SCRIPT_DIR}/acl/build.sh"
    
    if [[ ! -f "$build_script" ]]; then
        error "RPM build script not found: $build_script"
        exit 1
    fi

    # Package list — build.sh receives these as positional args.
    # Maintained in acl/packages.yaml.
    local packages_file="${SCRIPT_DIR}/acl/packages.yaml"
    if [[ ! -f "$packages_file" ]]; then
        error "Package list not found: $packages_file"
        exit 1
    fi
    local -a package_list=()
    if ! mapfile -t package_list < <(yq -r '.packages[]' "$packages_file"); then
        error "Failed to parse package list from $packages_file"
        exit 1
    fi
    
    info "Running RPM build script..."
    info "  Build script: $build_script"
    info "  Package list: ${package_list[*]}"
    info "  Output dir:   ${STAGING_DIR}"
    echo

    # Run the build script
    if ! "$build_script" "${package_list[@]}"; then
        error "RPM build failed"
        exit 1
    fi

    # Remove custom-built systemd-boot RPMs from staging so the stock
    # Microsoft-signed systemd-boot is used instead. The systemd spec produces
    # systemd-boot as a sub-package, but on Trusted Launch VMs shim verifies the
    # bootloader signature, only the PMC-published systemd-boot is signed by
    # Microsoft, so our locally-built copy would fail Secure Boot verification
    # and prevent the VM from booting.
    local removed_boot=0
    for f in "${STAGING_DIR}"/systemd-boot-*.rpm; do
        [[ -e "$f" ]] || continue
        info "Removing custom-built $(basename "$f") from staging (using stock Microsoft-signed version)"
        rm -f "$f"
        removed_boot=$((removed_boot + 1))
    done
    if (( removed_boot > 0 )); then
        info "  Removed ${removed_boot} systemd-boot RPM(s) — stock version from PMC will be used"
    fi

    # Count built RPMs
    local rpm_count=$(ls -1 "${STAGING_DIR}"/*.rpm 2>/dev/null | wc -l)
    info "✓ RPM build complete"
    info "  Total RPMs in staging: ${rpm_count}"

    # Update repository metadata with new RPMs
    create_repo
}

# Builds the Azure Container Linux (ACL) image using SDK container.
build_image() {
    section "Building Azure Container Linux Image"

    info "Configuration:"
    info "  Board:           ${BOARD}"
    info "  Group:           ${GROUP}"
    info "  Output:          ${OUTPUT_ROOT}"
    info "  Staging Dir:     ${STAGING_DIR}"
    info "  Force Rebuild:   ${FORCE_REBUILD}"
    echo

    # Count RPMs
    local rpm_count=$(ls -1 "${STAGING_DIR}"/*.rpm 2>/dev/null | wc -l)
    info "Using ${rpm_count} pre-downloaded RPM packages"

    # Build arguments for build_image
    # Embedded sysexts (placed on /usr, activated at boot) are defined in the
    # sysexts YAML with mode: embedded.  Load them from the config rather than
    # hardcoding them here.
    local embedded_sysexts
    embedded_sysexts=$(parse_embedded_sysexts_yaml "${SYSEXTS_YAML}" "${BOARD}")
    if [[ -z "${embedded_sysexts}" ]]; then
        error "No embedded sysexts found in ${SYSEXTS_YAML} for board ${BOARD}."
        error "At least one sysext with 'mode: embedded' is required."
        exit 1
    fi

    local build_args=(
        "--image_compression_formats=none"
        "--nogenerate_update"
        "--board=${BOARD}"
        "--group=${GROUP}"
        "--base_sysexts=${embedded_sysexts}"
        "--disk_layout=${DISK_LAYOUT}"
        "--image_name=${IMG_NAME}_image.bin"
    )

    if [[ "$FORCE_REBUILD" == "true" ]]; then
        build_args+=("--replace")
    fi

    # Run the build inside SDK container
    info "Starting SDK container and build process..."

    local sdk_image
    sdk_image=$(get_sdk_image)

    info "Using SDK image: ${sdk_image}"
    # Use -C to specify the custom image (skips registry download)
    # Use --rm to remove old container and ensure environment variables are set correctly
    "${SCRIPT_DIR}/run_sdk_container" \
        --rm \
        $(get_tty_flag) \
        -C "${sdk_image}" \
        -- \
        ./build_image "${build_args[@]}"

    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        section "Build Completed Successfully"
        show_build_output
    else
        error "Build failed with exit code: $exit_code"
        suggest_troubleshooting
        exit $exit_code
    fi
}

# Shows build output location.
show_build_output() {
    info "Build artifacts location:"

    local image_dir="${SCRIPT_DIR}/__build__/images/images/${BOARD}"
    if [[ -d "$image_dir" ]]; then
        # Find latest build
        local latest=$(ls -td "${image_dir}"/*/ 2>/dev/null | head -1)
        if [[ -n "$latest" ]]; then
            info "  Latest build: ${latest}"
            ls -lh "${latest}"/*.{bin,img,vmdk,qcow2,raw,gz,xz} 2>/dev/null | head -10 || true
        fi
    else
        warn "No image output directory found at: ${image_dir}"
    fi
}

# Suggests troubleshooting steps.
suggest_troubleshooting() {
    echo
    warn "Troubleshooting suggestions:"
    echo "  1. Check the build log for specific errors"
    echo "  2. Verify RPM staging directory has all required packages:"
    echo "     ls ${STAGING_DIR}/*.rpm | wc -l"
    echo "  3. Try cleaning staging and build RPM directories before rebuilding:"
    echo "     $0 --clean"
    echo "  4. Check for missing critical packages:"
    echo "     ls ${STAGING_DIR}/{filesystem,glibc,bash,readline,ncurses}*.rpm"
    echo "  5. Enable debug mode:"
    echo "     DEBUG=true $0"
    echo
}

# Builds standalone sysexts as a separate step (not during VM image conversion).
# Uses the sysext base squashfs produced by build_image and delegates to
# build_standalone_sysext_images() from build_library/standalone_sysext_util.sh
# inside the SDK container.
build_standalone_sysexts() {
    section "Building Standalone Sysexts"

    # Parse YAML config — arch and optional tag filtering is handled by the parser
    local sysext_spec_str
    sysext_spec_str=$(parse_standalone_sysexts_yaml "${SYSEXTS_YAML}" "${BOARD}" "${STANDALONE_SYSEXTS_TAG}")

    if [[ -z "${sysext_spec_str// /}" ]]; then
        info "No standalone sysexts to build for ${BOARD}"
        return 0
    fi

    local sdk_image
    sdk_image=$(get_sdk_image)

    local from_dir="${SCRIPT_DIR}/__build__/images/images/${BOARD}/latest"
    local sysext_base="${from_dir}/${IMG_NAME}_image_sysext.squashfs"
    if [[ ! -f "${sysext_base}" ]]; then
        error "Sysext base squashfs not found: ${sysext_base}"
        error "Run --build-image first to produce the sysext base."
        exit 1
    fi

    # CI mode: copy artifact version.txt so the SDK container picks up matching versions
    local version_args=()
    if [[ "${NO_TTY:-false}" == "true" ]] && [[ -f "${from_dir}/version.txt" ]]; then
        info "Installing artifact version.txt into manifest location (CI mode)"
        cp "${from_dir}/version.txt" \
           "${SCRIPT_DIR}/sdk_container/.repo/manifests/version.txt"
        version_args=( -U )
    fi

    # Paths as seen inside the SDK container
    local container_squashfs="../build/images/${BOARD}/latest/${IMG_NAME}_image_sysext.squashfs"
    local container_output="../build/images/${BOARD}/latest"

    # Single container invocation using the shared utility via build_standalone_sysexts
    STANDALONE_SYSEXTS_SPEC="${sysext_spec_str}" \
    "${SCRIPT_DIR}/run_sdk_container" \
        --rm \
        $(get_tty_flag) \
        "${version_args[@]}" \
        -C "${sdk_image}" \
        -- \
        ./build_standalone_sysexts \
            --board="${BOARD}" \
            --squashfs_base="${container_squashfs}" \
            --output_dir="${container_output}"

    info "All standalone sysexts built successfully"
}

# Builds a VM image (qemu_uefi or azure) from the base image using the SDK container.
build_vm_image() {
    local vm_type="$1"
    local vm_image_path="$2"
    local format

    case "$vm_type" in
        qemu)   format="qemu_uefi" ;;
        azure)  format="azure" ;;
        *)      error "Unsupported VM type: $VM_TYPE"; exit 1 ;;
    esac

    local sdk_image
    sdk_image=$(get_sdk_image)

    local build_args=(
        "--image_compression_formats=none"
        "--from=../build/images/${BOARD}/latest"
        "--board=${BOARD}"
        "--format=${format}"
        "--image_name=${IMG_NAME}_image.bin"
    )

    info "Building ${vm_type} VM image using SDK container..."

    # In CI test-only mode the git checkout may be newer than the artifacts.
    # Copy the artifact's version.txt into the standard manifest location
    # so that run_sdk_container (and everything it calls, e.g. build_sysext)
    # picks up the versions that match the artifact.  Pass -U so
    # run_sdk_container reads both OS and SDK versions from the file and
    # does not overwrite it with a git-derived version.
    # Only do this in pipeline runs (NO_TTY=true) to avoid accidentally
    # pulling a stale version.txt into local dev builds.
    local version_args=()
    local from_dir="${SCRIPT_DIR}/__build__/images/images/${BOARD}/latest"
    if [[ "${NO_TTY:-false}" == "true" ]] && [[ -f "${from_dir}/version.txt" ]]; then
        info "Installing artifact version.txt into manifest location (CI mode)"
        cp "${from_dir}/version.txt" \
           "${SCRIPT_DIR}/sdk_container/.repo/manifests/version.txt"
        version_args=( -U )
    fi

    # Use -C to specify custom SDK image (avoids trying to download non-existent version-specific image)
    # Use --rm to remove old container and ensure environment variables are set correctly
    "${SCRIPT_DIR}/run_sdk_container" \
        --rm \
        $(get_tty_flag) \
        "${version_args[@]}" \
        -C "${sdk_image}" \
        -- \
        ./image_to_vm.sh "${build_args[@]}"

    if ! [[ -f "$vm_image_path" ]]; then
        error "${vm_type} VM image generation failed"
        exit 1
    fi
}

# Print size summary of built images
print_size_summary() {
    section "Image Size Summary"

    # Find the latest build directory
    local build_dir="${OUTPUT_ROOT}"
    BUILD_IMAGE_DIR="${build_dir}/images/images/${BOARD}/latest"
    if [[ -d "${BUILD_IMAGE_DIR}" ]]; then
        info "Build directory: ${BUILD_IMAGE_DIR}"
        echo

        # USR partition image
        if [[ -f "${BUILD_IMAGE_DIR}/${IMG_NAME}_image.bin" ]]; then
            usr_size=$(du -h "${BUILD_IMAGE_DIR}/${IMG_NAME}_image.bin" | cut -f1)
            info "USR Image:    ${usr_size}  (${BUILD_IMAGE_DIR}/${IMG_NAME}_image.bin)"
        fi

        # Sysext images
        if ls "${BUILD_IMAGE_DIR}"/rootfs-included-sysexts/*.raw &>/dev/null; then
            echo
            info "Sysext Images:"
            for sysext in "${BUILD_IMAGE_DIR}"/rootfs-included-sysexts/*.raw; do
                if [[ -f "$sysext" ]]; then
                    sysext_size=$(du -h "$sysext" | cut -f1)
                    sysext_name=$(basename "$sysext")
                    info "  - ${sysext_name}: ${sysext_size}"
                fi
            done
        fi

        # Full disk image
        if [[ -f "${BUILD_IMAGE_DIR}/${IMG_NAME}_image.bin" ]]; then
            echo
            full_size=$(du -h "${BUILD_IMAGE_DIR}/${IMG_NAME}_image.bin" | cut -f1)
            info "Full Image:   ${full_size}  (total disk image)"
        fi
    else
        warn "Build directory not found: ${BUILD_IMAGE_DIR}"
    fi
    echo
}

# Print summary of what will be done
print_summary() {
    section "Azure Container Linux Image Build Summary"

    echo "This script will:"
    echo

    if [[ "$BUILD_RPMS" == "true" ]]; then
        echo "  Build custom RPM packages"
        echo "  Output: ${STAGING_DIR}"
        if [[ "$CLEAN_DIRS" == "true" ]]; then
            echo "     Mode: Clean build (remove existing)"
        fi
        echo
    fi

    if [[ "$BUILD_IMAGE" == "true" ]]; then
        echo "  Build Azure Container Linux image using SDK container"
        echo "  Board: ${BOARD}"
        echo "  Group: ${GROUP}"
        echo "  Mode: RPM (Azure Linux RPMs)"
        echo "  Standalone sysexts: enabled"
        echo
    fi

    if [[ "$BUILD_VM_IMAGE" == "true" ]]; then
        echo "  Build Azure Container Linux VM image (no docker sysext)"
        echo "  VM Type: ${VM_TYPE}"
        echo "  Base Image: ${IMG_NAME}_${VM_TYPE}_uefi_image.img"
        echo
    fi

    if [[ "$BUILD_TEST_IMAGE" == "true" ]]; then
        echo "  Build Azure Container Linux test VM image (with docker sysext)"
        echo "  VM Type: ${VM_TYPE}"
        if [[ "$VM_TYPE" == "azure" ]]; then
            echo "  Test Image: ${IMG_NAME}_azure_test_image.vhd"
        else
            echo "  Test Image: ${IMG_NAME}_qemu_uefi_test_image.img"
        fi

        echo
    fi

    if [[ "$BUILD_STANDALONE_SYSEXTS" == "true" ]]; then
        local _tag_info=""
        [[ -n "${STANDALONE_SYSEXTS_TAG}" ]] && _tag_info=" (tag: ${STANDALONE_SYSEXTS_TAG})"
        echo "  Build standalone sysexts${_tag_info}"
        # Reuse parse_standalone_sysexts_yaml to apply both tag and arch
        # filtering, so the summary matches what will actually be built.
        local _sysext_spec
        _sysext_spec=$(parse_standalone_sysexts_yaml "${SYSEXTS_YAML}" "${BOARD}" "${STANDALONE_SYSEXTS_TAG}") || {
            error "Failed to parse ${SYSEXTS_YAML} with yq."
            error "  version: $(yq --version 2>&1 || echo unknown)"
            error "Check the YAML syntax or ensure yq v4+ is installed."
            exit 1
        }
        # Extract just the names (before the "|" delimiter) for display.
        local _sysext_names
        _sysext_names=$(echo "${_sysext_spec}" | tr ' ' '\n' | cut -d'|' -f1 | tr '\n' ' ')
        echo "  Sysexts: ${_sysext_names:-<none>}"
        echo
    fi

    echo
}

# Cleans RPM directories before operations.
cleanup_rpm_directories() {
    if [[ "$CLEAN_DIRS" == "true" ]]; then
        section "Cleaning RPM Directories"
        
        # Clean staging directory
        if [[ -d "${STAGING_DIR}" ]]; then
            warn "Removing: ${STAGING_DIR}"
            rm -rf "${STAGING_DIR}"
        fi
        
        # Clean build directories
        local build_dir="${SCRIPT_DIR}/__build__/rpms_build_dir"
        if [[ -d "$build_dir" ]]; then
            warn "Removing: $build_dir"
            sudo rm -rf "$build_dir"
        fi
        
        local out_dir="${SCRIPT_DIR}/__build__/rpms_out_dir"
        if [[ -d "$out_dir" ]]; then
            warn "Removing: $out_dir"
            sudo rm -rf "$out_dir"
        fi
        
        info "✓ Cleanup complete"
    fi
}

# Cleans intermediate RPM build caches between retry attempts.
# Preserves the azurelinux git clone, toolchain RPMs, and rpm-staging
# (which contains cross-project RPMs from upstream pipeline artifacts).
# Only clears the caches that are likely stale after a transient failure:
#   - rpm_cache:    graphpkgfetcher download cache (tdnf repo metadata)
#   - pkg_artifacts: intermediate build artifacts including tdnf worker caches
#   - worker:       worker chroot (may have stale tdnf state)
#   - make_status:  make status flags (so make re-runs targets)
#   - rpms_out_dir: build outputs (need fresh generation)
clean_rpm_build_caches() {
    local build_dir="${SCRIPT_DIR}/__build__/rpms_build_dir"
    local out_dir="${SCRIPT_DIR}/__build__/rpms_out_dir"

    warn "Cleaning intermediate build caches for retry..."
    for subdir in rpm_cache pkg_artifacts worker make_status; do
        if [[ -d "${build_dir}/${subdir}" ]]; then
            warn "  Removing: ${build_dir}/${subdir}"
            sudo rm -rf "${build_dir}/${subdir}"
        fi
    done
    if [[ -d "$out_dir" ]]; then
        warn "  Removing: $out_dir"
        sudo rm -rf "$out_dir"
    fi
    info "  ✓ Intermediate caches cleared (azurelinux clone, toolchain, and rpm-staging preserved)"
}

# Runs a build function with retry if RETRY_ATTEMPTS > 0, otherwise runs directly.
# Centralizes the retry policy (backoff timing, cleanup function) so call sites
# don't duplicate the retry_with_backoff invocation.
run_with_retry() {
    if [[ "$RETRY_ATTEMPTS" -gt 0 ]]; then
        retry_with_backoff \
            --max-attempts "$RETRY_ATTEMPTS" --initial-wait 15 --max-backoff 300 \
            --clean-cmd clean_rpm_build_caches \
            -- "$@"
    else
        "$@"
    fi
}

# Main entry point
main() {
    parse_args "$@"

    section "Azure Container Linux Image Builder"
    info "Building ${BOARD} ${GROUP} image using Azure Linux RPMs"

    check_prerequisites
    print_summary

    # Step 0: Update SDK container if requested (before download/build)
    if [[ "$BUILD_SDK_CONTAINER" == "true" ]]; then
        update_sdk_container
        info "Updated SDK container. Existing SDK containers removed. For subsequent runs, remove the --build-sdk-container flag to speed up."
    else 
        info "Skipping SDK container update"
        info "Found the following SDK containers:"
        docker ps -a --filter "name=flatcar-sdk-" --format "{{.ID}} {{.Names}}"
    fi

    # Step 0.5: Clean RPM directories (if requested)
    cleanup_rpm_directories

    # Step 2: Build custom RPM packages (if requested)
    if [[ "$BUILD_RPMS" == "true" ]]; then
        run_with_retry build_rpms
    fi

    # Step 3: Build image (if requested)
    if [[ "$BUILD_IMAGE" == "true" ]]; then
        # Reset cached image version so common.sh generates fresh values
        if [[ "$FORCE_REBUILD" == "true" ]]; then
            rm -f "${SCRIPT_DIR}/__build__/image-version.env"
        fi
        build_image
        print_size_summary
    fi

    # Step 4: Build standalone sysexts (if requested)
    if [[ "$BUILD_STANDALONE_SYSEXTS" == "true" ]]; then
        build_standalone_sysexts
    fi

    # Step 5a: Build test VM image (if requested)
    if [[ "$BUILD_TEST_IMAGE" == "true" ]]; then
        local vm_image_path test_vm_image_path
        case "$VM_TYPE" in
            qemu)
                vm_image_path="__build__/images/images/${BOARD}/latest/${IMG_NAME}_qemu_uefi_image.img"
                test_vm_image_path="__build__/images/images/${BOARD}/latest/${IMG_NAME}_qemu_uefi_test_image.img"
                ;;
            azure)
                vm_image_path="__build__/images/images/${BOARD}/latest/${IMG_NAME}_azure_image.vhd"
                test_vm_image_path="__build__/images/images/${BOARD}/latest/${IMG_NAME}_azure_test_image.vhd"
                ;;
        esac
        section "Building Test VM Image at ${test_vm_image_path}"
        info "Converting base image to ${VM_TYPE} test VM format (with docker sysext)..."
        export INJECT_DOCKER_SYSEXT=true
        build_vm_image "$VM_TYPE" "$vm_image_path"
        mv "${vm_image_path}" "${test_vm_image_path}"

        # Preserve the secure boot firmware alongside the test image so that a
        # subsequent --build-vm-image (step 5b) can overwrite the shared firmware
        # files without breaking the test image's secure boot chain.
        if [[ "$VM_TYPE" == "qemu" ]]; then
            local fw_base="__build__/images/images/${BOARD}/latest/${IMG_NAME}_qemu_uefi"
            local test_fw_base="${fw_base}_test"
            for suffix in _secure_efi_code.qcow2 _secure_efi_vars.qcow2; do
                if [[ -f "${fw_base}${suffix}" ]]; then
                    cp "${fw_base}${suffix}" "${test_fw_base}${suffix}"
                fi
            done
        fi

        info "Test VM image ready at: ${test_vm_image_path}"
    fi

    # Step 5b: Build VM image (if requested)
    if [[ "$BUILD_VM_IMAGE" == "true" ]]; then
        local vm_image_path
        case "$VM_TYPE" in
            qemu)  vm_image_path="__build__/images/images/${BOARD}/latest/${IMG_NAME}_qemu_uefi_image.img" ;;
            azure) vm_image_path="__build__/images/images/${BOARD}/latest/${IMG_NAME}_azure_image.vhd" ;;
        esac
        section "Building VM Image at ${vm_image_path}"
        info "Converting base image to ${VM_TYPE} VM format..."
        export INJECT_DOCKER_SYSEXT=false
        build_vm_image "$VM_TYPE" "$vm_image_path"
        info "VM image ready at: ${vm_image_path}"
    fi

    # Step 6: VM lifecycle & kola tests — delegate to validate_rpm_image.sh
    if [[ "$START_VM" == "true" ]] || [[ "$RUN_KOLA_TESTS" == "true" ]]; then
        local validate_args=()
        validate_args+=("--board=${BOARD}")
        validate_args+=("--img-name=${IMG_NAME}")
        validate_args+=("--vm-type=${VM_TYPE}")
        validate_args+=("--vm-name=${VM_NAME}")
        validate_args+=("--ssh-timeout=${VM_SSH_TIMEOUT}")
        validate_args+=("--boot-timeout=${VM_BOOT_TIMEOUT}")
        validate_args+=("--console-user=${VM_CONSOLE_USER}")
        [[ -n "${AZ_SUB_ID:-}" ]] && validate_args+=("--az-sub-id=${AZ_SUB_ID}")
        [[ -n "${AZ_REGION:-}" ]] && validate_args+=("--az-region=${AZ_REGION}")
        [[ -n "${AZ_STORAGE_ACC:-}" ]] && validate_args+=("--az-storage-account=${AZ_STORAGE_ACC}")
        [[ -n "${AZ_STORAGE_RG:-}" ]] && validate_args+=("--az-storage-rg=${AZ_STORAGE_RG}")
        [[ -n "${AZ_STORAGE_CONTAINER:-}" ]] && validate_args+=("--az-storage-container=${AZ_STORAGE_CONTAINER}")
        [[ -n "${AZ_ACG:-}" ]] && validate_args+=("--acg-gallery-name=${AZ_ACG}")
        [[ -n "${AZ_GALLERY_RG:-}" ]] && validate_args+=("--az-gallery-rg=${AZ_GALLERY_RG}")
        [[ -n "${AZ_VM_SIZE:-}" ]] && validate_args+=("--az-vm-size=${AZ_VM_SIZE}")
        [[ -n "${AZ_BACKUP_REGIONS:-}" ]] && validate_args+=("--az-backup-regions=${AZ_BACKUP_REGIONS}")
        [[ -n "$BUILD_ID" ]]                  && validate_args+=("--build-id=${BUILD_ID}")

        [[ -n "$VM_SSH_KEY" ]]              && validate_args+=("--ssh-key=${VM_SSH_KEY}")
        [[ -n "$VM_SSH_AUTHORIZED_KEYS" ]]  && validate_args+=("--ssh-authorized-keys=${VM_SSH_AUTHORIZED_KEYS}")
        [[ -n "$VM_CONSOLE_PASSWORD" ]]     && validate_args+=("--console-password=${VM_CONSOLE_PASSWORD}")
        [[ -n "$ACG_IMAGE_VERSION_ID" ]]    && validate_args+=("--acg-image-version-id=${ACG_IMAGE_VERSION_ID}")

        [[ "$USE_TEST_IMAGE" == "true" ]]       && validate_args+=("--use-test-image")
        [[ "$START_VM" == "true" ]]             && validate_args+=("--start-vm")
        [[ "$KEEP_VM" == "true" ]]              && validate_args+=("--keep-vm")
        [[ "$REUSE_VM" == "true" ]]             && validate_args+=("--reuse-vm")
        [[ "$REUSE_IMAGE" == "true" ]]           && validate_args+=("--reuse-image")
        [[ -n "${NO_CLEANUP:-}" ]] && [[ "$NO_CLEANUP" == "true" ]] && validate_args+=("--no-cleanup")
        [[ "$RUN_KOLA_TESTS" == "true" ]]       && validate_args+=("--run-kola-tests")
        [[ "$USE_SERIAL_CONSOLE" == "true" ]]   && validate_args+=("--use-serial")
        [[ "$USE_SERIAL_CONSOLE" == "false" ]]  && validate_args+=("--use-ssh")
        [[ "${SECURE_BOOT_ENABLED:-}" == "false" ]] && validate_args+=("--no-secure-boot")

        [[ "$VM_TYPE" == "azure" ]] && [[ -n "$AZ_VM_ARGS" ]] && validate_args+=("--az-vm-args=${AZ_VM_ARGS}")

        for script in "${RUN_SCRIPTS[@]}"; do
            validate_args+=("--run-script=${script}")
        done

        for script in "${RUN_HOST_SCRIPTS[@]}"; do
            validate_args+=("--run-host-script=${script}")
        done

        for tag in "${RESOURCE_TAGS[@]}"; do
            validate_args+=("--tag=${tag}")
        done

        "${SCRIPT_DIR}/acl/validate/validate_rpm_image.sh" "${validate_args[@]}"
    fi
}

# Run main function
main "$@"
