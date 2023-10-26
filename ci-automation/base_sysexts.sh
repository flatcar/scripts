# Definitions of base sysexts to be built, for each arch. Used by
# image.sh and image_changes.sh.

if [[ ${1:-} = 'local' ]]; then
    local amd64_base_sysexts arm64_base_sysexts
fi

amd64_base_sysexts=(
    'containerd-flatcar:app-containers/containerd'
    'docker-flatcar:app-containers/docker'
)

arm64_base_sysexts=(
    'containerd-flatcar:app-containers/containerd'
    'docker-flatcar:app-containers/docker'
)
