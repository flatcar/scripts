#!/bin/bash

# Toolchain packages are treated a bit specially, since they take a
# while to build and are generally more complicated to build they are
# only built via catalyst and everyone else installs them as binpkgs.
TOOLCHAIN_PKGS=(
    sys-devel/binutils
    sys-devel/gcc
    sys-kernel/linux-headers
    sys-libs/glibc
)

# Portage profile to use for building out the cross compiler's SYSROOT.
# This is only used as an intermediate step to be able to use the cross
# compiler to build a full native toolchain. Packages are not uploaded.
declare -A CROSS_PROFILES
CROSS_PROFILES["x86_64-cros-linux-gnu"]="coreos-overlay:coreos/amd64/generic"
CROSS_PROFILES["aarch64-cros-linux-gnu"]="coreos-overlay:coreos/arm64/generic"

# Map board names to CHOSTs and portage profiles. This is the
# definitive list, there is assorted code new and old that either
# guesses or hard-code these. All that should migrate to this list.
declare -A BOARD_CHOSTS BOARD_PROFILES
BOARD_CHOSTS["amd64-usr"]="x86_64-cros-linux-gnu"
BOARD_PROFILES["amd64-usr"]="coreos-overlay:coreos/amd64/generic"

BOARD_CHOSTS["arm64-usr"]="aarch64-cros-linux-gnu"
BOARD_PROFILES["arm64-usr"]="coreos-overlay:coreos/arm64/generic"

BOARD_NAMES=( "${!BOARD_CHOSTS[@]}" )

# Declare the above globals as read-only to avoid accidental conflicts.
declare -r \
    TOOLCHAIN_PKGS \
    CROSS_PROFILES \
    BOARD_CHOSTS \
    BOARD_NAMES \
    BOARD_PROFILES

### Generic metadata fetching functions ###

# map CHOST to portage ARCH, list came from crossdev
# Usage: get_portage_arch chost
get_portage_arch() {
    case "$1" in
        aarch64*)   echo arm64;;
        alpha*)     echo alpha;;
        arm*)       echo arm;;
        hppa*)      echo hppa;;
        ia64*)      echo ia64;;
        i?86*)      echo x86;;
        m68*)       echo m68k;;
        mips*)      echo mips;;
        powerpc64*) echo ppc64;;
        powerpc*)   echo ppc;;
        sparc*)     echo sparc;;
        s390*)      echo s390;;
        sh*)        echo sh;;
        x86_64*)    echo amd64;;
        *)          die "Unknown CHOST '$1'";;
    esac
}

# map CHOST to kernel ARCH
# Usage: get_kernel_arch chost
get_kernel_arch() {
    case "$1" in
        aarch64*)   echo arm64;;
        alpha*)     echo alpha;;
        arm*)       echo arm;;
        hppa*)      echo parisc;;
        ia64*)      echo ia64;;
        i?86*)      echo x86;;
        m68*)       echo m68k;;
        mips*)      echo mips;;
        powerpc*)   echo powerpc;;
        sparc64*)   echo sparc64;;
        sparc*)     echo sparc;;
        s390*)      echo s390;;
        sh*)        echo sh;;
        x86_64*)    echo x86;;
        *)          die "Unknown CHOST '$1'";;
    esac
}

get_board_list() {
    local IFS=$'\n\t '
    sort <<<"${BOARD_NAMES[*]}"
}

get_chost_list() {
    local IFS=$'\n\t '
    sort -u <<<"${BOARD_CHOSTS[*]}"
}

get_profile_list() {
    local IFS=$'\n\t '
    sort -u <<<"${BOARD_PROFILES[*]}"
}

# Usage: get_board_arch board [board...]
get_board_arch() {
    local board
    for board in "$@"; do
        get_portage_arch $(get_board_chost "${board}")
    done
}

