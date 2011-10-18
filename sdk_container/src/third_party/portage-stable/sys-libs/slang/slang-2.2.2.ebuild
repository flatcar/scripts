# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/slang/slang-2.2.2.ebuild,v 1.9 2010/12/27 12:51:44 ssuominen Exp $

EAPI=2
inherit eutils

DESCRIPTION="A portable programmer's library designed to allow a developer to create robust portable software"
HOMEPAGE="http://www.jedsoft.org/slang/"
SRC_URI="mirror://slang/v${PV%.*}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~sparc-fbsd ~x86-fbsd"
IUSE="cjk pcre png readline zlib"

RDEPEND="sys-libs/ncurses
	pcre? ( dev-libs/libpcre )
	png? ( media-libs/libpng )
	cjk? ( dev-libs/oniguruma )
	readline? ( sys-libs/readline )
	zlib? ( sys-libs/zlib )"
DEPEND="${RDEPEND}"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-2.1.2-slsh-libs.patch \
		"${FILESDIR}"/${PN}-2.1.3-uclibc.patch

	sed -i \
		-e '/^TERMCAP=/s:=.*:=:' \
		configure || die
}

src_configure() {
	local myconf

	if use readline; then
		myconf+=" --with-readline=gnu"
	else
		myconf+=" --with-readline=slang"
	fi

	econf \
		$(use_with cjk onig) \
		$(use_with pcre) \
		$(use_with png) \
		$(use_with zlib z) \
		${myconf}
}

src_compile() {
	emake -j1 elf static || die "emake elf static failed"

	cd slsh
	emake -j1 slsh || die "emake slsh failed"
}

src_install() {
	emake -j1 DESTDIR="${D}" install-all || die "emake install-all failed"

	rm -rf "${D}"/usr/share/doc/{slang,slsh}

	dodoc NEWS README *.txt doc/{,internal,text}/*.txt
	dohtml doc/slangdoc.html slsh/doc/html/*.html
}
