#!/bin/sh

SCRIPT_DIR="$(dirname "$0")"
VM_BOARD=
VM_NAME=
VM_UUID=
VM_IMAGE=
VM_KERNEL=
VM_INITRD=
VM_MEMORY=
VM_CDROM=
VM_PFLASH_RO=
VM_PFLASH_RW=
VM_NCPUS="$(getconf _NPROCESSORS_ONLN)"
SSH_PORT=2222
SSH_KEYS=""
CLOUD_CONFIG_FILE=""
IGNITION_CONFIG_FILE=""
CONFIG_IMAGE=""
SWTPM_DIR=
SAFE_ARGS=0
USAGE="Usage: $0 [-a authorized_keys] [--] [qemu options...]
Options:
    -i FILE     File containing an Ignition config
                (needs \"-append 'flatcar.first_boot=1'\" for already-booted or PXE images)
    -u FILE     Cloudinit user-data as either a cloud config or script.
    -c FILE     Config drive as an iso or fat filesystem image.
    -a FILE     SSH public keys for login access. [~/.ssh/id_{dsa,rsa}.pub]
    -p PORT     The port on localhost to map to the VM's sshd. [2222]
    -I FILE     Set a custom image file.
    -M MB       Set VM memory in MBs.
    -T DIR      Add a software TPM2 device through swtpm which stores secrets
                and the control socket to the given directory. This may need
                some configuration first with 'swtpm_setup --tpmstate DIR ...'
                (see https://github.com/stefanberger/swtpm/wiki/Certificates-created-by-swtpm_setup).
    -R FILE     Set up pflash ro content, e.g., for UEFI (with -W).
    -W FILE     Set up pflash rw content, e.g., for UEFI (with -R).
    -K FILE     Set kernel for direct boot used to simulate a PXE boot (with -r).
    -r FILE     Set initrd for direct boot used to simulate a PXE boot (with -K).
    -s          Safe settings: single simple cpu and no KVM.
    -h          this ;-)

This script is a wrapper around qemu for starting Flatcar virtual machines.
The -a option may be used to specify a particular ssh public key to give
login access to. If -a is not provided ~/.ssh/id_{dsa,rsa}.pub is used.
If no public key is provided or found the VM will still boot but you may
be unable to login unless you built the image yourself after setting a
password for the core user with the 'set_shared_user_password.sh' script
or provide the option \"-append 'flatcar.autologin'\".

Any arguments after -a and -p will be passed through to qemu, -- may be
used as an explicit separator. See the qemu(1) man page for more details.
"

die(){
	echo "${1}"
	exit 1
}

check_conflict() {
    if [ -n "${CLOUD_CONFIG_FILE}${CONFIG_IMAGE}${SSH_KEYS}" ]; then
        echo "The -u -c and -a options cannot be combined!" >&2
        exit 1
    fi
}

while [ $# -ge 1 ]; do
    case "$1" in
        -i|-ignition-config)
            IGNITION_CONFIG_FILE="$2"
            shift 2 ;;
        -u|-user-data)
            check_conflict
            CLOUD_CONFIG_FILE="$2"
            shift 2 ;;
        -c|-config-drive)
            check_conflict
            CONFIG_IMAGE="$2"
            shift 2 ;;
        -a|-authorized-keys)
            check_conflict
            SSH_KEYS="$2"
            shift 2 ;;
        -p|-ssh-port)
            SSH_PORT="$2"
            shift 2 ;;
        -s|-safe)
            SAFE_ARGS=1
            shift ;;
        -I|-image-file)
            VM_IMAGE="$2"
            shift 2 ;;
        -M|-memory)
            VM_MEMORY="$2"
            shift 2 ;;
        -T|-tpm)
            SWTPM_DIR="$2"
            shift 2 ;;
        -R|-pflash-ro)
            VM_PFLASH_RO="$2"
            shift 2 ;;
        -W|-pflash-rw)
            VM_PFLASH_RW="$2"
            shift 2 ;;
        -K|-kernel-file)
            VM_KERNEL="$2"
            shift 2 ;;
        -r|-initrd-file)
            VM_INITRD="$2"
            shift 2 ;;
        -v|-verbose)
            set -x
            shift ;;
        -h|-help|--help)
            echo "$USAGE"
            exit ;;
        --)
            shift
            break ;;
        *)
            break ;;
    esac
