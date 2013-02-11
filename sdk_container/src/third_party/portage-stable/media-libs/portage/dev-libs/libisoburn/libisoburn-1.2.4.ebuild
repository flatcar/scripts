# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libisoburn/libisoburn-1.2.4.ebuild,v 1.7 2012/09/30 18:59:44 armin76 Exp $

EAPI=4

DESCRIPTION="Enables creation and expansion of ISO-9660 filesystems on all CD/DVD media supported by libburn"
HOMEPAGE="http://libburnia-project.org/"
SRC_URI="http://files.libburnia-project.org/releases/${P}.tar.gz"

LICENSE="GPL-2 GPL-3"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ppc ppc64 x86"
IUSE="acl cdio debug external-filters external-filters-setuid readline static-libs xattr zlib"

RDEPEND=">=dev-libs/libburn-1.2.4
	>=dev-libs/libisofs-1.2.4
	readline? ( sys-libs/readline )
	acl? ( virtual/acl )
	xattr? ( sys-apps/attr )
	zlib? ( sys-libs/zlib )
	cdio? ( >=dev-libs/libcdio-0.83 )"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

src_configure() {
	econf \
	$(use_enable static-libs static) \
	$(use_enable readline libreadline) \
	$(use_enable acl libacl) \
	$(use_enable xattr) \
	$(use_enable zlib) \
	--disable-libjte \
	$(use_enable cdio libcdio) \
	$(use_enable external-filters) \
	$(use_enable external-filters-setuid) \
	 --disable-ldconfig-at-install \
	--enable-pkg-check-modules \
	$(use_enable debug)
}

src_install() {
	default

	dodoc CONTRIBUTORS doc/{comments,*.wiki,startup_file.txt}

	cd "${S}"/xorriso
	docinto xorriso
	dodoc changelog.txt README_gnu_xorriso

	find "${D}" -name '*.la' -exec rm -rf '{}' '+' || die "la removal failed"
}
