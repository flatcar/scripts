# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/x264/x264-0.0.20110426.ebuild,v 1.5 2011/08/27 17:47:04 armin76 Exp $

EAPI=2
inherit eutils multilib toolchain-funcs versionator

MY_P=x264-snapshot-$(get_version_component_range 3)-2245

DESCRIPTION="A free library for encoding X264/AVC streams"
HOMEPAGE="http://www.videolan.org/developers/x264.html"
SRC_URI="http://ftp.videolan.org/pub/videolan/x264/snapshots/${MY_P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 ~mips ppc ppc64 sparc x86 ~x86-fbsd"
IUSE="debug +threads pic"

RDEPEND=""
DEPEND="amd64? ( >=dev-lang/yasm-0.6.2 )
	x86? ( >=dev-lang/yasm-0.6.2 )
	x86-fbsd? ( >=dev-lang/yasm-0.6.2 )"

S=${WORKDIR}/${MY_P}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-nostrip.patch \
		"${FILESDIR}"/${PN}-onlylib-20110425.patch
}

src_configure() {
	tc-export CC

	local myconf=""
	use debug && myconf="${myconf} --enable-debug"

	if use x86 && use pic; then
		myconf="${myconf} --disable-asm"
	fi

	./configure \
		--prefix=/usr \
		--libdir=/usr/$(get_libdir) \
		--disable-avs \
		--disable-lavf \
		--disable-swscale \
		--disable-gpac \
		$(use threads || echo "--disable-thread") \
		--enable-pic \
		--enable-shared \
		--extra-asflags="${ASFLAGS}" \
		--extra-cflags="${CFLAGS}" \
		--extra-ldflags="${LDFLAGS}" \
		--host="${CHOST}" \
		${myconf} \
		|| die
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS doc/*.txt
}
