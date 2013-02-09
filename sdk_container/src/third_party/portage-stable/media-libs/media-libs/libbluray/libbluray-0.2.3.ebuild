# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libbluray/libbluray-0.2.3.ebuild,v 1.5 2013/01/16 18:51:54 ago Exp $

EAPI=4

inherit autotools java-pkg-opt-2 flag-o-matic eutils

DESCRIPTION="Blu-ray playback libraries"
HOMEPAGE="http://www.videolan.org/developers/libbluray.html"
SRC_URI="ftp://ftp.videolan.org/pub/videolan/libbluray/${PV}/${P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 ppc ppc64 x86 ~amd64-fbsd ~x86-fbsd"
IUSE="aacs java static-libs utils +xml"

COMMON_DEPEND="
	xml? ( dev-libs/libxml2 )
"
RDEPEND="
	${COMMON_DEPEND}
	aacs? ( media-libs/libaacs )
	java? ( >=virtual/jre-1.6 )
"
DEPEND="
	${COMMON_DEPEND}
	java? (
		>=virtual/jdk-1.6
		dev-java/ant-core
	)
	virtual/pkgconfig
"
REQUIRED_USE="utils? ( static-libs )"

DOCS=( ChangeLog README.txt )

src_prepare() {
	use java && export JDK_HOME="$(java-config -g JAVA_HOME)"
	eautoreconf

	java-pkg-opt-2_src_prepare
}

src_configure() {
	local myconf=""
	if use java; then
		export JAVACFLAGS="$(java-pkg_javac-args)"
		append-cflags "$(java-pkg_get-jni-cflags)"
		myconf="--with-jdk=${JDK_HOME}"
	fi

	use xml && myconf+=" --enable-libxml2"

	econf \
		--disable-debug \
		--disable-optimizations \
		$(use_enable java bdjava) \
		$(use_enable static-libs static) \
		$(use_enable utils examples) \
		${myconf}
}

src_install() {
	default

	if use utils; then
		cd src/examples/
		dobin clpi_dump index_dump mobj_dump mpls_dump sound_dump
		cd .libs/
		dobin bd_info bdsplice hdmv_test libbluray_test list_titles
		if use java; then
			dobin bdj_test
		fi
	fi

	if use java; then
		java-pkg_dojar "${S}/src/.libs/${PN}.jar"
		doenvd "${FILESDIR}"/90${PN}
	fi

	prune_libtool_files
}
