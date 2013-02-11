# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/dmalloc/dmalloc-5.5.2-r3.ebuild,v 1.8 2011/07/27 13:00:23 naota Exp $

EAPI="3"

inherit autotools eutils multilib

DESCRIPTION="A Debug Malloc Library"
HOMEPAGE="http://dmalloc.com"
SRC_URI="http://dmalloc.com/releases/${P}.tgz"

LICENSE="CCPL-Attribution-ShareAlike-3.0"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 s390 sh sparc x86 ~x86-fbsd"
IUSE="threads"

DEPEND="sys-apps/texinfo"
RDEPEND=""

src_prepare() {
	# - Build objects twice, once -fPIC for shared.
	# - Use DESTDIR.
	# - Fix SONAME and NEEDED.
	epatch "${FILESDIR}"/${P}-Makefile.in.patch
	# - Broken test, always returns false.
	epatch "${FILESDIR}"/${P}-cxx.patch
	# - Add threads support.
	use threads && epatch "${FILESDIR}"/${P}-threads.patch
	# Respect CFLAGS/LDFLAGS. #337429
	sed -i Makefile.in \
		-e '/libdmalloc/ s:$(CC):& $(CFLAGS) $(LDFLAGS):g' \
		|| die "sed Makefile.in"
	# - Run autoconf for -cxx.patch.
	eautoconf
}

src_configure() {
	econf --enable-cxx --enable-shlib \
		$(use_enable threads) || die "econf failed!"
}

src_compile() {
	emake || die "emake failed!"
	cd docs && makeinfo dmalloc.texi
}

src_test() {
	emake heavy || die "emake check failed!"
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed!"

	newdoc ChangeLog.1 ChangeLog
	dodoc NEWS README docs/NOTES docs/TODO
	insinto /usr/share/doc/${PF}
	doins docs/dmalloc.pdf
	dohtml RELEASE.html docs/dmalloc.html
	doinfo docs/dmalloc.info

	# add missing symlinks, lazy
	dosym lib${PN}.so.${PV} /usr/$(get_libdir)/lib${PN}.so
	for lib in cxx th thcxx; do
		dosym lib${PN}${lib}.so.${PV} /usr/$(get_libdir)/lib${PN}${lib}.so
	done
}
