# Copyright 1999-2004 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/java-vm-2.eclass,v 1.29 2009/10/11 11:46:59 maekke Exp $

# -----------------------------------------------------------------------------
# @eclass-begin
# @eclass-shortdesc Java Virtual Machine eclass
# @eclass-maintainer java@gentoo.org
#
# This eclass provides functionality which assists with installing
# virtual machines, and ensures that they are recognized by java-config.
#
# -----------------------------------------------------------------------------

inherit eutils fdo-mime

DEPEND="=dev-java/java-config-2*"
hasq "${EAPI}" 0 1 && DEPEND="${DEPEND} >=sys-apps/portage-2.1"

RDEPEND="
	=dev-java/java-config-2*"

export WANT_JAVA_CONFIG=2

JAVA_VM_CONFIG_DIR="/usr/share/java-config-2/vm"
JAVA_VM_DIR="/usr/lib/jvm"
JAVA_VM_BUILD_ONLY="${JAVA_VM_BUILD_ONLY:-FALSE}"

EXPORT_FUNCTIONS pkg_setup pkg_postinst pkg_prerm pkg_postrm

java-vm-2_pkg_setup() {
	if [[ "${SLOT}" != "0" ]]; then
		VMHANDLE=${PN}-${SLOT}
	else
		VMHANDLE=${PN}
	fi
}

java-vm-2_pkg_postinst() {
	# Set the generation-2 system VM, if it isn't set
	if [[ -z "$(java-config-2 -f)" ]]; then
		java_set_default_vm_
	fi

	java-vm_check-nsplugin
	java_mozilla_clean_
	fdo-mime_desktop_database_update
}

java-vm_check-nsplugin() {
	local libdir
	if [[ ${VMHANDLE} =~ emul-linux-x86 ]]; then
		libdir=lib32
	else
		libdir=lib
	fi
	# Install a default nsplugin if we don't already have one
	if has nsplugin ${IUSE} && use nsplugin; then
		if [[ ! -f /usr/${libdir}/nsbrowser/plugins/javaplugin.so ]]; then
			einfo "No system nsplugin currently set."
			java-vm_set-nsplugin
		else
			einfo "System nsplugin is already set, not changing it."
		fi
		einfo "You can change nsplugin with eselect java-nsplugin."
	fi
}

java-vm_set-nsplugin() {
	local extra_args
	if use amd64; then
		if [[ ${VMHANDLE} =~ emul-linux-x86 ]]; then
			extra_args="32bit"
		else
			extra_args="64bit"
		fi
		einfo "Setting ${extra_args} nsplugin to ${VMHANDLE}"
	else
		einfo "Setting nsplugin to ${VMHANDLE}..."
	fi
	eselect java-nsplugin set ${extra_args} ${VMHANDLE}
}

java-vm-2_pkg_prerm() {
	if [[ "$(java-config -f 2>/dev/null)" == "${VMHANDLE}" ]]; then
		ewarn "It appears you are removing your system-vm!"
		ewarn "Please run java-config -L to list available VMs,"
		ewarn "then use java-config -S to set a new system-vm!"
	fi
}

java-vm-2_pkg_postrm() {
	fdo-mime_desktop_database_update
}

java_set_default_vm_() {
	java-config-2 --set-system-vm="${VMHANDLE}"

	einfo " ${P} set as the default system-vm."
}

get_system_arch() {
	local sarch
	sarch=$(echo ${ARCH} | sed -e s/[i]*.86/i386/ -e s/x86_64/amd64/ -e s/sun4u/sparc/ -e s/sparc64/sparc/ -e s/arm.*/arm/ -e s/sa110/arm/)
	if [ -z "${sarch}" ]; then
		sarch=$(uname -m | sed -e s/[i]*.86/i386/ -e s/x86_64/amd64/ -e s/sun4u/sparc/ -e s/sparc64/sparc/ -e s/arm.*/arm/ -e s/sa110/arm/)
	fi
	echo ${sarch}
}

