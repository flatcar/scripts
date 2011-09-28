# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/atk/atk-1.32.0-r1.ebuild,v 1.9 2011/07/11 00:03:33 mattst88 Exp $

EAPI="3"
GCONF_DEBUG="no"

inherit gnome2

DESCRIPTION="GTK+ & GNOME Accessibility Toolkit"
HOMEPAGE="http://projects.gnome.org/accessibility/"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 ~s390 sh sparc x86 ~x86-fbsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris ~x86-winnt"
IUSE="doc +introspection nls"

RDEPEND="dev-libs/glib:2
	introspection? ( >=dev-libs/gobject-introspection-0.6.7 )"
DEPEND="${RDEPEND}
	>=dev-lang/perl-5
	dev-util/pkgconfig
	doc? ( >=dev-util/gtk-doc-1 )
	nls? ( sys-devel/gettext )"

pkg_setup() {
	G2CONF="${G2CONF} $(use_enable introspection)"
	DOCS="AUTHORS ChangeLog NEWS README"
}

src_prepare() {
	gnome2_src_prepare

	if ! use test; then
		# don't waste time building tests (bug #226353)
		sed 's/^\(SUBDIRS =.*\)tests\(.*\)$/\1\2/' -i Makefile.am Makefile.in \
			|| die "sed failed"
	fi

	# Remove DEPRECATED flags
	sed -e '/-D[A-Z_]*DISABLE_DEPRECATED/d' -i atk/Makefile.am atk/Makefile.in \
		tests/Makefile.am tests/Makefile.in || die "sed 2 failed"
}
