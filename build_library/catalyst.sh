#!/bin/bash
# Copyright (c) 2013 The CoreOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# common.sh should be sourced first
[[ -n "${DEFAULT_BUILD_ROOT}" ]] || exit 1
. "${SCRIPTS_DIR}/sdk_lib/sdk_util.sh" || exit 1
. "${BUILD_LIBRARY_DIR}/toolchain_util.sh" || exit 1

# Default option values, may be provided before including this file
: ${TYPE:="coreos-sdk"}
: ${ARCH:=$(get_sdk_arch)}
: ${DEFAULT_CATALYST_ROOT:="${DEFAULT_BUILD_ROOT}/catalyst"}
: ${DEFAULT_SEED:=${FLATCAR_SDK_TARBALL_PATH}}
: ${DEFAULT_PROFILE:=$(get_sdk_profile)}
# Set to something like "stage4" to restrict what to build
# FORCE_STAGES=

# Values set in catalyst_init, don't use till after calling it
CATALYST_ROOT=
DEBUG=()
BUILDS=
BINPKGS=
DISTDIR=
TEMPDIR=
STAGES=

DEFINE_string catalyst_root "${DEFAULT_CATALYST_ROOT}" \
    "Path to directory for all catalyst images and other files."
DEFINE_string portage_stable "${SRC_ROOT}/third_party/portage-stable" \
    "Path to the portage-stable git checkout."
DEFINE_string coreos_overlay "${SRC_ROOT}/third_party/coreos-overlay" \
    "Path to the coreos-overlay git checkout."
DEFINE_string seed_tarball "${DEFAULT_SEED}" \
    "Path to an existing stage tarball to start from."
DEFINE_string version "${FLATCAR_VERSION}" \
    "Version to use for portage snapshot and stage tarballs."
DEFINE_string profile "${DEFAULT_PROFILE}" \
    "Portage profile, may be prefixed with repo:"
DEFINE_boolean rebuild ${FLAGS_FALSE} \
    "Rebuild and overwrite stages that already exist."
DEFINE_boolean debug ${FLAGS_FALSE} "Enable verbose output from catalyst."

#####################
# CONFIG DEFINITIONS
#
# These templates can be expanded by calling the wrapping function after
# catalyst_init has been called. They are written as files in write_configs
# rather than passed as command line args for easier inspection and debugging
# by hand, catalyst can get tricky.
######################

# Values to write to catalyst.conf
catalyst_conf() {
cat <<EOF
# catalyst.conf
digests=["md5", "sha1", "sha512", "blake2b"]
options=["pkgcache"]
sharedir="/usr/share/catalyst"
storedir="$CATALYST_ROOT"
distdir="$DISTDIR"
envscript="$TEMPDIR/catalystrc"
port_logdir="$CATALYST_ROOT/log"
repo_basedir="/mnt/host/source/src/third_party"
repo_name="portage-stable"
EOF
}

catalystrc() {
local load=$((NUM_JOBS * 2))
cat <<EOF
export TERM='${TERM}'
export MAKEOPTS='--jobs=${NUM_JOBS} --load-average=${load}'
export EMERGE_DEFAULT_OPTS="--verbose \$MAKEOPTS"
export PORTAGE_USERNAME=portage
export PORTAGE_GRPNAME=portage
export GENTOO_MIRRORS='$(portageq envvar GENTOO_MIRRORS)'
export ac_cv_posix_semaphores_enabled=yes
EOF
}

# Common values for all stage spec files
catalyst_stage_default() {
cat <<EOF
target: stage$1
subarch: $ARCH
rel_type: $TYPE
portage_confdir: $TEMPDIR/portage
repos: $FLAGS_coreos_overlay
keep_repos: portage-stable coreos-overlay
profile: $FLAGS_profile
snapshot_treeish: $FLAGS_version
version_stamp: $FLAGS_version
cflags: -O2 -pipe
cxxflags: -O2 -pipe
ldflags: -Wl,-O2 -Wl,--as-needed
source_subpath: ${SEED}
EOF
}

