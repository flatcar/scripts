if [[ ${1:-} = 'local' ]]; then
    local -a COMMON_OEMIDS ARM64_ONLY_OEMIDS AMD64_ONLY_OEMIDS OEMIDS
    shift
fi

COMMON_OEMIDS=(
    ami
    azure
    openstack
    packet
    qemu
)

ARM64_ONLY_OEMIDS=(
)

AMD64_ONLY_OEMIDS=(
    digitalocean
    vmware
)

OEMIDS=(
    "${COMMON_OEMIDS[@]}"
    "${ARM64_ONLY_OEMIDS[@]}"
    "${AMD64_ONLY_OEMIDS[@]}"
)

if [[ ${1:-} = 'only-oemids' ]]; then
    unset COMMON_OEMIDS ARM64_ONLY_OEMIDS AMD64_ONLY_OEMIDS
fi
