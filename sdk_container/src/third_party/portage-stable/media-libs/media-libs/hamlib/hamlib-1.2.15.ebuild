# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/hamlib/hamlib-1.2.15.ebuild,v 1.6 2012/11/11 17:34:40 tomjbe Exp $

EAPI="3"
PYTHON_DEPEND="python? 2"

inherit autotools-utils eutils multilib python

DESCRIPTION="Ham radio backend rig control libraries"
HOMEPAGE="http://sourceforge.net/apps/mediawiki/hamlib"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="LGPL-2 GPL-2"
SLOT="0"
KEYWORDS="amd64 x86 ~x86-fbsd"
IUSE="doc python tcl"

RESTRICT="test"

RDEPEND="
	=virtual/libusb-0*
	dev-libs/libxml2
	tcl? ( dev-lang/tcl )"

DEPEND=" ${RDEPEND}
	virtual/pkgconfig
	dev-lang/swig
	>=sys-devel/libtool-2.2
	doc? ( app-doc/doxygen )"

DOCS=(AUTHORS NEWS PLAN README README.betatester README.developer TODO)

pkg_setup() {
	if use python; then
		python_set_active_version 2
		python_pkg_setup
	fi
}

src_prepare() {
	# fix hardcoded libdir paths
	sed -i -e "s#fix}/lib#fix}/$(get_libdir)/hamlib#" \
		-e "s#fix}/include#fix}/include/hamlib#" \
		hamlib.pc.in || die "sed failed"

	# make building of documentation compatible with autotools-utils
	sed -i -e "s/doc:/html:/g" doc/Makefile.am || die "sed failed"

	# fix tcl lib path
	epatch "${FILESDIR}"/${PN}-1.2.11-bindings.diff

	eautoreconf
}

src_configure() {
	local myeconfargs=(
		--libdir=/usr/$(get_libdir)/hamlib
		--disable-static
		--with-rpc-backends
		--without-perl-binding
		$(use_with python python-binding)
		$(use_enable tcl tcl-binding)
		--disable-silent-rules
	)
	autotools-utils_src_configure
}

src_compile() {
	autotools-utils_src_compile
	use doc && autotools-utils_src_compile html
}

src_install() {
	use doc && HTML_DOCS=("${AUTOTOOLS_BUILD_DIR}/doc/html/")
	autotools-utils_src_install

	insinto /usr/$(get_libdir)/pkgconfig
	doins "${AUTOTOOLS_BUILD_DIR}"/hamlib.pc || die "doins failed"

	echo "LDPATH=/usr/$(get_libdir)/hamlib" > "${T}"/73hamlib
	doenvd "${T}"/73hamlib || die "doenvd failed"
}

pkg_postinst()  {
	use python && python_mod_optimize Hamlib.py
}

pkg_postrm()  {
	use python && python_mod_cleanup Hamlib.py
}
