# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/gmime/gmime-2.2.27-r1.ebuild,v 1.9 2012/06/17 17:37:36 armin76 Exp $

EAPI="4"
GNOME_TARBALL_SUFFIX="bz2"
GCONF_DEBUG="no"

inherit gnome2 eutils mono libtool autotools

DESCRIPTION="Utilities for creating and parsing messages using MIME"
HOMEPAGE="http://spruce.sourceforge.net/gmime/"

SRC_URI="${SRC_URI} http://dev.gentoo.org/~pacho/gnome/gmime-sharp.snk"

SLOT="0"
LICENSE="LGPL-2.1"
KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 sparc x86 ~x86-fbsd"
IUSE="doc mono"

RDEPEND=">=dev-libs/glib-2:2
	sys-libs/zlib
	mono? (
		dev-lang/mono
		>=dev-dotnet/gtk-sharp-2.4.0:2 )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	dev-util/gtk-doc-am
	doc? (
		>=dev-util/gtk-doc-1.0
		app-text/docbook-sgml-utils )
	mono? ( dev-dotnet/gtk-sharp-gapi:2 )"

pkg_setup() {
	DOCS="AUTHORS ChangeLog COPYING INSTALL NEWS PORTING README TODO doc/html/"
	G2CONF="${G2CONF} $(use_enable mono)"
}

src_prepare() {
	epatch "${FILESDIR}/gmime-2.2.23-sign-assembly.patch"

	cp "${DISTDIR}/gmime-sharp.snk" mono/ || die
	if use doc ; then
		#db2html should be docbook2html
		sed -i -e 's:db2html:docbook2html -o gmime-tut:g' \
			docs/tutorial/Makefile.am docs/tutorial/Makefile.in \
			|| die "sed failed (1)"
		sed -i -e 's:db2html:docbook2html:g' configure.in configure \
			|| die "sed failed (2)"
		# Fix doc targets (bug #97154)
		sed -i -e 's!\<\(tmpl-build.stamp\): !\1 $(srcdir)/tmpl/*.sgml: !' \
			gtk-doc.make docs/reference/Makefile.in || die "sed failed (3)"
	fi

	eautoreconf
	elibtoolize
}

src_compile() {
	MONO_PATH="${S}" emake
	# 'all' rule doesn't generate html files
	use doc && cd docs/tutorial/ && emake html
}

src_install() {
	emake DESTDIR="${D}" install

	if use doc ; then
		# we don't use docinto/dodoc, because we don't want html doc gzipped
		insinto /usr/share/doc/${PF}/tutorial
		doins docs/tutorial/html/*
	fi

	# rename these two, so they don't conflict with app-arch/sharutils
	# (bug #70392)	Ticho, 2004-11-10
	mv "${ED}/usr/bin/uuencode" "${ED}/usr/bin/gmime-uuencode"
	mv "${ED}/usr/bin/uudecode" "${ED}/usr/bin/gmime-uudecode"
	mono_multilib_comply

	# Prevent collissions with 2.6 slot, bug #413145
	rm -f "${ED}/usr/share/gapi-2.0/gmime-api.xml" || die
}