# TODO rename to something more evident, like install_env_file
set_java_env() {
	debug-print-function ${FUNCNAME} $*
	local platform="$(get_system_arch)"
	local env_file="${D}${JAVA_VM_CONFIG_DIR}/${VMHANDLE}"
	local old_env_file="${D}/etc/env.d/java/20${P}"
	if [[ ${1} ]]; then
		local source_env_file="${1}"
	else
		local source_env_file="${FILESDIR}/${VMHANDLE}.env"
	fi

	if [[ ! -f ${source_env_file} ]]; then
		die "Unable to find the env file: ${source_env_file}"
	fi

	dodir ${JAVA_VM_CONFIG_DIR}
	sed \
		-e "s/@P@/${P}/g" \
		-e "s/@PN@/${PN}/g" \
		-e "s/@PV@/${PV}/g" \
		-e "s/@PF@/${PF}/g" \
		-e "s/@PLATFORM@/${platform}/g" \
		-e "/^LDPATH=.*lib\\/\\\"/s|\"\\(.*\\)\"|\"\\1${platform}/:\\1${platform}/server/\"|" \
		< ${source_env_file} \
		> ${env_file} || die "sed failed"

	(
		echo "VMHANDLE=\"${VMHANDLE}\""
		echo "BUILD_ONLY=\"${JAVA_VM_BUILD_ONLY}\""
	) >> ${env_file}

	[[ -n ${JAVA_PROVIDE} ]] && echo "PROVIDES=\"${JAVA_PROVIDE}\"" >> ${env_file}

	local java_home=$(source ${env_file}; echo ${JAVA_HOME})
	[[ -z ${java_home} ]] && die "No JAVA_HOME defined in ${env_file}"

	# Make the symlink
	dosym ${java_home} ${JAVA_VM_DIR}/${VMHANDLE} \
		|| die "Failed to make VM symlink at ${JAVA_VM_DIR}/${VMHANDLE}"
}

# -----------------------------------------------------------------------------
# @ebuild-function java-vm_revdep-mask
#
# Installs a revdep-rebuild control file which SEARCH_DIR_MASK set to the path
# where the VM is installed. Prevents pointless rebuilds - see bug #177925.
# Also gives a notice to the user.
#
# @example
#	java-vm_revdep-mask
#	java-vm_revdep-mask /path/to/jdk/
#
# @param $1 - Path of the VM (defaults to /opt/${P} if not set)
# ------------------------------------------------------------------------------
java-vm_revdep-mask() {
	local VMROOT="${1-/opt/${P}}"

	dodir /etc/revdep-rebuild/
	echo "SEARCH_DIRS_MASK=\"${VMROOT}\""> "${D}/etc/revdep-rebuild/61-${VMHANDLE}"

	elog "A revdep-rebuild control file was installed to prevent reinstalls due to"
	elog "missing dependencies (see bug #177925 for more info). Note that some parts"
	elog "of the JVM may require dependencies that are pulled only through respective"
	elog "USE flags (typically X, alsa, odbc) and some Java code may fail without them."
}

java_get_plugin_dir_() {
	echo /usr/$(get_libdir)/nsbrowser/plugins
}

install_mozilla_plugin() {
	local plugin="${1}"
	local variant="${2}"

	if [[ ! -f "${D}/${plugin}" ]]; then
		die "Cannot find mozilla plugin at ${D}/${plugin}"
	fi

	if [[ -n "${variant}" ]]; then
		variant="-${variant}"
	fi

	local plugin_dir="/usr/share/java-config-2/nsplugin"
	dodir "${plugin_dir}"
	dosym "${plugin}" "${plugin_dir}/${VMHANDLE}${variant}-javaplugin.so"
}

java_mozilla_clean_() {
	# Because previously some ebuilds installed symlinks outside of pkg_install
	# and are left behind, which forces you to manualy remove them to select the
	# jdk/jre you want to use for java
	local plugin_dir=$(java_get_plugin_dir_)
	for file in ${plugin_dir}/javaplugin_*; do
		rm -f ${file}
	done
	for file in ${plugin_dir}/libjavaplugin*; do
		rm -f ${file}
	done
}

# ------------------------------------------------------------------------------
# @eclass-end
# ------------------------------------------------------------------------------
