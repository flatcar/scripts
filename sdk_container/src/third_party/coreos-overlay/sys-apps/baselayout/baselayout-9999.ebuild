# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=8
EGIT_REPO_URI="https://github.com/flatcar/baselayout.git"

if [[ "${PV}" == 9999 ]]; then
	inherit git-r3
	KEYWORDS="~amd64 ~arm64"
else
	EGIT_COMMIT="1ad3846c507888ffbb4209f6eaf294a60cda5fe6" # flatcar-master
	SRC_URI="https://github.com/flatcar/baselayout/archive/${EGIT_COMMIT}.tar.gz -> flatcar-${PN}-${EGIT_COMMIT}.tar.gz"
	S="${WORKDIR}/${PN}-${EGIT_COMMIT}"
	KEYWORDS="amd64 arm64"
fi

inherit multilib

DESCRIPTION="Filesystem baselayout for Flatcar"
HOMEPAGE="https://www.flatcar.org/"

LICENSE="GPL-2"
SLOT="0"
IUSE="cros_host bash"

# Make sure coreos-init is not installed in the SDK
RDEPEND="
	bash? ( >=sys-apps/gentoo-functions-0.10 )
	cros_host? ( !coreos-base/coreos-init )
"

src_prepare() {
	default

	if use cros_host; then
		# Undesirable in the SDK
		rm -f lib/tmpfiles.d/baselayout-etc-profile-flatcar-profile.conf || die
		# Provided by vim in the SDK
		rm -f lib/tmpfiles.d/baselayout-etc-vim.conf || die
		# Don't initialize /etc/passwd, group, and friends on boot.
		rm -rf bin || die
		rm -rf lib/systemd || die
		# Inject custom SSL configuration required for signing
		# payloads from the SDK container using OpenSSL.
		mkdir -p etc/ssl || die
		cp -a share/baselayout/pkcs11.cnf etc/ssl || die
	else
		# Don't install /etc/issue since it is handled by coreos-init right now
		rm -f lib/tmpfiles.d/baselayout-etc-issue.conf || die
	fi

	# sssd not yet building on arm64
	if use arm64; then
		sed -i -e 's/ sss//' share/baselayout/nsswitch.conf || die
		sed -i -e '/pam_sss.so/d' lib/pam.d/* || die
	fi

	# handle multilib paths.  do it here because we want this behavior
	# regardless of the C library that you're using.  we do explicitly
	# list paths which the native ldconfig searches, but this isn't
	# problematic as it doesn't change the resulting ld.so.cache or
	# take longer to generate.  similarly, listing both the native
	# path and the symlinked path doesn't change the resulting cache.
	local libdir ldpaths
	for libdir in $(get_all_libdirs) ; do
		ldpaths+=":${EPREFIX}/usr/${libdir}"
		ldpaths+=":${EPREFIX}/usr/local/${libdir}"
	done
	echo "LDPATH='${ldpaths#:}'" >> etc/env.d/00basic || die

	# Add oem/lib64 to search path towards end of the system's list.
	# This simplifies the configuration of OEMs with dynamic libs.
	ldpaths=
	for libdir in $(get_all_libdirs) ; do
		ldpaths+=":/oem/${libdir}"
	done
	echo "LDPATH='${ldpaths#:}'" >> etc/env.d/80oem || die
}

src_compile() {
	local libdirs

	libdirs=$(get_all_libdirs)
	emake LIBDIRS="${libdirs}" all
}

src_install() {
	emake DESTDIR="${ED}" install
	# GID 190 is taken from acct-group/systemd-journal eclass
	SYSTEMD_JOURNAL_GID=${ACCT_GROUP_SYSTEMD_JOURNAL_ID:-190} ROOT_UID=0 ROOT_GID=0 CORE_UID=500 CORE_GID=500 DESTDIR=${D} ./dumb-tmpfiles-proc.sh --exclude d "${ED}/usr/lib/tmpfiles.d" || die

	insinto /usr/share/baselayout
	doins Makefile
	exeinto /usr/share/baselayout
	doexe dumb-tmpfiles-proc.sh
}

pkg_preinst() {
	local libdirs
	libdirs=$(get_all_libdirs)
	emake -C "${ED}/usr/share/${PN}" DESTDIR="${EROOT}" LIBDIRS="${libdirs}" layout
	SYSTEMD_JOURNAL_GID=${ACCT_GROUP_SYSTEMD_JOURNAL_ID:-190} ROOT_UID=0 ROOT_GID=0 CORE_UID=500 CORE_GID=500 DESTDIR=${D} "${ED}/usr/share/${PN}/dumb-tmpfiles-proc.sh" "${ED}/usr/lib/tmpfiles.d" || die
	rm -f "${ED}/usr/share/${PN}/Makefile" "${ED}/usr/share/${PN}/dumb-tmpfiles-proc.sh" || die
}

pkg_postinst() {
	# compat symlink for packages that haven't migrated to gentoo-functions
    if use bash; then
        local func=../../lib/gentoo/functions.sh
        if [[ "$(readlink "${ROOT}/etc/init.d/functions.sh")" != "${func}" ]]; then
            elog "Creating /etc/init.d/functions.sh symlink..."
            mkdir -p "${ROOT}/etc/init.d"
            ln -sf "${func}" "${ROOT}/etc/init.d/functions.sh"
        fi
    fi
	# install compat symlinks in production images, not in SDK
	# os-release symlink is set up in scripts
	if ! use cros_host; then
		local compat libdir
		for compat in systemd kernel modprobe.d pam pam.d sysctl.d udev ; do
			for libdir in $(get_all_libdirs) ; do
				if [[ "${libdir}" == 'lib' ]]; then continue; fi
				ln -sfT "../lib/${compat}" "${ROOT}/usr/${libdir}/${compat}"
			done
		done
		# Create a compatibility symlink for OEM.
		ln -sfT ../../oem "${ROOT}/usr/share/oem"
		# Also create the directory to avoid having dangling
		# symlinks.
		mkdir -p "${ROOT}/oem"
	fi

	# The default passwd/group files must exist for some ebuilds
	touch "${EROOT}/etc/"{group,gshadow,passwd,shadow}
	chmod 640 "${EROOT}/etc/"{gshadow,shadow}
}
