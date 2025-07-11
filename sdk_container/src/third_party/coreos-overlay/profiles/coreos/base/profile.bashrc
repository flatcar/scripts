# Dumping ground for build-time helpers to utilize since SYSROOT/tmp/
# can be nuked at any time.
CROS_BUILD_BOARD_TREE="${SYSROOT}/build"
CROS_BUILD_BOARD_BIN="${CROS_BUILD_BOARD_TREE}/bin"

CROS_ADDONS_TREE="/mnt/host/source/src/third_party/coreos-overlay/coreos"

# Are we merging for the board sysroot, or for the SDK, or for
# the images? Returns a string in a passed variable:
#
#  - sdk (the SDK)
#  - generic-board (board sysroot)
#  - generic-prod (production image)
#  - generic-dev (developer container image)
#  - generic-sysext-base-${name} (sysext image ${name} built-in into
#    production image, usually docker or containerd)
#  - generic-sysext-extra-${name} (extra sysext image ${name}, like
#    podman, python, zfs)
#  - generic-oem-${name} (image for OEM ${name})
#  - generic-unknown (something using generic profile, but otherwise
#    unknown, probably something is messed up)
#  - unknown (unknown type of image, neither generic, nor sdk,
#    probably something is messed up)
flatcar_target_ref() {
    local -n type_ref=${1}; shift

    local name
    case ${FLATCAR_TYPE} in
        sdk) type_ref='sdk';;
        generic)
            case ${ROOT} in
                "${SYSROOT}") type_ref='generic-board';;
                */prod-image-rootfs) type_ref='generic-prod';;
                */dev-image-rootfs) type_ref='generic-dev';;
                */*-base-sysext-rootfs)
                    name=${ROOT##*/}
                    name=${name%-base-sysext-rootfs}
                    type_ref='generic-sysext-base-{name}'
                    ;;
                */*-extra-sysext-rootfs)
                    name=${ROOT##*/}
                    name=${name%-extra-sysext-rootfs}
                    type_ref='generic-sysext-extra-{name}'
                    ;;
                */*-oem-rootfs)
                    name=${ROOT##*/}
                    name=${name%-oem-rootfs}
                    type_ref='generic-oem-{name}'
                    ;;
                *) type_ref='generic-unknown'
            esac
            ;;
        *) type_ref='unknown';;
    esac
}

# Prints the type of image we are merging the package for, see
# flatcar_target_ref for details.
flatcar_target() {
    local target_type
    flatcar_target_ref target_type
    echo "${target_type}"
}

# Load all additional bashrc files we have for this package.
cros_stack_bashrc() {
	local cfg cfgd

	cfgd="${CROS_ADDONS_TREE}/config/env"
	for cfg in ${PN} ${PN}-${PV} ${PN}-${PV}-${PR} ; do
		cfg="${cfgd}/${CATEGORY}/${cfg}"
		[[ -f ${cfg} ]] && . "${cfg}"
	done
}
cros_stack_bashrc

# The standard bashrc hooks do not stack.  So take care of that ourselves.
# Now people can declare:
#   cros_pre_pkg_preinst_foo() { ... }
# And we'll automatically execute that in the pre_pkg_preinst func.
#
# Note: profile.bashrc's should avoid hooking phases that differ across
# EAPI's (src_{prepare,configure,compile} for example).  These are fine
# in the per-package bashrc tree (since the specific EAPI is known).
cros_lookup_funcs() {
	declare -f | egrep "^$1 +\(\) +$" | awk '{print $1}'
}
cros_stack_hooks() {
	local phase=$1 func
	local header=true

	for func in $(cros_lookup_funcs "cros_${phase}_[-_[:alnum:]]+") ; do
		if ${header} ; then
			einfo "Running stacked hooks for ${phase}"
			header=false
		fi
		ebegin "   ${func#cros_${phase}_}"
		${func}
		eend $?
	done
}
cros_setup_hooks() {
	# Avoid executing multiple times in a single build.
	[[ ${cros_setup_hooks_run+set} == "set" ]] && return

	local phase
	for phase in {pre,post}_{src_{unpack,prepare,configure,compile,test,install},pkg_{{pre,post}{inst,rm},setup}} ; do
		eval "${phase}() { cros_stack_hooks ${phase} ; }"
	done
	export cros_setup_hooks_run="booya"
}
cros_setup_hooks

# Since we're storing the wrappers in a board sysroot, make sure that
# is actually in our PATH.
cros_pre_pkg_setup_sysroot_build_bin_dir() {
	PATH+=":${CROS_BUILD_BOARD_BIN}"
}

# Avoid modifications of the preexisting users - these are provided by
# our baselayout and usermod can't change anything there anyway (it
# complains that the user is not in /etc/passwd).
cros_pre_pkg_postinst_no_modifications_of_users() {
    if [[ "${CATEGORY}" != 'acct-user' ]]; then
        return 0
    fi
    export ACCT_USER_NO_MODIFY=x
}

# Source hooks for SLSA build provenance report generation
source "${BASH_SOURCE[0]}.slsa-provenance"

# Improve the chance that ccache is valid across versions by making all
# paths under $S relative to $S, avoiding encoding the package version
# contained in the path into __FILE__ expansions and debug info.
if [[ -z "${CCACHE_BASEDIR}" ]] && [[ -d "${S}" ]]; then
    export CCACHE_BASEDIR="${S}"
fi
