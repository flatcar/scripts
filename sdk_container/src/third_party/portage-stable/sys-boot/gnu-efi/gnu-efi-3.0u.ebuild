# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-boot/gnu-efi/gnu-efi-3.0u.ebuild,v 1.1 2013/07/03 14:14:03 chithanh Exp $

EAPI=5

inherit eutils multilib

MY_P="${PN}_${PV}"
DEB_VER="3.0i-4"
DESCRIPTION="Library for build EFI Applications"
HOMEPAGE="http://developer.intel.com/technology/efi"
SRC_URI="mirror://sourceforge/gnu-efi/${MY_P}.orig.tar.gz
	mirror://debian/pool/main/g/gnu-efi/${PN}_${DEB_VER}.diff.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ia64 ~x86"
IUSE=""

DEPEND="sys-apps/pciutils"
RDEPEND=""

S=${WORKDIR}/${P%?}

# These objects get run early boot (i.e. not inside of Linux),
# so doing these QA checks on them doesn't make sense.
QA_EXECSTACK="usr/*/lib*efi.a:* usr/*/crt*.o"

src_prepare() {
	EPATCH_OPTS="-p1" epatch "${WORKDIR}"/*.diff
}

_emake() {
	emake prefix=${CHOST}- ARCH=${iarch} PREFIX=/usr "$@"
}

src_compile() {
	case ${ARCH} in
		ia64)  iarch=ia64 ;;
		x86)   iarch=ia32 ;;
		amd64) iarch=x86_64 ;;
		*)     die "unknown architecture: $ARCH" ;;
	esac
	# The lib subdir uses unsafe archive targets, and
	# the apps subdir needs gnuefi subdir
	_emake -j1
}

src_install() {
	_emake install PREFIX=/usr INSTALLROOT="${D}"
	dodoc README* ChangeLog
}
