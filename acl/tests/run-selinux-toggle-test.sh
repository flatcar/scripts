#!/bin/bash
# Test the acl-selinux-toggle dracut module: set an Azure VM tag, reboot,
# and verify SELinux mode changed. Requires an already-provisioned Azure VM.

set -euo pipefail

source "${SCRIPT_DIR}/acl/validate/validate_common.sh"

# ── Helpers ────────────────────────────────────────────────────────

SSH_OPTS=()

setup_ssh_opts() {
    SSH_OPTS=(
        -o StrictHostKeyChecking=no
        -o UserKnownHostsFile=/dev/null
        -o BatchMode=yes
        -o ConnectTimeout=10
        -i "$VM_SSH_KEY"
    )
}

ssh_cmd() {
    ssh "${SSH_OPTS[@]}" "${VM_SSH_USER}@${VM_IP}" "$@"
}

# Get current SELinux mode via getenforce.
get_selinux_mode() {
    ssh_cmd "sudo getenforce" 2>/dev/null | tr '[:upper:]' '[:lower:]'
}

# Read the acl-node-security-profile tag value as IMDS sees it from the VM.
# Returns non-zero if the IMDS request fails or the response cannot be parsed.
imds_tag() {
    local raw
    raw=$(ssh_cmd "curl -sf -H Metadata:true --noproxy '*' \
        'http://169.254.169.254/metadata/instance/compute/tagsList?api-version=2021-02-01'" \
        2>/dev/null) || return 1
    jq -r '.[] | select(.name=="acl-node-security-profile") | .value' <<<"$raw"
}

# Read the kernel boot ID from the VM. Changes on every real boot.
boot_id() {
    ssh_cmd 'cat /proc/sys/kernel/random/boot_id' 2>/dev/null
}

# Set (or remove) the tag on the VM, then wait for in-guest IMDS to converge.
#
# Uses the generic ARM tag endpoint (`az tag update`) rather than
# `az vm update --set tags.…`. The latter round-trips the whole VM resource
# through the Compute RP, so it can fail on unrelated VM properties.
set_selinux_tag() {
    local value="$1"
    local vm_id
    vm_id=$(az vm show --resource-group "$VM_RG" --name "$VM_NAME" --query id -o tsv)
    if [[ -z "$value" ]]; then
        info "Removing acl-node-security-profile tag..."
        az tag update \
            --resource-id "$vm_id" \
            --operation delete \
            --tags "acl-node-security-profile=" \
            --output none
    else
        info "Setting acl-node-security-profile=${value}..."
        az tag update \
            --resource-id "$vm_id" \
            --operation merge \
            --tags "acl-node-security-profile=${value}" \
            --output none
    fi
    info "Waiting for in-guest IMDS to report tag='${value:-<absent>}'..."
    local deadline=$(( $(date +%s) + 60 )) seen
    while (( $(date +%s) < deadline )); do
        seen=$(imds_tag) && [[ "$seen" == "$value" ]] && return 0
        sleep 2
    done
    error "IMDS did not converge to '${value:-<absent>}' within 60s"
    return 1
}

# Reboot the VM and wait until the kernel boot_id changes — proves SSH is back
# AND it's the new kernel (the old sshd can briefly answer mid-shutdown).
reboot_and_wait() {
    local old new
    old=$(boot_id) || { error "Cannot read boot_id — VM unreachable?"; return 1; }
    info "Rebooting VM ${VM_NAME} via SSH (old boot_id=${old})..."
    ssh_cmd "sudo reboot" || true
    local deadline=$(( $(date +%s) + VM_SSH_TIMEOUT ))
    while (( $(date +%s) < deadline )); do
        new=$(boot_id) && [[ "$new" != "$old" ]] && {
            info "VM rebooted (new boot_id=${new})"
            return 0
        }
        sleep 2
    done
    warn "VM did not come back after reboot within ${VM_SSH_TIMEOUT}s — capturing VM diagnostics"

    local diag_dir="${DIAGNOSTICS_DIR:-/tmp}"
    mkdir -p "$diag_dir"
    local prefix="${diag_dir}/$(date +%Y%m%d-%H%M%S)-${VM_NAME}"
    az vm get-instance-view --resource-group "$VM_RG" --name "$VM_NAME" \
        --query 'instanceView.{statuses:statuses,vmAgent:vmAgent.statuses}' \
        -o json 2>&1 | tee "${prefix}-instance-view.json" || true
    az vm boot-diagnostics get-boot-log --resource-group "$VM_RG" --name "$VM_NAME" 2>&1 \
        | jq -r . > "${prefix}-serial.log" || true

    info "Full serial log: ${prefix}-serial.log ($(wc -c <"${prefix}-serial.log") bytes); last 200 lines:"
    tail -200 "${prefix}-serial.log" | sed 's/^/  [serial] /' || true
    info "Diagnostics saved to ${prefix}-{instance-view.json,serial.log}"
    error "VM did not come back after reboot"
    return 1
}

# Assert that SELinux is in the expected mode.
assert_selinux_mode() {
    local expected="$1"
    local actual
    actual=$(get_selinux_mode)
    if [[ "$actual" == "$expected" ]]; then
        info "✅ SELinux mode is '${actual}' (expected '${expected}')"
        return 0
    else
        error "❌ SELinux mode is '${actual}' but expected '${expected}'"
        return 1
    fi
}

# ── Main ───────────────────────────────────────────────────────────

main() {
    parse_validate_args "$@"

    section "SELinux Toggle Test"

    if [[ "$VM_TYPE" != "azure" ]]; then
        info "Skipping SELinux toggle test (requires Azure VM with IMDS)"
        exit 0
    fi

    read_vm_state
    setup_ssh_opts

    info "VM: ${VM_NAME} (RG: ${VM_RG}, IP: ${VM_IP})"

    if ! wait_for_ssh "$VM_IP" "$VM_SSH_TIMEOUT"; then
        error "Cannot reach VM via SSH"
        exit 1
    fi

    local exit_code=0

    # Step 1: Record the starting mode (expected: enforcing).
    section "Step 1: Check initial SELinux mode"
    local initial_mode
    initial_mode=$(get_selinux_mode)
    info "Current SELinux mode: ${initial_mode}"

    if [[ "$initial_mode" != "enforcing" ]]; then
        warn "Expected initial mode 'enforcing' but got '${initial_mode}'"
        warn "The test will still toggle and verify, but the baseline is unexpected."
    fi

    # Step 2: Toggle to permissive (with extra k/v to exercise comma-separated parsing).
    section "Step 2: Toggle SELinux to permissive via IMDS tag"
    set_selinux_tag "selinux=permissive,foo=bar"
    reboot_and_wait
    if ! assert_selinux_mode "permissive"; then
        exit_code=1
    fi

    # Step 3: Toggle back to enforcing.
    section "Step 3: Toggle SELinux back to enforcing via IMDS tag"
    set_selinux_tag "selinux=enforcing"
    reboot_and_wait
    if ! assert_selinux_mode "enforcing"; then
        exit_code=1
    fi

    # Step 4: Clean up — remove the tag, reboot, verify mode stays enforcing.
    section "Step 4: Cleanup — remove tag and reboot"
    set_selinux_tag ""
    reboot_and_wait
    if ! assert_selinux_mode "enforcing"; then
        exit_code=1
    fi

    # Summary
    section "SELinux Toggle Test Summary"
    if [[ "$exit_code" -eq 0 ]]; then
        info "✅ All SELinux toggle assertions passed"
    else
        error "❌ One or more assertions failed"
    fi

    exit "$exit_code"
}

main "$@"
