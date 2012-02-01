# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-process/psmisc/psmisc-22.10.ebuild,v 1.6 2010/02/13 13:02:41 armin76 Exp $

inherit autotools eutils

DESCRIPTION="A set of tools that use the proc filesystem"
HOMEPAGE="http://psmisc.sourceforge.net/"
SRC_URI="mirror://sourceforge/psmisc/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86"
IUSE="ipv6 nls selinux X"

RDEPEND=">=sys-libs/ncurses-5.2-r2
	selinux? ( sys-libs/libselinux )"
DEPEND="${RDEPEND}
	sys-devel/libtool
	nls? ( sys-devel/gettext )"

src_unpack() {
	unpack ${A}
	cd "${S}"
	use nls || epatch "${FILESDIR}"/${PN}-22.5-no-nls.patch #193920
	eautoreconf
}

src_compile() {
	# the nls looks weird, but it's because we actually delete the nls stuff
	# above when USE=-nls.  this should get cleaned up so we dont have to patch
	# it out, but until then, let's not confuse users ... #220787
	econf \
		--disable-dependency-tracking \
		$(use_enable selinux) \
		$(use_enable ipv6) \
		$(use nls && use_enable nls)

	emake || die
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS ChangeLog NEWS README
	use X || rm "${D}"/usr/bin/pstree.x11
	# fuser is needed by init.d scripts
	dodir /bin
	mv "${D}"/usr/bin/fuser "${D}"/bin/ || die
	# easier to do this than forcing regen of autotools
	[[ -e ${D}/usr/bin/peekfd ]] || rm -f "${D}"/usr/share/man/man1/peekfd.1
}
