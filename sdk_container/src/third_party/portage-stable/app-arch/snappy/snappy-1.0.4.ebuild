# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-arch/snappy/snappy-1.0.4.ebuild,v 1.1 2011/11/21 09:53:37 nirbheek Exp $

EAPI="4"

DESCRIPTION="A high-speed compression/decompression library by Google"
HOMEPAGE="https://code.google.com/p/snappy/"
SRC_URI="http://${PN}.googlecode.com/files/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 arm x86"
IUSE="static-libs"

RDEPEND=""
DEPEND="${RDEPEND}"

DOCS="AUTHORS ChangeLog README NEWS format_description.txt"

src_prepare() {
	default
	# Avoid automagic lzop and gzip by not checking for it
	#sed -i -e '/^CHECK_EXT_COMPRESSION_LIB/d' "${S}/configure.ac" || die
	# Avoid eautoreconf due to the above sed by just removing the expanded lines
	sed -i -e '15126,15385d' "${S}/configure" || die
}

src_configure() {
	econf \
		--without-gflags \
		--disable-gtest \
		$(use_enable static-libs static)
}

src_install() {
	default

	# Remove docs installed by snappy itself
	rm -rf "${ED}/usr/share/doc/snappy" || die

	# Remove la files if we're not installing static libraries
	if ! use static-libs; then
		find "${ED}" -iname '*.la' -exec rm -f {} + || die
	fi
}