done


find_ssh_keys() {
    if [ -S "$SSH_AUTH_SOCK" ]; then
        ssh-add -L
    fi
    for default_key in ~/.ssh/id_*.pub; do
        if [ ! -f "$default_key" ]; then
            continue
        fi
        cat "$default_key"
    done
}

write_ssh_keys() {
    echo "#cloud-config"
    echo "ssh_authorized_keys:"
    sed -e 's/^/ - /'
}

if [ -n "${SWTPM_DIR}" ]; then
    mkdir -p "${SWTPM_DIR}"
    if ! command -v swtpm >/dev/null; then
        echo "$0: swtpm command not found!" >&2
        exit 1
    fi
    case "${VM_BOARD}" in
        amd64-usr)
            TPM_DEV=tpm-tis ;;
        arm64-usr)
            TPM_DEV=tpm-tis-device ;;
        *) die "Unsupported arch" ;;
    esac
    SWTPM_SOCK="${SWTPM_DIR}/socket"
    swtpm socket --tpmstate "dir=${SWTPM_DIR}" --ctrl "type=unixio,path=${SWTPM_SOCK},terminate" --tpm2 &
    SWTPM_PROC=$!
    PARENT=$$
    # The swtpm process exits if qemu disconnects but if we never started qemu because
    # this script fails or qemu failed to start, we need to kill the process.
    # The EXIT trap is already in use by the config drive cleanup and anyway doesn't work with kill -9.
    (while [ -e "/proc/${PARENT}" ]; do sleep 1; done; kill "${SWTPM_PROC}" 2>/dev/null; exit 0) &
    set -- -chardev "socket,id=chrtpm,path=${SWTPM_SOCK}" -tpmdev emulator,id=tpm0,chardev=chrtpm -device "${TPM_DEV}",tpmdev=tpm0 "$@"
fi

if [ -z "${CONFIG_IMAGE}" ]; then
    CONFIG_DRIVE=$(mktemp -d)
    ret=$?
    if [ "$ret" -ne 0 ] || [ ! -d "$CONFIG_DRIVE" ]; then
        echo "$0: mktemp -d failed!" >&2
        exit 1
    fi
    # shellcheck disable=SC2064
    trap "rm -rf '$CONFIG_DRIVE'" EXIT
    mkdir -p "${CONFIG_DRIVE}/openstack/latest"


    if [ -n "$SSH_KEYS" ]; then
        if [ ! -f "$SSH_KEYS" ]; then
            echo "$0: SSH keys file not found: $SSH_KEYS" >&2
            exit 1
        fi
        SSH_KEYS_TEXT=$(cat "$SSH_KEYS")
        ret=$?
        if [ "$ret" -ne 0 ] || [ -z "$SSH_KEYS_TEXT" ]; then
            echo "$0: Failed to read SSH keys from $SSH_KEYS" >&2
            exit 1
        fi
        echo "$SSH_KEYS_TEXT" | write_ssh_keys > \
            "${CONFIG_DRIVE}/openstack/latest/user_data"
    elif [ -n "${CLOUD_CONFIG_FILE}" ]; then
        cp "${CLOUD_CONFIG_FILE}" "${CONFIG_DRIVE}/openstack/latest/user_data"
        ret=$?
        if [ "$ret" -ne 0 ]; then
            echo "$0: Failed to copy cloudinit file from $CLOUD_CONFIG_FILE" >&2
            exit 1
        fi
    else
        find_ssh_keys | write_ssh_keys > \
            "${CONFIG_DRIVE}/openstack/latest/user_data"
    fi
fi

# Start assembling our default command line arguments
if [ "${SAFE_ARGS}" -eq 1 ]; then
    # Disable KVM, for testing things like UEFI which don't like it
    set -- -machine accel=tcg "$@"
