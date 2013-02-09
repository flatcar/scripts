# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/vamp-plugin-sdk/vamp-plugin-sdk-2.0.ebuild,v 1.9 2012/03/18 18:11:47 armin76 Exp $

inherit toolchain-funcs eutils multilib

DESCRIPTION="Audio processing plugin system for plugins that extract descriptive information from audio data"
HOMEPAGE="http://www.vamp-plugins.org"
SRC_URI="mirror://sourceforge/vamp/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 hppa ppc ppc64 x86"
IUSE="doc"

RDEPEND="media-libs/libsndfile"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )"

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${P}-gcc44.patch
	# multilib for default search paths
	sed -i -e "s:/usr/lib/vamp:/usr/$(get_libdir)/vamp:" src/vamp-hostsdk/PluginHostAdapter.cpp || die "sed failed"
}

src_compile() {
	tc-export CXX AR RANLIB
	econf
	emake || die "emake failed"
	if use doc; then
		cd build
		doxygen || die "creating doxygen doc failed"
	fi
}

src_install() {
	emake DESTDIR="${D}" INSTALL_SDK_LIBS="/usr/$(get_libdir)" INSTALL_PKGCONFIG="/usr/$(get_libdir)/pkgconfig" INSTALL_PLUGINS="/usr/$(get_libdir)/vamp" install || die "emake install failed"
	dodoc README* CHANGELOG
	use doc && dohtml -r build/doc/html/*
}

pkg_postinst() {
	elog ""
	elog "You might also want to install some Vamp plugins."
	elog "See media-plugins/vamp-*"
	elog ""
}
