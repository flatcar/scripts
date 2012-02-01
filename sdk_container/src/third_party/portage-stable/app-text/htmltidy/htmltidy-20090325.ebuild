# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-text/htmltidy/htmltidy-20090325.ebuild,v 1.10 2010/01/02 12:16:07 fauli Exp $

EAPI=2
inherit eutils autotools

MY_PN="tidy"
MY_P=${MY_PN}-${PV}
S="${WORKDIR}"/${MY_P}

DESCRIPTION="Tidy the layout and correct errors in HTML and XML documents"
HOMEPAGE="http://tidy.sourceforge.net/"
SRC_URI="mirror://gentoo/${MY_P}.tar.bz2
	mirror://gentoo/${MY_P}-doc.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos"
IUSE="debug doc"

DEPEND="doc? ( app-doc/doxygen )"
RDEPEND=""

src_prepare() {
	# Required to setup the source dist for autotools
	einfo "Setting up autotools for source build"
	cp -R  ./build/gnuauto/* . || die "could not prepare autotools environment"

	# Stop tidy from appending -O2 to our CFLAGS
	epatch "${FILESDIR}"/htmltidy-5.10.26-strip-O2-flag.patch

	# Define /etc/tidyrc for system wide config, bug 154834
	epatch "${FILESDIR}"/htmltidy-20090325-tidyrc.patch

	eautoreconf
}

src_compile() {
	default

	if use doc ; then
		doxygen htmldoc/doxygen.cfg  || die "error making apidocs"
	fi
}

src_configure() {
	econf $(use_enable debug)
}

src_install() {
	emake DESTDIR="${D}" install || die "error during make install"

	cd "${S}"/htmldoc
	# It seems the manual page installation in the Makefile's
	# is commented out, so we need to install manually
	# for the moment. Please check this on updates.
	# mv man_page.txt tidy.1
	# doman tidy.1
	#
	# Update:
	# Now the man page is provided as an xsl file, which
	# we can't use until htmltidy is merged.
	# I have generated the man page and quickref which is on
	# the mirrors. (bug #132429)
	doman "${WORKDIR}"/${MY_P}-doc/tidy.1

	# Install basic html documentation
	dohtml *.html *.css *.gif "${WORKDIR}"/${MY_P}-doc/quickref.html

	# If use 'doc' is set, then we also want to install the
	# api documentation
	use doc && dohtml -r api
}
