# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/antlr-c/antlr-c-3.3_pre20110403.ebuild,v 1.1 2011/06/10 07:02:40 qiaomuf Exp $

EAPI="4"
inherit eutils versionator autotools

MY_PN="libantlr3c"
MY_P="${MY_PN}-$(get_version_component_range 1-2)-SNAPSHOT"
DESCRIPTION="The ANTLR3 C Runtime"
HOMEPAGE="http://fisheye2.atlassian.com/browse/antlr/runtime/C/dist/"
SRC_URI="http://www.antlr.org/download/C/${MY_P}.tar.gz ->
	${MY_PN}-${PV}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="debug debugger doc static-libs"

DEPEND="doc? ( app-doc/doxygen )"
RDEPEND=""

S="${WORKDIR}/${MY_P}"

src_prepare() {
	epatch "${FILESDIR}/${PN}-3.1.4-doxygen.patch"
	epatch "${FILESDIR}/${PN}-3.3-cflags.patch"
	mkdir m4
	eautoreconf
}

src_configure() {
	local myconf

	if use amd64 || use ia64; then
		myconf="${myconf} --enable-64bit"
	else
		myconf="${myconf} --disable-64bit"
	fi

	econf \
		$(use_enable static-libs static) \
		$(use_enable debug debuginfo ) \
		$(use_enable debugger antlrdebug ) \
		${myconf}
}

src_compile() {
	emake

	if use doc; then
		einfo "Generating documentation API ..."
		doxygen -u doxyfile
		doxygen doxyfile || die "doxygen failed"
	fi
}

src_install() {
	emake DESTDIR="${D}" install

	# remove useless .la files
	find "${D}" -name '*.la' -delete

	dodoc AUTHORS ChangeLog NEWS README
	if use doc; then
		dohtml api/*
	fi
}
