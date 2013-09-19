# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/hwids/hwids-20130915.1.ebuild,v 1.2 2013/09/16 07:33:36 ssuominen Exp $

EAPI=5
inherit udev eutils

DESCRIPTION="Hardware (PCI, USB, OUI, IAB) IDs databases"
HOMEPAGE="https://github.com/gentoo/hwids"
SRC_URI="https://github.com/gentoo/hwids/archive/${P}.tar.gz"

LICENSE="|| ( GPL-2 BSD ) public-domain"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~x64-freebsd ~amd64-linux ~arm-linux ~x86-linux"
IUSE="+udev"

DEPEND="udev? (
	dev-lang/perl
	>=virtual/udev-206
)"
RDEPEND="!<sys-apps/pciutils-3.1.9-r2
	!<sys-apps/usbutils-005-r1"

S=${WORKDIR}/hwids-${P}

src_prepare() {
	sed -i -e '/udevadm hwdb/d' Makefile || die
}

src_compile() {
	emake UDEV=$(usex udev)
}

src_install() {
	emake UDEV=$(usex udev) install \
		DOCDIR="${EPREFIX}/usr/share/doc/${PF}" \
		MISCDIR="${EPREFIX}/usr/share/misc" \
		HWDBDIR="${EPREFIX}$(get_udevdir)/hwdb.d" \
		DESTDIR="${D}"
}

pkg_postinst() {
	if use udev; then
		udevadm hwdb --update --root="${ROOT%/}"
		# http://cgit.freedesktop.org/systemd/systemd/commit/?id=1fab57c209035f7e66198343074e9cee06718bda
		if [[ ${ROOT} != "" ]] && [[ ${ROOT} != "/" ]]; then
			return 0
		fi
		udevadm control --reload
	fi
}