else
    case "${VM_BOARD}+$(uname -m)" in
        amd64-usr+x86_64)
            set -- -global ICH9-LPC.disable_s3=1 \
                   -global driver=cfi.pflash01,property=secure,value=on \
                   "$@"
            # Emulate the host CPU closely in both features and cores.
            set -- -machine q35,accel=kvm:hvf:tcg,smm=on -cpu host -smp "${VM_NCPUS}" "$@"
            ;;
        amd64-usr+*)
            set -- -machine q35 -cpu kvm64 -smp 1 -nographic "$@" ;;
        arm64-usr+aarch64)
            set -- -machine virt,accel=kvm,gic-version=3 -cpu host -smp "${VM_NCPUS}" -nographic "$@" ;;
        arm64-usr+*)
            if test "${VM_NCPUS}" -gt 4 ; then
                VM_NCPUS=4
            elif test "${VM_NCPUS}" -gt 2 ; then
                VM_NCPUS=2
            fi
            set -- -machine virt -cpu cortex-a57 -smp "${VM_NCPUS}" -nographic "$@" ;;
        *)
            die "Unsupported arch" ;;
    esac
fi

# ${CONFIG_DRIVE} or ${CONFIG_IMAGE} will be mounted in Flatcar as /media/configdrive
if [ -n "${CONFIG_DRIVE}" ]; then
    set -- \
        -fsdev local,id=conf,security_model=none,readonly=on,path="${CONFIG_DRIVE}" \
        -device virtio-9p-pci,fsdev=conf,mount_tag=config-2 "$@"
fi

if [ -n "${CONFIG_IMAGE}" ]; then
    set -- -drive if=virtio,file="${CONFIG_IMAGE}" "$@"
fi

if [ -n "${VM_IMAGE}" ]; then
    case "${VM_BOARD}" in
        amd64-usr)
            set -- -drive if=virtio,file="${SCRIPT_DIR}/${VM_IMAGE}" "$@" ;;
        arm64-usr)
            set -- -drive if=none,id=blk,file="${SCRIPT_DIR}/${VM_IMAGE}" \
            -device virtio-blk-device,drive=blk "$@"
            ;;
        *) die "Unsupported arch" ;;
    esac
fi

if [ -n "${VM_KERNEL}" ]; then
    set -- -kernel "${SCRIPT_DIR}/${VM_KERNEL}" "$@"
fi

if [ -n "${VM_INITRD}" ]; then
    set -- -initrd "${SCRIPT_DIR}/${VM_INITRD}" "$@"
fi

if [ -n "${VM_UUID}" ]; then
    set -- -uuid "$VM_UUID" "$@"
fi

if [ -n "${VM_CDROM}" ]; then
    set -- -boot order=d \
	-drive file="${SCRIPT_DIR}/${VM_CDROM}",media=cdrom,format=raw "$@"
fi

if [ -n "${VM_PFLASH_RO}" ] && [ -n "${VM_PFLASH_RW}" ]; then
    set -- \
        -drive if=pflash,unit=0,file="${SCRIPT_DIR}/${VM_PFLASH_RO}",format=qcow2,readonly=on \
        -drive if=pflash,unit=1,file="${SCRIPT_DIR}/${VM_PFLASH_RW}",format=qcow2 "$@"
fi

if [ -n "${IGNITION_CONFIG_FILE}" ]; then
    set -- -fw_cfg name=opt/org.flatcar-linux/config,file="${IGNITION_CONFIG_FILE}" "$@"
fi

case "${VM_BOARD}" in
    amd64-usr)
        # Default to KVM, fall back on full emulation
        qemu-system-x86_64 \
            -name "$VM_NAME" \
            -m ${VM_MEMORY} \
            -netdev user,id=eth0,hostfwd=tcp::"${SSH_PORT}"-:22,hostname="${VM_NAME}" \
            -device virtio-net-pci,netdev=eth0 \
            -object rng-random,filename=/dev/urandom,id=rng0 -device virtio-rng-pci,rng=rng0 \
            "$@"
        ;;
    arm64-usr)
        qemu-system-aarch64 \
            -name "$VM_NAME" \
            -m ${VM_MEMORY} \
            -netdev user,id=eth0,hostfwd=tcp::"${SSH_PORT}"-:22,hostname="${VM_NAME}" \
            -device virtio-net-device,netdev=eth0 \
            -object rng-random,filename=/dev/urandom,id=rng0 -device virtio-rng-pci,rng=rng0 \
            "$@"
        ;;
    *) die "Unsupported arch" ;;
esac

exit $?
