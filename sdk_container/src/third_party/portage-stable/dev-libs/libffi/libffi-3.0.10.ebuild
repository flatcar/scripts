# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libffi/libffi-3.0.10.ebuild,v 1.1 2011/08/29 17:40:29 flameeyes Exp $

EAPI=2

MY_P=${P/_}

inherit libtool toolchain-funcs eutils

DESCRIPTION="a portable, high level programming interface to various calling conventions."
HOMEPAGE="http://sourceware.org/libffi/"
SRC_URI="ftp://sourceware.org/pub/${PN}/${MY_P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~ppc-aix ~sparc-fbsd ~x86-fbsd ~x64-freebsd ~hppa-hpux ~ia64-hpux ~x86-interix ~amd64-linux ~ia64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="debug static-libs test"

RDEPEND=""
DEPEND="test? ( dev-util/dejagnu )"

S=${WORKDIR}/${MY_P}

pkg_setup() {
	# Detect and document broken installation of sys-devel/gcc in the build.log wrt #354903
	if ! has_version dev-libs/libffi; then
		local base="${T}/conftest"
		echo 'int main() { }' > "${base}.c"
		$(tc-getCC) -o "${base}" "${base}.c" -lffi >&/dev/null && \
			ewarn "Found a copy of second libffi in your system. Uninstall it before continuing."
	fi
}

src_prepare() {
	elibtoolize
}

src_configure() {
	use userland_BSD && export HOST="${CHOST}"
	econf \
		--disable-dependency-tracking \
		$(use_enable static-libs static) \
		$(use_enable debug)
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc ChangeLog* README
	find "${D}" -name '*.la' -exec rm -f {} +
}
