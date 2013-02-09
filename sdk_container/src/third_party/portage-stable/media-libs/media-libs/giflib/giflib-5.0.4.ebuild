# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/giflib/giflib-5.0.4.ebuild,v 1.1 2013/01/23 18:03:04 vapier Exp $

EAPI=4

inherit eutils libtool

DESCRIPTION="Library to handle, display and manipulate GIF images"
HOMEPAGE="http://sourceforge.net/projects/giflib/"
SRC_URI="mirror://sourceforge/giflib/${P}.tar.bz2"

LICENSE="MIT"
SLOT="0"
# Needs testing first.
#KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd"
IUSE="static-libs"

src_prepare() {
	elibtoolize
	epunt_cxx
}

src_configure() {
	# No need for xmlto as they ship generated files.
	ac_cv_prog_have_xmlto=no \
	econf $(use_enable static-libs static)
}

src_install() {
	default
	find "${ED}" -name '*.la' -delete
	doman doc/*.1
	dodoc doc/*.txt
	dohtml -r doc
}
