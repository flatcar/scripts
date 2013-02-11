# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/pslib/pslib-0.4.5.ebuild,v 1.1 2012/09/10 14:08:22 scarabeus Exp $

EAPI=4

inherit eutils

DESCRIPTION="pslib is a C-library to create PostScript files on the fly."
HOMEPAGE="http://pslib.sourceforge.net/"
SRC_URI="mirror://sourceforge/pslib/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~ppc64 ~sparc ~x86"
IUSE="debug jpeg png static-libs tiff"

RDEPEND="
	png? ( >=media-libs/libpng-1.2.43-r2:0 )
	jpeg? ( virtual/jpeg )
	tiff? ( media-libs/tiff )"
#gif? requires libungif, not in portage
DEPEND="${RDEPEND}
	dev-lang/perl
	>=dev-libs/glib-2
	dev-util/intltool
	dev-perl/XML-Parser"

src_configure() {
	econf \
		--enable-bmp \
		$(use_enable static-libs static) \
		$(use_with png) \
		$(use_with jpeg) \
		$(use_with tiff) \
		$(use_with debug)
}

src_install() {
	default

	prune_libtool_files --all
}