# Config values for each stage
catalyst_stage1() {
cat <<EOF
# stage1 packages aren't published, save in tmp
pkgcache_path: ${TEMPDIR}/stage1-${ARCH}-packages
update_seed: yes
update_seed_command: --exclude cross-*-cros-linux-gnu/* --exclude dev-lang/rust --exclude dev-lang/rust-bin --ignore-world y --ignore-built-slot-operator-deps y @changed-subslot
EOF
catalyst_stage_default 1
}

catalyst_stage3() {
cat <<EOF
pkgcache_path: $BINPKGS
EOF
catalyst_stage_default 3
}

catalyst_stage4() {
die "The calling script should redefine this function!"
}

##########################
# END CONFIG DEFINITIONS #
##########################

# catalyst_init
# Parses command ling arguments, validates them, and sets up environment
# for the rest of the functions here. Should be the first thing called
# after any script specific shflags DEFINE_* statements.
# Usage: catalyst_init "$@"
catalyst_init() {
    FLAGS "$@" || exit 1
    switch_to_strict_mode
    eval set -- "${FLAGS_ARGV}"

    local stage

    if [[ -n "${FORCE_STAGES}" ]]; then
        STAGES="${FORCE_STAGES}"
    elif [[ $# -eq 0 ]]; then
        STAGES="stage1 stage3 stage4"
    else
        for stage in "$@"; do
            if [[ ! "$stage" =~ ^stage[134]$ ]]; then
                die_notrace "Invalid target name $stage"
            fi
        done
        STAGES="$*"
    fi

    if [[ $(id -u) != 0 ]]; then
        die_notrace "This script must be run as root."
    fi

    if ! command -v catalyst >/dev/null 2>&1; then
        die_notrace "catalyst not found, not installed or bad PATH?"
    fi

    # Before doing anything else, ensure we have at least Catalyst 4.
    if catalyst --version | grep -q "Catalyst [0-3]\."; then
        emerge --verbose "--jobs=${NUM_JOBS}" --oneshot ">=dev-util/catalyst-4" || exit 1
    fi

    DEBUG=()
    if [[ ${FLAGS_debug} -eq ${FLAGS_TRUE} ]]; then
        DEBUG=("--debug")
    fi

    # Create output dir, expand path for easy comparison later
    mkdir -p "$FLAGS_catalyst_root"
    CATALYST_ROOT=$(readlink -f "$FLAGS_catalyst_root")

    BUILDS="$CATALYST_ROOT/builds/$TYPE"
    BINPKGS="$CATALYST_ROOT/packages/$TYPE"
    TEMPDIR="$CATALYST_ROOT/tmp/$TYPE"
    DISTDIR="$CATALYST_ROOT/distfiles"

    # automatically download the current SDK if it is the seed tarball.
    if [[ "$FLAGS_seed_tarball" == "${FLATCAR_SDK_TARBALL_PATH}" ]]; then
        sdk_download_tarball
    fi

    # confirm seed exists
    if [[ ! -f "$FLAGS_seed_tarball" ]]; then
        die_notrace "Seed tarball not found: $FLAGS_seed_tarball"
    fi

    # so far so good, expand path to work with weird comparison code below
    FLAGS_seed_tarball=$(readlink -f "$FLAGS_seed_tarball")

    if [[ ! "$FLAGS_seed_tarball" =~ .\.tar\.(bz2|xz) ]]; then
        die_notrace "Seed tarball doesn't end in .tar.bz2 or .tar.xz :-/"
    fi

    # catalyst is obnoxious and wants the $TYPE/stage3-$VERSION part of the
    # path, not the real path to the seed tarball. (Because it could be a
    # directory under $TEMPDIR instead, aka the SEEDCACHE feature.)
    if [[ "$FLAGS_seed_tarball" =~ "$CATALYST_ROOT/builds/".* ]]; then
        SEED="${FLAGS_seed_tarball#$CATALYST_ROOT/builds/}"
        SEED="${SEED%.tar.*}"
    else
        mkdir -p "$CATALYST_ROOT/builds/seed"
        cp -n "$FLAGS_seed_tarball" "$CATALYST_ROOT/builds/seed"
        SEED="seed/${FLAGS_seed_tarball##*/}"
        SEED="${SEED%.tar.*}"
    fi
}

