# Dumping ground for build-time helpers to utilize since SYSROOT/tmp/
# can be nuked at any time.
CROS_BUILD_BOARD_TREE="${SYSROOT}/build"
CROS_ADDONS_TREE="/mnt/host/source/src/third_party/coreos-overlay/coreos"

# Prints the type of image we are merging the package for, prints one
# of the following:
#
#  - sdk (the SDK)
#  - generic-board (board sysroot)
#  - generic-prod (production image)
#  - generic-dev (developer container image)
#  - generic-sysext-base-${name} (sysext image ${name} built-in into
#    production image, usually docker or containerd)
#  - generic-sysext-extra-${name} (extra sysext image ${name}, like
#    podman, python, zfs)
#  - generic-sysext-oem-${name} (OEM sysext image ${name}, like
#    azure, qemu_uefi)
#  - generic-unknown (something using generic profile, but otherwise
#    unknown, may happen when config override is sourced between phase
#    funcs and flatcar_target is called at the toplevel scope instead
#    of a hook)
#  - unknown (unknown type of image, neither generic, nor sdk,
#    probably something is messed up)
#
# When using it with a string comparison, it is better to always use
# equality instead of unequality. So:
#
# if [[ $(flatcar_target) = 'generic-'* ]]; then …; fi
#
# instead of
#
# if [[ $(flatcar_target) != 'sdk' ]]; then …; fi
#
# The latter will be true if flatcar_target prints 'unknown'.
flatcar_target() {
    local target_type
    local revert_shopt=$(shopt -p extglob)
    shopt -s extglob
    source "${BASH_SOURCE[0]}.flatcar-target" target_type
    echo "${target_type}"
    ${revert_shopt}
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

# Remove any debug build-id symlinks that are broken because of INSTALL_MASK,
# and also remove their associated debug files to avoid wasting space.
cros_post_pkg_preinst_rm_masked_debug_files() {
	local link debug dir=${ED}/usr/lib/debug
	[[ -d ${dir}/.build-id ]] || return 0
	while read -d $'\n' -r link; do
		debug=$(realpath "${link}.debug") || die
		rm -f -- "${link}" "${link}.debug" "${debug}" || die
	done < <(find "${dir}"/.build-id -xtype l ! -name "*.debug")
	# -delete implies -depth so entire empty trees are deleted.
	find "${dir}" -type d -empty -delete || die
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

# Move pam files from /etc to /usr. It is a no-op for SDK builds.
#
# Invoke this in post_src_install hook.
vendorize_pam_files() {
    if [[ ${FLATCAR_TYPE} = 'sdk' ]]; then
        # We don't care about PAM inside SDK.
        return 0
    fi

    mkdir -p "${ED}/usr/lib/pam/security"

    tar --create --remove-files --directory "${ED}/etc/security" . | \
        tar --extract --directory "${ED}/usr/lib/pam/security"
    tar --create --remove-files --directory "${ED}/etc/pam.d" . | \
        tar --extract --directory "${ED}/usr/lib/pam"
}

# Source hooks for SLSA build provenance report generation
source "${BASH_SOURCE[0]}.slsa-provenance"

# Improve the chance that ccache is valid across versions by making all
# paths under $S relative to $S, avoiding encoding the package version
# contained in the path into __FILE__ expansions and debug info.
if [[ -z "${CCACHE_BASEDIR}" ]] && [[ -d "${S}" ]]; then
    export CCACHE_BASEDIR="${S}"
fi
