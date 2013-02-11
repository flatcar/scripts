# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libSM/libSM-1.2.1.ebuild,v 1.9 2012/08/26 17:26:40 armin76 Exp $

EAPI=4

XORG_DOC=doc
inherit xorg-2

DESCRIPTION="X.Org SM library"

KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~ppc-aix ~amd64-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~hppa-hpux ~ia64-hpux ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris ~x86-winnt"
IUSE="doc ipv6 +uuid"

RDEPEND=">=x11-libs/libICE-1.0.5
	x11-libs/xtrans
	x11-proto/xproto
	!elibc_FreeBSD? ( !elibc_SunOS? (
		uuid? ( >=sys-apps/util-linux-2.16 )
	) )"
DEPEND="${RDEPEND}"

pkg_setup() {
	local withuuid=$(use_with uuid libuuid)
	xorg-2_pkg_setup

	# do not use uuid even if available in libc (like on FreeBSD)
	use uuid || export ac_cv_func_uuid_create=no

	if use uuid ; then
		case ${CHOST} in
			*-solaris*|*-darwin*)
				if [[ ! -d ${EROOT}usr/include/uuid ]] &&
					[[ -d ${ROOT}usr/include/uuid ]]
				then
					# Solaris and Darwin have uuid provided by the host
					# system.  Since util-linux's version is based on this
					# version, and on Darwin actually breaks host headers when
					# installed, we can "pretend" for libSM we have libuuid
					# installed, while in fact we don't
					withuuid="--without-libuuid"
					export HAVE_LIBUUID=yes
					export LIBUUID_CFLAGS="-I${ROOT}usr/include/uuid"
					# Darwin has uuid in libSystem
					[[ ${CHOST} == *-solaris* ]] &&	export LIBUUID_LIBS="-luuid"
				fi
				;;
		esac
	fi
	XORG_CONFIGURE_OPTIONS=(
		$(use_enable ipv6)
		$(use_enable doc docs)
		$(use_with doc xmlto)
		${withuuid}
		--without-fop
	)
}
