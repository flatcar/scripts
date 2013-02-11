# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libical/libical-0.48.ebuild,v 1.9 2012/06/06 01:26:12 darkside Exp $

EAPI=4

DESCRIPTION="An implementation of basic iCAL protocols from citadel, previously known as aurore"
HOMEPAGE="http://freeassociation.sourceforge.net"
#SRC_URI="mirror://sourceforge/freeassociation/files/${PN}/${P}/${P}.tar.gz"
SRC_URI="mirror://sourceforge/freeassociation/${PN}/${P}/${P}.tar.gz"

LICENSE="|| ( MPL-1.1 LGPL-2 )"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~x86-solaris"
IUSE="examples"

# https://sourceforge.net/tracker2/index.php?func=detail&aid=2196790&group_id=16077&atid=116077
# Upstream states that tests are supposed to fail (I hope sf updates archives
# and answer became visible):
# http://sourceforge.net/mailarchive/forum.php?thread_name=1257441040.20584.3431.camel%40tablet&forum_name=freeassociation-devel
RESTRICT="test"

src_prepare() {
	# Do not waste time building examples
	sed -i -e 's/^\(SUBDIRS =.*\)examples\(.*\)$/\1\2/' Makefile.{am,in} || die
	# If errors are fatal, some software can segfault
	sed -i \
		-e 's/^#define ICAL_ERRORS_ARE_FATAL 0/#undef ICAL_ERRORS_ARE_FATAL/' \
		configure || die
}

src_configure() {
	econf \
		--disable-static \
		--disable-icalerrors-are-fatal
}

src_install() {
	emake DESTDIR="${D}" install

	rm -f "${ED}"usr/lib*/${PN}*.la

	dodoc AUTHORS ChangeLog NEWS README TEST THANKS TODO \
		doc/{AddingOrModifyingComponents,UsingLibical}.txt

	if use examples; then
		rm examples/Makefile* examples/CMakeLists.txt
		insinto /usr/share/doc/${PF}/examples
		doins examples/*
	fi
}
