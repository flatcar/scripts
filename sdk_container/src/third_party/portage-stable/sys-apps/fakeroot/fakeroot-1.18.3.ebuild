# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/fakeroot/fakeroot-1.18.3.ebuild,v 1.1 2012/05/12 17:01:29 radhermit Exp $

EAPI=4

DESCRIPTION="Run commands in an environment faking root privileges"
HOMEPAGE="http://packages.qa.debian.org/f/fakeroot.html"
SRC_URI="mirror://debian/pool/main/f/fakeroot/${PF/-/_}.orig.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 ~arm ~hppa ~ppc ~sparc ~x86 ~amd64-linux ~x86-linux"
IUSE="static-libs test"

DEPEND="test? ( app-arch/sharutils )"

DOCS=( AUTHORS BUGS DEBUG README doc/README.saving )

src_configure() {
	econf \
		$(use_enable static-libs static)
}

src_install() {
	default
	use static-libs || find "${ED}" -name '*.la' -exec rm -f '{}' +
}
