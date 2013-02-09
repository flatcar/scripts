# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/celt/celt-0.6.1.ebuild,v 1.5 2012/12/07 18:57:22 ulm Exp $

EAPI="2"

inherit autotools

DESCRIPTION="CELT is a very low delay audio codec designed for high-quality communications."
HOMEPAGE="http://www.celt-codec.org/"
SRC_URI="http://downloads.us.xiph.org/releases/${PN}/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~ppc ~x86"
IUSE="ogg"

DEPEND="ogg? ( media-libs/libogg )"
RDEPEND="${DEPEND}"

src_unpack() {
	unpack ${A}
	cd "${S}"
	eautoreconf
}

src_configure() {
	econf $(use_with ogg ogg /usr)
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed."
	dodoc ChangeLog README TODO || die "dodoc failed."

	find "${D}" -name '*.la' -delete
}