write_configs() {
    info "Creating output directories..."
    mkdir -m 775 -p "$DISTDIR"
    chown portage:portage "$DISTDIR"
    info "Writing out catalyst configs..."
    info "    catalyst.conf"
    catalyst_conf > "$TEMPDIR/catalyst.conf"
    info "    catalystrc"
    catalystrc > "$TEMPDIR/catalystrc"
    info "    stage1.spec"
    catalyst_stage1 > "$TEMPDIR/stage1.spec"

    info "Configuring Portage..."
    cp -r "${BUILD_LIBRARY_DIR}"/portage/ "${TEMPDIR}/"

    ln -sfT '/mnt/host/source/src/third_party/coreos-overlay/coreos/user-patches' \
        "${TEMPDIR}"/portage/patches
}

build_stage() {
    local stage catalyst_conf target_tarball

    stage="$1"
    catalyst_conf="$TEMPDIR/catalyst.conf"
    target_tarball="${stage}-${ARCH}-${FLAGS_version}.tar.bz2"

    if [[ -f "$BUILDS/${target_tarball}" && $FLAGS_rebuild == $FLAGS_FALSE ]]
    then
        info "Skipping $stage, $target_tarball already exists."
        return
    fi

    info "Starting $stage"
    catalyst \
        "${DEBUG[@]}" \
        --verbose \
        --config "$TEMPDIR/catalyst.conf" \
        --file "$TEMPDIR/${stage}.spec"
    # Catalyst does not clean up after itself...
    rm -rf "$TEMPDIR/$stage-${ARCH}-${FLAGS_version}"
    ln -sf "$stage-${ARCH}-${FLAGS_version}.tar.bz2" \
        "$BUILDS/$stage-${ARCH}-latest.tar.bz2"
    info "Finished building $target_tarball"
}

build_snapshot() {
    local repo_dir snapshot snapshots_dir snapshot_path

    repo_dir=${1:-"${FLAGS_portage_stable}"}
    snapshot=${2:-"${FLAGS_version}"}
    snapshots_dir="${CATALYST_ROOT}/snapshots"
    snapshot_path="${snapshots_dir}/portage-stable-${snapshot}.sqfs"
    if [[ -f ${snapshot_path} && $FLAGS_rebuild == $FLAGS_FALSE ]]
    then
        info "Skipping snapshot, ${snapshot_path} exists"
    else
        info "Creating snapshot ${snapshot_path}"
        mkdir -p "${snapshot_path%/*}"
        tar -c -C "${repo_dir}" . | tar2sqfs "${snapshot_path}" -q -f -j1 -c gzip
    fi
}

catalyst_build() {
    # assert catalyst_init has been called
    [[ -n "$CATALYST_ROOT" ]]

    info "Building stages: $STAGES"
    write_configs
    build_snapshot

    local used_seed

    used_seed=0
    if [[ "$STAGES" =~ stage1 ]]; then
        build_stage stage1
        used_seed=1
    fi

    if [[ "$STAGES" =~ stage3 ]]; then
        if [[ $used_seed -eq 1 ]]; then
            SEED="${TYPE}/stage1-${ARCH}-latest"
        fi
        info "    stage3.spec"
        catalyst_stage3 > "$TEMPDIR/stage3.spec"
        build_stage stage3
        used_seed=1
    fi

    if [[ "$STAGES" =~ stage4 ]]; then
        if [[ $used_seed -eq 1 ]]; then
            SEED="${TYPE}/stage3-${ARCH}-latest"
        fi
        info "    stage4.spec"
        catalyst_stage4 > "$TEMPDIR/stage4.spec"
        build_stage stage4
        used_seed=1
    fi

    # Cleanup snapshots, we don't use them
    rm -rf "$CATALYST_ROOT/snapshots/${FLAGS_portage_stable##*/}-${FLAGS_version}.sqfs"*
}
