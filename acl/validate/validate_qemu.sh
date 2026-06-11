#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# QEMU validation module for Azure Container Linux (ACL) images.
#
# Provides QEMU/libvirt-specific VM lifecycle functions:
#   - libvirt network management
#   - swtpm workaround
#   - Ignition config generation
#   - VM IP / boot-wait helpers
#   - Serial console command execution (expect-based)
#   - start_vm_qemu (full VM definition & launch)
#
# Sourced by validate_rpm_image.sh (requires validate_common.sh loaded first).
#

# Guard against double-sourcing
[[ -n "${_VALIDATE_QEMU_LOADED:-}" ]] && return 0
_VALIDATE_QEMU_LOADED=1

export LIBVIRT_DEFAULT_URI="${LIBVIRT_DEFAULT_URI:-qemu:///system}"

# ── libvirt network ────────────────────────────────────────────────

ensure_libvirt_network() {
    if ! command -v virsh &>/dev/null; then
        error "virsh not found - required for VM operations"
        if is_azure_linux_3; then
            error "Install with: sudo tdnf install -y libvirt libvirt-client"
        else
            error "Install with: sudo apt-get install -y libvirt-clients"
        fi
        return 1
    fi
    if ! virsh net-info default &>/dev/null 2>&1; then
        warn "libvirt default network not found"
        if [[ -f /usr/share/libvirt/networks/default.xml ]]; then
            info "Attempting to define default network from template..."
            if sudo virsh net-define /usr/share/libvirt/networks/default.xml; then
                info "Default network defined successfully"
            else
                error "Failed to define default network."
                return 1
            fi
        else
            error "Default network template not found"
            return 1
        fi
    fi
    if ! virsh net-info default 2>/dev/null | grep -q 'Active:.*yes'; then
        info "Starting libvirt default network..."
        if sudo virsh net-start default; then
            sudo virsh net-autostart default 2>/dev/null || true
            info "Default network started successfully"
        else
            error "Failed to start default network"
            return 1
        fi
    fi
    return 0
}

# ── swtpm workaround for Azure Linux 3 ────────────────────────────

check_swtpm_azure_linux() {
    if ! is_azure_linux_3; then
        return 0
    fi
    if [[ -x /usr/bin/swtpm ]]; then
        if [[ -L /usr/bin/swtpm ]] && [[ -f /usr/bin/swtpm.orig ]]; then
            debug "swtpm wrapper already installed"
            return 0
        fi
    fi
}

# ── Ignition config generation ─────────────────────────────────────

