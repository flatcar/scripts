# Definitions of base sysexts to be built. Used by image.sh and
# image_changes.sh.

if [[ ${1:-} = 'local' ]]; then
    local ciabs_base_sysexts
fi

ciabs_base_sysexts=(
    'containerd-flatcar|app-containers/containerd'
    'docker-flatcar|app-containers/docker&app-containers/docker-cli&app-containers/docker-buildx'
)