# Usage: get_board_chost board [board...]
get_board_chost() {
    local board
    for board in "$@"; do
        if [[ ${#BOARD_CHOSTS["$board"]} -ne 0 ]]; then
            echo "${BOARD_CHOSTS["$board"]}"
        else
            die "Unknown board '$board'"
        fi
    done
}

# Usage: get_board_profile board [board...]
get_board_profile() {
    local board
    for board in "$@"; do
        if [[ ${#BOARD_PROFILES["$board"]} -ne 0 ]]; then
            echo "${BOARD_PROFILES["$board"]}"
        else
            die "Unknown board '$board'"
        fi
    done
}

# Usage: get_board_binhost board [version...]
# If no versions are specified the current and SDK versions are used.
get_board_binhost() {
    local board ver
    board="$1"
    shift

    if [[ $# -eq 0 ]]; then
        if [[ "${FLATCAR_BUILD_ID}" =~ ^nightly-.*$ ]] ; then
            # containerised nightly build; this uses [VERSION]-[BUILD_ID] for binpkg url
            set -- "${FLATCAR_VERSION_ID}+${FLATCAR_BUILD_ID}"
        else
            set -- "${FLATCAR_VERSION_ID}"
        fi
    fi

    for ver in "$@"; do
        echo "${FLATCAR_DEV_BUILDS}/boards/${board}/${ver}/pkgs/"
    done
}

get_sdk_arch() {
    get_portage_arch $(uname -m)
}

get_sdk_profile() {
    echo "coreos-overlay:coreos/$(get_sdk_arch)/sdk"
}

get_sdk_libdir() {
    # Looking for LIBDIR_amd64 or similar
    portageq envvar "LIBDIR_$(get_sdk_arch)"
}

# Usage: get_sdk_binhost [version...]
# If no versions are specified the current and SDK versions are used.
get_sdk_binhost() {
    local arch=$(get_sdk_arch) ver
    if [[ $# -eq 0 ]]; then
        set -- "${FLATCAR_SDK_VERSION}"
    fi

    if [ "${FLATCAR_DEV_BUILDS}" != "${SETTING_BINPKG_SERVER_DEV_CONTAINERISED}" ] ; then
        FLATCAR_DEV_BUILDS_SDK="${FLATCAR_DEV_BUILDS_SDK-${FLATCAR_DEV_BUILDS}/sdk}"
    else
        # ALWAYS use a released SDK version, never a nightly, for SDK binpkgs
        FLATCAR_DEV_BUILDS_SDK="${FLATCAR_DEV_BUILDS_SDK-${SETTING_BINPKG_SERVER_PROD}/sdk}"
    fi
    for ver in "$@"; do
        # The entry for /pkgs/ is there if something needs to be reinstalled in the SDK
        # but normally it is not needed because everything is already part of the tarball.
        if curl -Ifs -o /dev/null "${FLATCAR_DEV_BUILDS_SDK}/${arch}/${ver}/pkgs/"; then
            echo "${FLATCAR_DEV_BUILDS_SDK}/${arch}/${ver}/pkgs/"
        fi
    done
}

# Usage: get_cross_pkgs chost [chost2...]
get_cross_pkgs() {
    local cross_chost native_pkg
    for cross_chost in "$@"; do
        for native_pkg in "${TOOLCHAIN_PKGS[@]}"; do
            echo "${native_pkg/*\//cross-${cross_chost}/}"
        done
    done
}

# Get portage arguments restricting toolchains to binary packages only.
get_binonly_args() {
    local pkgs=( "${TOOLCHAIN_PKGS[@]}" $(get_cross_pkgs "$@") )
    echo "${pkgs[@]/#/--useoldpkg-atoms=}" "${pkgs[@]/#/--rebuild-exclude=}"
}

### Toolchain building utilities ###

# Create the crossdev overlay and repos.conf entry.
# crossdev will try to setup this itself but doesn't do everything needed
# to make the newer repos.conf based configuration system happy. This can
# probably go away if crossdev itself is improved.
configure_crossdev_overlay() {
    local root="$1"
    local location="$2"

    # may be called from either catalyst (root) or update_chroot (user)
    local sudo=("env")
    if [[ $(id -u) -ne 0 ]]; then
        sudo=("sudo" "-E")
    fi

    "${sudo[@]}" mkdir -p "${root}${location}/"{profiles,metadata}
    echo "x-crossdev" | \
        "${sudo[@]}" tee "${root}${location}/profiles/repo_name" > /dev/null
    "${sudo[@]}" tee "${root}${location}/metadata/layout.conf" > /dev/null <<EOF
masters = portage-stable coreos-overlay
use-manifests = true
thin-manifests = true
EOF

    "${sudo[@]}" tee "${root}/etc/portage/repos.conf/crossdev.conf" > /dev/null <<EOF
[x-crossdev]
location = ${location}
EOF
}

# Ugly hack to get a dependency list of a set of packages.
# This is required to figure out what to install in the crossdev sysroot.
# Usage: ROOT=/foo/bar _get_dependency_list pkgs... [--portage-opts...]
_get_dependency_list() {
    local pkgs=( ${*/#-*/} )
    local IFS=$'| \t\n'

    PORTAGE_CONFIGROOT="$ROOT" emerge "$@" --pretend \
        --emptytree --onlydeps --quiet | \
        egrep "$ROOT" |
        sed -e 's/[^]]*\] \([^ :]*\).*/=\1/' |
        egrep -v "=($(echo "${pkgs[*]}"))-[0-9]"
}

# Configure a new ROOT
# Values are copied from the environment or the current host configuration.
# Usage: CBUILD=foo-bar-linux-gnu ROOT=/foo/bar SYSROOT=/foo/bar configure_portage coreos-overlay:some/profile
# Note: if using portageq to get CBUILD it must be called before CHOST is set.
_configure_sysroot() {
    local profile="$1"

    # may be called from either catalyst (root) or setup_board (user)
    local sudo=("env")
    if [[ $(id -u) -ne 0 ]]; then
        sudo=("sudo" "-E")
    fi

    "${sudo[@]}" mkdir -p "${ROOT}/etc/portage/"{profile,repos.conf}
    "${sudo[@]}" cp /etc/portage/repos.conf/* "${ROOT}/etc/portage/repos.conf/"
    # set PORTAGE_CONFIGROOT to tell eselect to modify the profile
    # inside /build/<arch>-usr, but set ROOT to /, so eselect will
    # actually find the profile which is outside /build/<arch>-usr,
    # set SYSROOT to / as well, because it must match ROOT
    "${sudo[@]}" PORTAGE_CONFIGROOT=${ROOT} SYSROOT=/ ROOT=/ eselect profile set --force "$profile"

    local coreos_path
    coreos_path=$(portageq get_repo_path "${ROOT}" coreos-overlay)
    "${sudo[@]}" ln -sfT "${coreos_path}/coreos/user-patches" "${ROOT}/etc/portage/patches"

    echo "Writing make.conf for the sysroot ${SYSROOT}, root ${ROOT}"
    "${sudo[@]}" tee "${ROOT}/etc/portage/make.conf" <<EOF
$(portageq envvar -v CHOST CBUILD ROOT DISTDIR PKGDIR)
HOSTCC=\${CBUILD}-gcc
PKG_CONFIG_PATH="\${SYSROOT}/usr/lib/pkgconfig/"
# Enable provenance reporting by default. Produced files are in /usr/share/SLSA
GENERATE_SLSA_PROVENANCE="true"
EOF
}

# Dump crossdev information to determine if configs must be regenerated
_crossdev_info() {
    local cross_chost="$1"; shift
    echo -n "# "; crossdev --version
    echo "# $@"
    crossdev "$@" --show-target-cfg
}

# Gets atoms for emerge and flags for crossdev that will install such
# versions of cross toolchain packages that they will match versions
# of a normal packages that would be installed. That way, if, for
# example, some version of sys-devel/gcc needs to be masked, then
# there is no need to also mask cross-<arch>-cros-linux-gnu/gcc
# package.
#
# Example use:
#
# local -a emerge_atoms=() crossdev_flags=()
# _get_cross_pkgs_for_emerge_and_crossdev x86_64-cros-linux-gnu emerge_atoms crossdev_flags
#
# emerge_atoms will have atoms like "=cross-x86_64-cros-linux-gnu/gcc-11.3.1_p20221209"
#
# crossdev_flags will have flags like "--gcc" "=11.3.1_p20221209"
_get_cross_pkgs_for_emerge_and_crossdev() {
    local cross_chost="${1}"; shift
    local gcpfeac_emerge_atoms_var_name="${1}"; shift
    local gcpfeac_crossdev_pkg_flags_var_name="${1}"; shift
    local -n gcpfeac_emerge_atoms_var_ref="${gcpfeac_emerge_atoms_var_name}"
    local -n gcpfeac_crossdev_pkg_flags_var_ref="${gcpfeac_crossdev_pkg_flags_var_name}"

    local -a all_pkgs=( "${TOOLCHAIN_PKGS[@]}" dev-debug/gdb )
    local -A crossdev_flags_map=(
        [binutils]=--binutils
        [gdb]=--gdb
        [gcc]=--gcc
        [linux-headers]=--kernel
        [glibc]=--libc
    )
    local emerge_report pkg line version pkg_name crossdev_flag

    emerge_report=$(emerge --quiet --pretend --oneshot --nodeps "${all_pkgs[@]}")
    for pkg in "${all_pkgs[@]}"; do
        line=$(grep -o "${pkg}-[^ ]*" <<<"${emerge_report}")
        cross_pkg="${pkg/*\//cross-${cross_chost}/}"
        version="${line#${pkg}-}"
        gcpfeac_emerge_atoms_var_ref+=( "=${cross_pkg}-${version}" )
        pkg_name="${pkg#*/}"
        crossdev_flag="${crossdev_flags_map[${pkg_name}]}"
        gcpfeac_crossdev_pkg_flags_var_ref+=( "${crossdev_flag}" "=${version}" )
    done
}

# Build/install a toolchain w/ crossdev.
# Usage: build_cross_toolchain chost [--portage-opts....]
install_cross_toolchain() {
    local cross_chost="${1}"; shift
    local cross_cfg cross_cfg_data cbuild
    local -a cross_flags emerge_flags emerge_atoms cross_pkg_flags

    emerge_atoms=()
    cross_pkg_flags=()
    _get_cross_pkgs_for_emerge_and_crossdev "${cross_chost}" emerge_atoms cross_pkg_flags
    # build gdb as an extra step, use specific versions of toolchain packages
    cross_flags=( --ex-gdb --target "${cross_chost}" "${cross_pkg_flags[@]}" )
    cross_cfg="/usr/${cross_chost}/etc/portage/${cross_chost}-crossdev"
    cross_cfg_data=$(_crossdev_info "${cross_flags[@]}")
    cbuild=$(portageq envvar CBUILD)
    emerge_flags=( "$@" --binpkg-respect-use=y --update --newuse )

    # Forcing binary packages for toolchain packages breaks crossdev since it
    # prevents it from rebuilding with different use flags during bootstrap.
    local safe_flags=( "${@/#--useoldpkg-atoms=*/}" )
    safe_flags=( "${safe_flags[@]/#--rebuild-exclude=*/}" )
    cross_flags+=( --portage "${safe_flags[*]}" )

    # may be called from either catalyst (root) or upgrade_chroot (user)
    local sudo=("env")
    if [[ $(id -u) -ne 0 ]]; then
        sudo=("sudo" "-E")
    fi

    # crossdev will arbitrarily choose an overlay that it finds first.
    # Force it to use the one created by configure_crossdev_overlay
    local cross_overlay
    cross_overlay=$(portageq get_repo_path / x-crossdev)
    if [[ -n "${cross_overlay}" ]]; then
        cross_flags+=( --ov-output "${cross_overlay}" )
    else
        echo "No x-crossdev overlay found!" >&2
        return 1
    fi

    # Only call crossdev to regenerate configs if something has changed
    if [[ ! -d "${cross_overlay}/cross-${cross_chost}" ]] || ! cmp --quiet - "${cross_cfg}" <<<"${cross_cfg_data}"
    then
        "${sudo[@]}" crossdev "${cross_flags[@]}" --init-target
        "${sudo[@]}" tee "${cross_cfg}" <<<"${cross_cfg_data}" >/dev/null
    fi

    # Check if any packages need to be built from source. If so do a full
    # bootstrap via crossdev, otherwise just install the binaries (if enabled).
    # It is ok to build gdb from source outside of crossdev.
    if emerge "${emerge_flags[@]}" \
        --pretend "${emerge_atoms[@]}" | grep -q '^\[ebuild'
    then
        echo "Doing a full bootstrap via crossdev"
        "${sudo[@]}" crossdev "${cross_flags[@]}" --stage4
    else
        echo "Installing existing binaries"
        "${sudo[@]}" emerge "${emerge_flags[@]}" "${emerge_atoms[@]}"
    fi

    # Setup environment and wrappers for our shiny new toolchain
    binutils_set_latest_profile "${cross_chost}"
    gcc_set_latest_profile "${cross_chost}"
}

# Build/install toolchain dependencies into the cross sysroot for a
# given CHOST. This is required to build target board toolchains since
# the target sysroot under /build/$BOARD is incomplete at this stage.
# Usage: build_cross_toolchain chost [--portage-opts....]
install_cross_libs() {
    local cross_chost="$1"; shift
    local ROOT="/usr/${cross_chost}"
    local package_provided="$ROOT/etc/portage/profile/package.provided"

    # may be called from either catalyst (root) or setup_board (user)
    local sudo=("env")
    if [[ $(id -u) -ne 0 ]]; then
        sudo=("sudo" "-E")
    fi

    CBUILD="$(portageq envvar CBUILD)" \
        CHOST="${cross_chost}" \
        ROOT="$ROOT" \
        SYSROOT="$ROOT" \
        _configure_sysroot "${CROSS_PROFILES[${cross_chost}]}"

    # In order to get a dependency list we must calculate it before
    # updating package.provided. Otherwise portage will no-op.
    "${sudo[@]}" rm -f "${package_provided}/cross-${cross_chost}"
    local cross_deps=$(ROOT="$ROOT" SYSROOT="$ROOT" _get_dependency_list \
        "$@" "${TOOLCHAIN_PKGS[@]}" | "${sudo[@]}" tee \
        "$ROOT/etc/portage/cross-${cross_chost}-depends")

    # Add toolchain to packages.provided since they are on the host system
    if [[ -f "${package_provided}" ]]; then
        # emerge-wrapper is trying a similar trick but doesn't work
        "${sudo[@]}" rm -f "${package_provided}"
    fi
    "${sudo[@]}" mkdir -p "${package_provided}"
    local native_pkg cross_pkg cross_pkg_version
    for native_pkg in "${TOOLCHAIN_PKGS[@]}"; do
        cross_pkg="${native_pkg/*\//cross-${cross_chost}/}"
        cross_pkg_version=$(portageq match / "${cross_pkg}")
        echo "${native_pkg%/*}/${cross_pkg_version#*/}"
    done | "${sudo[@]}" tee "${package_provided}/cross-${cross_chost}" >/dev/null

    # OK, clear as mud? Install those dependencies now!
    PORTAGE_CONFIGROOT="$ROOT" "${sudo[@]}" emerge --root="$ROOT" --sysroot="$ROOT" "$@" --update $cross_deps
}

install_cross_rust() {
    # may be called from either catalyst (root) or upgrade_chroot (user)
    local sudo=("env")
    if [[ $(id -u) -ne 0 ]]; then
        sudo=("sudo" "-E")
    fi

    echo "Installing dev-lang/rust with (potentially outdated) cross targets."
    "${sudo[@]}" emerge "${emerge_flags[@]}" --binpkg-respect-use=y --update dev-lang/rust

    [[
       -d /usr/lib/rustlib/x86_64-unknown-linux-gnu &&
       -d /usr/lib/rustlib/aarch64-unknown-linux-gnu
    ]] && return

    echo "Rebuilding dev-lang/rust with updated cross targets."
    "${sudo[@]}" emerge "${emerge_flags[@]}" --usepkg=n dev-lang/rust
}

# Update to the latest binutils profile for a given CHOST if required
# Usage: binutils_set_latest_profile chost
binutils_set_latest_profile() {
    local latest="$@-latest"
    if [[ -z "${latest}" ]]; then
        echo "Failed to detect latest binutils profile for $1" >&2
        return 1
    fi

    # may be called from either catalyst (root) or upgrade_chroot (user)
    local sudo=("env")
    if [[ $(id -u) -ne 0 ]]; then
        sudo=("sudo" "-E")
    fi

    "${sudo[@]}" binutils-config "${latest}"
}

# Get the latest GCC profile for a given CHOST
# The extra flag can be blank, hardenednopie, and so on. See gcc-config -l
# Usage: gcc_get_latest_profile chost [extra]
gcc_get_latest_profile() {
    local prefix="${1}-"
    local suffix="${2+-$2}"
    local status
    gcc-config -l | cut -d' ' -f3 | grep "^${prefix}[0-9\\.]*${suffix}$" | tail -n1

    # return 1 if anything in the above pipe failed
    for status in ${PIPESTATUS[@]}; do
        [[ $status -eq 0 ]] || return 1
    done
}

# Update to the latest GCC profile for a given CHOST if required
# The extra flag can be blank, hardenednopie, and so on. See gcc-config -l
# Usage: gcc_set_latest_profile chost [extra]
gcc_set_latest_profile() {
    local latest=$(gcc_get_latest_profile "$@")
    if [[ -z "${latest}" ]]; then
        echo "Failed to detect latest gcc profile for $1" >&2
        return 1
    fi

    # may be called from either catalyst (root) or upgrade_chroot (user)
    local sudo=("env")
    if [[ $(id -u) -ne 0 ]]; then
        sudo=("sudo" "-E")
    fi

    "${sudo[@]}" gcc-config "${latest}"
}
