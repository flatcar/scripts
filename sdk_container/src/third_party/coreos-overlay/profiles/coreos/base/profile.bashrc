# Dumping ground for build-time helpers to utilize since SYSROOT/tmp/
# can be nuked at any time.
CROS_BUILD_BOARD_TREE="${SYSROOT}/build"
CROS_BUILD_BOARD_BIN="${CROS_BUILD_BOARD_TREE}/bin"

CROS_ADDONS_TREE="/mnt/host/source/src/third_party/coreos-overlay/coreos"

# Are we merging for the board sysroot, or for the cros sdk, or for
# the target hardware?  Returns a string:
#  - cros_host (the sdk)
#  - board_sysroot
#  - target_image
# We can't rely on "use cros_host" as USE gets filtred based on IUSE,
# and not all packages have IUSE=cros_host.
cros_target() {
	if [[ ${CROS_SDK_HOST} == "cros-sdk-host" ]] ; then
		echo "cros_host"
	elif [[ ${ROOT%/} == ${SYSROOT%/} ]] ; then
		echo "board_sysroot"
	else
		echo "target_image"
	fi
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

# sys-apps/policycoreutils creates /var/lib/selinux directory in
# src_install and then needs it to be available when running
# pkg_postinst, because it does a policy module rebuild there. We
# initially have put /var/lib/selinux into INSTALL_MASK and told
# coreos-base/misc-files to install the directory at
# /usr/lib/selinux/policy together with a symlink at /var/lib/selinux
# pointing to the directory. But this is done too late - at
# sys-apps/policycoreutils' pkg_postinst time, /var/lib/selinux does
# not exist, because coreos-base/misc-files was not yet emerged. So we
# need to fall back to this hack, where we set up /var/lib/selinux and
# /usr/lib/selinux/policy the way we want.
cros_post_src_install_set_up_var_lib_selinux() {
    if [[ ${CATEGORY} != 'sys-apps' ]] || [[ ${PN} != 'policycoreutils' ]]; then
        return 0;
    fi
    dodir /usr/lib/selinux
    mv "${ED}/var/lib/selinux" "${ED}/usr/lib/selinux/policy"
    dosym ../../usr/lib/selinux/policy /var/lib/selinux
}

# Source hooks for SLSA build provenance report generation
source "${BASH_SOURCE[0]}.slsa-provenance"

# Improve the chance that ccache is valid across versions by making all
# paths under $S relative to $S, avoiding encoding the package version
# contained in the path into __FILE__ expansions and debug info.
if [[ -z "${CCACHE_BASEDIR}" ]] && [[ -d "${S}" ]]; then
    export CCACHE_BASEDIR="${S}"
fi