generate_ignition_config() {
    local config_path="$1"
    local ssh_keys=()
    local password_hash=""
    local private_key=""
    local public_key=""

    if [[ -n "$VM_SSH_AUTHORIZED_KEYS" ]]; then
        if [[ -f "$VM_SSH_AUTHORIZED_KEYS" ]]; then
            while IFS= read -r line; do
                [[ -z "$line" ]] && continue
                [[ "$line" == \#* ]] && continue
                ssh_keys+=("$line")
            done < "$VM_SSH_AUTHORIZED_KEYS"
        else
            ssh_keys+=("$VM_SSH_AUTHORIZED_KEYS")
        fi
    fi

    if [[ ${#ssh_keys[@]} -eq 0 ]]; then
        private_key=$(get_ssh_private_key)
        public_key="${private_key}.pub"
        ssh_keys+=("$(cat "$public_key")")
        info "Using default SSH key: $public_key"
    fi

    if [[ -n "$VM_PASSWORD" ]]; then
        if command -v openssl &>/dev/null; then
            password_hash=$(openssl passwd -6 "$VM_PASSWORD")
        elif command -v mkpasswd &>/dev/null; then
            password_hash=$(mkpasswd -m sha-512 "$VM_PASSWORD")
        else
            warn "Cannot hash password - openssl or mkpasswd not found"
        fi
    fi

    local ssh_keys_json="[]"
    if [[ ${#ssh_keys[@]} -gt 0 ]]; then
        ssh_keys_json="["
        for i in "${!ssh_keys[@]}"; do
            [[ $i -gt 0 ]] && ssh_keys_json+=","
            local escaped_key=$(printf '%s' "${ssh_keys[$i]}" | sed 's/\\/\\\\/g; s/"/\\"/g')
            ssh_keys_json+="\"${escaped_key}\""
        done
        ssh_keys_json+="]"
    fi

    # When booting the test image, inject a systemd unit that symlinks the
    # docker sysext from the OEM partition into /etc/extensions/ so that
    # systemd-sysext picks it up.  This mirrors what mantle's NeedsDocker
    # logic does for kola tests.
    local systemd_section=""
    if [[ "${USE_TEST_IMAGE}" == "true" ]]; then
        info "Test image: injecting docker sysext symlink service into Ignition"
        # Escape the unit content for JSON embedding
        local sysext_link_unit
        sysext_link_unit=$(cat <<'UNIT'
[Unit]\nDescription=Create symlink for docker sysext\nDefaultDependencies=no\nBefore=systemd-sysext.service\nAfter=local-fs.target\n\n[Service]\nType=oneshot\nRemainAfterExit=true\nExecStart=/usr/bin/ln -sf /oem/sysext/docker.raw /etc/extensions/docker.raw\n\n[Install]\nWantedBy=sysinit.target
UNIT
)
        local sysext_dropin
        sysext_dropin=$(cat <<'DROPIN'
[Unit]\nWants=sysext-docker-link.service\nAfter=sysext-docker-link.service
DROPIN
)
        systemd_section=',
  "systemd": {
    "units": [
      {
        "name": "sysext-docker-link.service",
        "enabled": true,
        "contents": "'"${sysext_link_unit}"'"
      },
      {
        "name": "systemd-sysext.service",
        "dropins": [
          {
            "name": "10-wait-for-docker-link.conf",
            "contents": "'"${sysext_dropin}"'"
          }
        ]
      }
    ]
  }'
    fi

    cat > "${config_path}" <<EOF
{
  "ignition": {
    "version": "3.3.0"
  },
  "passwd": {
    "users": [
      {
        "name": "${VM_SSH_USER}",
        "sshAuthorizedKeys": ${ssh_keys_json}$(if [[ -n "$password_hash" ]]; then echo ",
        \"passwordHash\": \"${password_hash}\""; fi)$(if [[ "${VM_SSH_USER}" != "core" ]]; then echo ",
        \"groups\": [\"sudo\"]"; fi)
      }
    ]
  },
  "storage": {
    "files": [
      {
        "path": "/etc/hostname",
        "mode": 420,
        "overwrite": true,
        "contents": {
          "source": "data:,${VM_NAME}"
        }
      }
    ]
  }${systemd_section}
}
EOF
    chmod 644 "${config_path}"
    info "Generated Ignition config: $config_path"
    debug "SSH keys configured: ${#ssh_keys[@]}"
    debug "Password configured: $(if [[ -n "$password_hash" ]]; then echo 'yes'; else echo 'no'; fi)"
}

# ── VM IP helpers ──────────────────────────────────────────────────

get_vm_ip_qemu() {
    local vm_name="$1"
    local ip=""
    ip=$(virsh domifaddr "$vm_name" 2>/dev/null | awk '/ipv4/ {print $4}' | cut -d'/' -f1 | head -1)
    if [[ -n "$ip" ]] && [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "$ip"
        return 0
    fi
    echo ""
}

wait_for_vm_ip_qemu() {
    local vm_name="$1"
    local timeout="${2:-60}"
    info "Waiting for VM to obtain IP address (timeout: ${timeout}s)..."
    local start_time=$(date +%s)
    local end_time=$((start_time + timeout))
    VM_IP=""
    while [[ -z "$VM_IP" ]] && [[ $(date +%s) -lt $end_time ]]; do
        sleep 2
        VM_IP=$(get_vm_ip_qemu "$vm_name")
    done
    if [[ -z "$VM_IP" ]]; then
        error "Failed to get VM IP address after ${timeout}s"
        return 1
    fi
    info "VM IP address: $VM_IP"
    return 0
}

# ── Console helpers ────────────────────────────────────────────────

connect_vm_console_qemu() {
    local vm_name="$1"
    info "Connecting to console..."
    info "Press Ctrl+] to disconnect from console"
    sleep 1
    virsh console "$vm_name"
}

# ── Boot wait ─────────────────────────────────────────────────────

wait_for_vm_boot_qemu() {
    local vm_name="$1"
    local timeout="${2:-300}"

    info "Connecting to VM console (will disconnect on login prompt, timeout: ${timeout}s)..."
    echo "╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝"

    if ! command -v expect &>/dev/null; then
        error "'expect' is required for console monitoring. Install with: apt-get install expect"
        return 1
    fi

    local expect_script=$(mktemp)
    cat > "$expect_script" <<'EXPECT_EOF'
#!/usr/bin/expect -f
set timeout [lindex $argv 0]
set vm_name [lindex $argv 1]

log_user 1

spawn virsh console $vm_name

expect {
    "Escape character" {
        send "\r"
        exp_continue
    }
    -re {(login:|Login:)} {
        puts "\n╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝"
        puts "✓ Login prompt detected - VM boot complete"
        send "\x1d"
        expect eof
        exit 0
    }
    -re {(emergency|Emergency mode|Give root password|Press Enter for maintenance|Entering emergency mode|You are in emergency mode)} {
        puts "\n╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝"
        puts "⚠ EMERGENCY SHELL DETECTED - Switching to interactive console"
        puts "  Press Ctrl+] to disconnect"
        puts "╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝"
        interact
        exit 2
    }
    timeout {
        puts "\n╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝"
        puts "✗ Timeout waiting for login prompt"
        send "\x1d"
        expect eof
        exit 1
    }
    eof {
        puts "\n╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝"
        puts "✗ Console connection lost"
        exit 1
    }
}
EXPECT_EOF

    chmod +x "$expect_script"

    local exit_code
    "$expect_script" "$timeout" "$vm_name"
    exit_code=$?
    rm -f "$expect_script"

    case $exit_code in
        0) return 0 ;;
        2) warn "Emergency shell was detected - user exited interactive console"
           return 2 ;;
        *) return 1 ;;
    esac
}

# ── Console command execution ─────────────────────────────────────

run_command_via_console_qemu() {
    local vm_name="$1"
    local command="$2"
    local user="${3:-root}"
    local password="${4:-}"
    local timeout="${5:-60}"

    if ! command -v expect &>/dev/null; then
        error "'expect' is required for serial console execution. Install with: apt-get install expect"
        return 1
    fi

    info "Running command via serial console: $command"

    local tcl_safe_command="${command//\\/\\\\}"
    tcl_safe_command="${tcl_safe_command//\"/\\\"}"
    tcl_safe_command="${tcl_safe_command//\$/\\\$}"
    tcl_safe_command="${tcl_safe_command//\[/\\\[}"
    tcl_safe_command="${tcl_safe_command//\]/\\\]}"

    local expect_script=$(mktemp)
    cat > "$expect_script" <<EXPECT_EOF
#!/usr/bin/expect -f
set timeout $timeout
log_user 1

spawn virsh console $vm_name

expect {
    "Escape character" {
        send "\r"
    }
    timeout {
        puts "ERROR: Failed to connect to console"
        exit 1
    }
}

expect {
    -re "login:|Login:" {
        send "$user\r"
        expect {
            -re "[Pp]assword:" {
                send "$password\r"
                expect -re "\\$|#"
            }
            -re "\\$|#" {
            }
            timeout {
                puts "ERROR: Timeout after login"
                exit 1
            }
        }
    }
    -re "\\$|#" {
    }
    timeout {
        puts "ERROR: Timeout waiting for login prompt"
        exit 1
    }
}

send "$tcl_safe_command\r"

expect {
    -re "SCRIPT_EXIT_CODE:(\[0-9\]+)" {
        set exit_code \$expect_out(1,string)
        sleep 0.5
        if {\$exit_code != "0"} {
            puts "Command failed with exit code: \$exit_code"
            exit 1
        }
    }
    timeout {
        puts "ERROR: Command timeout"
        exit 1
    }
}

send "\035"
expect eof
exit 0
EXPECT_EOF

    chmod +x "$expect_script"

    local result=0
    "$expect_script" || result=$?

    rm -f "$expect_script"

    return $result
}

# ── Start QEMU VM ─────────────────────────────────────────────────

start_vm_qemu() {
    local vm_image_path="$1"
    local board="$2"

    if [[ "${board}" == "arm64-usr" ]] && ! command -v qemu-system-aarch64 &>/dev/null; then
        error "qemu-system-aarch64 not found. Install with: sudo tdnf install -y qemu-system-aarch64 (AzL) or sudo apt-get install -y qemu-system-arm (Ubuntu)"
        exit 1
    fi

    booted_image_path="${vm_image_path}.booted"
    cp "${vm_image_path}" "${booted_image_path}"

    abs_disk_path="$(cd "$(dirname "${booted_image_path}")" && pwd)/$(basename "${booted_image_path}")"
    local image_dir
    image_dir="$(dirname "${abs_disk_path}")"

    # Derive per-image firmware paths from the image filename.
    # E.g. for "acl_production_qemu_uefi_test_image.img" the base is
    # "acl_production_qemu_uefi_test" → firmware: *_test_secure_efi_code.qcow2
    local img_basename
    img_basename="$(basename "${vm_image_path}")"
    local img_fw_base="${image_dir}/${img_basename%_image.*}"

    local ovmf_code="" ovmf_vars_template="" secure_attr="" smm_feature=""

    if [[ "${board}" == "arm64-usr" ]]; then
        # arm64: Use AAVMF firmware. Prefer system-installed packages (compatible
        # with the host QEMU version) over SDK-built qcow2 firmware which may
        # crash under older QEMU TCG emulation.
        for code_file in \
            "/usr/share/AAVMF/AAVMF_CODE.fd" \
            "/usr/share/edk2/aarch64/QEMU_EFI-pflash.raw" \
            "/usr/share/qemu-efi-aarch64/QEMU_EFI.fd" \
            "${img_fw_base}_efi_code.qcow2" \
            "${image_dir}/acl_production_qemu_uefi_efi_code.qcow2"; do
            if [[ -f "$code_file" ]]; then
                ovmf_code="$code_file"
                break
            fi
        done
        for vars_file in \
            "/usr/share/AAVMF/AAVMF_VARS.fd" \
            "/usr/share/edk2/aarch64/vars-template-pflash.raw" \
            "/usr/share/qemu-efi-aarch64/QEMU_VARS.fd" \
            "${img_fw_base}_efi_vars.qcow2" \
            "${image_dir}/acl_production_qemu_uefi_efi_vars.qcow2"; do
            if [[ -f "$vars_file" ]]; then
                ovmf_vars_template="$vars_file"
                break
            fi
        done
        # arm64 doesn't support SMM-based secure boot
        secure_attr=""
        smm_feature=""
    elif [[ "${SECURE_BOOT_ENABLED}" != "true" ]]; then
        info "Secure boot DISABLED"
        for code_file in \
            "/usr/share/edk2/ovmf/OVMF_CODE.fd" \
            "/usr/share/OVMF/OVMF_CODE_4M.fd" \
            "/usr/share/OVMF/OVMF_CODE.fd"; do
            if [[ -f "$code_file" ]]; then
                ovmf_code="$code_file"
                break
            fi
        done
        for vars_file in \
            "/usr/share/edk2/ovmf/OVMF_VARS.fd" \
            "/usr/share/OVMF/OVMF_VARS_4M.fd" \
            "/usr/share/OVMF/OVMF_VARS.fd"; do
            if [[ -f "$vars_file" ]]; then
                ovmf_vars_template="$vars_file"
                break
            fi
        done
        secure_attr=""
        smm_feature=""
    else
        for code_file in \
            "${img_fw_base}_secure_efi_code.qcow2" \
            "${image_dir}/acl_production_qemu_uefi_secure_efi_code.qcow2" \
            "/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd" \
            "/usr/share/OVMF/OVMF_CODE_4M.secboot.fd" \
            "/usr/share/OVMF/OVMF_CODE.secboot.fd" \
            "/usr/share/edk2/ovmf/OVMF_CODE.secboot.fd" \
            "/usr/share/OVMF/OVMF_CODE_4M.fd" \
            "/usr/share/OVMF/OVMF_CODE.fd"; do
            if [[ -f "$code_file" ]]; then
                ovmf_code="$code_file"
                break
            fi
        done
        for vars_file in \
            "${img_fw_base}_secure_efi_vars.qcow2" \
            "${image_dir}/acl_production_qemu_uefi_secure_efi_vars.qcow2" \
            "/usr/share/edk2/x64/OVMF_VARS.ms.4m.fd" \
            "/usr/share/OVMF/OVMF_VARS_4M.ms.fd" \
            "/usr/share/OVMF/OVMF_VARS.ms.fd" \
            "/usr/share/edk2/x64/OVMF_VARS.secboot.fd" \
            "/usr/share/OVMF/OVMF_VARS_4M.fd" \
            "/usr/share/OVMF/OVMF_VARS.fd" \
            "/usr/share/edk2/x64/OVMF_VARS.4m.fd"; do
            if [[ -f "$vars_file" ]]; then
                ovmf_vars_template="$vars_file"
                break
            fi
        done
        secure_attr=" secure='yes'"
        smm_feature="    <smm state='on'/>"
    fi

    if [[ -z "$ovmf_code" ]] || [[ -z "$ovmf_vars_template" ]]; then
        if [[ "${board}" == "arm64-usr" ]]; then
            error "AAVMF (aarch64 UEFI) firmware files not found"
            error "Install with: sudo tdnf install -y edk2-aarch64"
        else
            error "OVMF firmware files not found"
            error "Install with: sudo apt-get install -y ovmf"
        fi
        exit 1
    fi

    info "Using UEFI firmware:"
    info "  Code: $ovmf_code"
    info "  Vars: $ovmf_vars_template"

    local vm_vars_path="${abs_disk_path}.vars"
    local vm_code_path="${abs_disk_path}.code"

    # Convert qcow2 pflash images to raw — older libvirt/QEMU doesn't support
    # qcow2 format for pflash and reads physical file size instead of virtual size.
    if [[ "$ovmf_code" == *.qcow2 ]]; then
        info "Converting pflash firmware from qcow2 to raw..."
        qemu-img convert -f qcow2 -O raw "$ovmf_code" "$vm_code_path"
        qemu-img convert -f qcow2 -O raw "$ovmf_vars_template" "$vm_vars_path"
    else
        cp "$ovmf_code" "$vm_code_path"
        cp "$ovmf_vars_template" "$vm_vars_path"
    fi

    local ignition_config="/tmp/${VM_NAME}-ignition.ign"
    generate_ignition_config "$ignition_config"

    if [[ "${board}" == "arm64-usr" ]]; then
        _start_vm_qemu_arm64 "${abs_disk_path}" "${vm_vars_path}" "${vm_code_path}" "${ignition_config}"
    else
        _start_vm_qemu_x86_64 "${abs_disk_path}" "${vm_vars_path}" "${vm_code_path}" "${ignition_config}"
    fi
}

_start_vm_qemu_x86_64() {
    local abs_disk_path="$1" vm_vars_path="$2" vm_code_path="$3" ignition_config="$4"
    local tpm_device=""

    if [[ "${SECURE_BOOT_ENABLED}" != "true" ]]; then
        info "Creating x86_64 VM definition WITHOUT secure boot..."
        # TPM requires secure boot to be enabled; skip when it's disabled
        info "Skipping TPM device (secure boot disabled)"
    else
        info "Creating x86_64 VM definition with secure boot..."
        if command -v swtpm &>/dev/null && command -v swtpm_setup &>/dev/null; then
            tpm_device="    <tpm model='tpm-crb'>
                <backend type='emulator' version='2.0'/>
                </tpm>"
            info "swtpm found — adding TPM device to VM"
        else
            info "swtpm not found — skipping TPM device"
        fi
    fi

    cat > /tmp/${VM_NAME}.xml <<EOF
<domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
  <name>${VM_NAME}</name>
  <memory unit='KiB'>2097152</memory>
  <currentMemory unit='KiB'>2097152</currentMemory>
  <vcpu placement='static'>2</vcpu>
  <os>
    <type arch='x86_64' machine='q35'>hvm</type>
    <loader readonly='yes'${secure_attr} type='pflash'>${vm_code_path}</loader>
    <nvram>${vm_vars_path}</nvram>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
${smm_feature}
  </features>
  <cpu mode='host-passthrough'/>
  <clock offset='utc'>
    <timer name='rtc' tickpolicy='catchup'/>
    <timer name='pit' tickpolicy='delay'/>
    <timer name='hpet' present='no'/>
  </clock>
  <pm>
    <suspend-to-mem enabled='no'/>
    <suspend-to-disk enabled='no'/>
  </pm>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='${abs_disk_path}'/>
      <target dev='sda' bus='sata'/>
    </disk>
    <interface type='network'>
      <source network='default'/>
      <model type='virtio'/>
    </interface>
    <console type='pty'>
      <target type='serial'/>
    </console>
${tpm_device}
  </devices>
  <seclabel type='none'/>
  <qemu:commandline>
    <qemu:arg value='-fw_cfg'/>
    <qemu:arg value='name=opt/org.flatcar-linux/config,file=${ignition_config}'/>
  </qemu:commandline>
</domain>
EOF

    _define_and_start_vm "${ignition_config}"
}

_start_vm_qemu_arm64() {
    local abs_disk_path="$1" vm_vars_path="$2" vm_code_path="$3" ignition_config="$4"

    # Detect if we can use KVM (native aarch64 host) or must use TCG (cross-arch)
    local domain_type="qemu"
    local cpu_element="<cpu mode='custom'><model>cortex-a57</model></cpu>"
    local vcpus=2
    if [[ "$(uname -m)" == "aarch64" ]]; then
        domain_type="kvm"
        cpu_element="<cpu mode='host-passthrough'/>"
    fi

    info "Creating arm64 VM definition (${domain_type} mode)..."
    cat > /tmp/${VM_NAME}.xml <<EOF
<domain type='${domain_type}' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
  <name>${VM_NAME}</name>
  <memory unit='KiB'>2097152</memory>
  <currentMemory unit='KiB'>2097152</currentMemory>
  <vcpu placement='static'>${vcpus}</vcpu>
  <os>
    <type arch='aarch64' machine='virt'>hvm</type>
    <loader readonly='yes' type='pflash'>${vm_code_path}</loader>
    <nvram>${vm_vars_path}</nvram>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <gic version='3'/>
  </features>
  ${cpu_element}
  <clock offset='utc'/>
  <devices>
    <emulator>/usr/bin/qemu-system-aarch64</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='${abs_disk_path}'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <interface type='network'>
      <source network='default'/>
      <model type='virtio'/>
    </interface>
    <serial type='pty'>
      <target port='0'/>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
  </devices>
  <seclabel type='none'/>
  <qemu:commandline>
    <qemu:arg value='-fw_cfg'/>
    <qemu:arg value='name=opt/org.flatcar-linux/config,file=${ignition_config}'/>
  </qemu:commandline>
</domain>
EOF

    _define_and_start_vm "${ignition_config}"
}

_define_and_start_vm() {
    local ignition_config="$1"

    info "Defining VM with virsh..."
    virsh define /tmp/${VM_NAME}.xml

    info "Starting VM..."
    virsh start "${VM_NAME}"

    rm -f /tmp/${VM_NAME}.xml
    info "VM '${VM_NAME}' started successfully!"
}
