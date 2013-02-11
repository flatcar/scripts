# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libverto/libverto-0.2.4.ebuild,v 1.6 2012/11/30 08:09:46 eras Exp $

EAPI=4
inherit autotools

DESCRIPTION="Main event loop abstraction library"
HOMEPAGE="https://fedorahosted.org/libverto/"
SRC_URI="https://fedorahosted.org/releases/l/i/libverto/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~hppa ~ppc ~x86 ~amd64-fbsd"
IUSE="glib +libev libevent tevent +threads static-libs"

# file collisions
DEPEND="!=app-crypt/mit-krb5-1.10.1-r0
	!=app-crypt/mit-krb5-1.10.1-r1
	!=app-crypt/mit-krb5-1.10.1-r2
	glib? ( >=dev-libs/glib-2.29 )
	libev? ( >=dev-libs/libev-4.11 )
	libevent? ( >=dev-libs/libevent-2.0 )
	tevent? ( sys-libs/tevent )"

RDEPEND="${DEPEND}"

REQUIRED_USE="|| ( glib libev libevent tevent ) "

src_prepare() {
	if ! use static-libs; then
		sed -i -e 's/libverto.a/libverto.so/' tests/Makefile.{am,in} || die
	fi
	sed -i -e '/^AC_CHECK_LIB/i PKG_PROG_PKG_CONFIG' configure.ac || die

	# known problem uptream with tevent write test.  tevent does not fire a
	# callback on error, but we explicitly test for this behaviour.  Do not run
	# tevent tests for now.
	sed -i -e 's/def HAVE_TEVENT/ 0/' tests/test.h || die

	eautoreconf
}

src_configure() {
	econf \
		$(use_with glib) \
		$(use_with libev) \
		$(use_with libevent) \
		$(use_with tevent) \
		$(use_with threads pthread) \
		$(use_enable static-libs static)
}

src_install() {
	emake DESTDIR="${D}" install

	dodoc AUTHORS ChangeLog NEWS INSTALL README

	use static-libs || find "${D}" -name '*.la' -delete
}
