# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/eeze/eeze-1.7.4.ebuild,v 1.3 2013/01/04 18:58:44 tommy Exp $

inherit enlightenment

DESCRIPTION="library to simplify the use of devices"
HOMEPAGE="http://trac.enlightenment.org/e/wiki/Eeze"
SRC_URI="http://download.enlightenment.org/releases/${P}.tar.bz2"

LICENSE="BSD-2"
KEYWORDS="~amd64 ~arm ~x86"
IUSE="static-libs utilities"

DEPEND=">=dev-libs/ecore-1.7.4
	>=dev-libs/eina-1.7.4
	>=dev-libs/eet-1.7.4
	virtual/udev"
RDEPEND=${DEPEND}

src_configure() {
	MY_ECONF="
	$(use_enable doc)
	$(use_enable utilities eeze-disk-ls)
	$(use_enable utilities eeze-mount)
	$(use_enable utilities eeze-umount)
	$(use_enable utilities eeze-udev-test)
	"

	enlightenment_src_configure
}
