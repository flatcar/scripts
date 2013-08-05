# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-text/gnome-doc-utils/gnome-doc-utils-0.20.10.ebuild,v 1.11 2013/02/12 07:16:21 tetromino Exp $

EAPI="4"
GCONF_DEBUG="no"
PYTHON_DEPEND="2:2.5"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="3.* *-jython *-pypy-*"

inherit gnome2 python

DESCRIPTION="A collection of documentation utilities for the Gnome project"
HOMEPAGE="http://live.gnome.org/GnomeDocUtils"

LICENSE="GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE=""

RDEPEND=">=dev-libs/libxml2-2.6.12[python]
	 >=dev-libs/libxslt-1.1.8
"
DEPEND="${RDEPEND}
	>=dev-util/intltool-0.35
	app-text/docbook-xml-dtd:4.4
	app-text/scrollkeeper-dtd
	sys-devel/gettext
	virtual/awk
	virtual/pkgconfig"
# dev-libs/glib needed for eautofoo, bug #255114.

# If there is a need to reintroduce eautomake or eautoreconf, make sure
# to AT_M4DIR="tools m4", bug #224609 (m4 removes glib build time dep)

pkg_setup() {
	DOCS="AUTHORS ChangeLog NEWS README"
	G2CONF="${G2CONF} --disable-scrollkeeper"
	python_pkg_setup
}

src_prepare() {
	gnome2_src_prepare

	python_clean_py-compile_files

	python_copy_sources
}

src_configure() {
	python_execute_function -s gnome2_src_configure
}

src_compile() {
	python_execute_function -d -s
}

src_test() {
	python_execute_function -d -s
}

src_install() {
	installation() {
		gnome2_src_install
		python_convert_shebangs $(python_get_version) "${ED}"usr/bin/xml2po
		mv "${ED}"usr/bin/xml2po "${ED}"usr/bin/xml2po-$(python_get_version)
	}
	python_execute_function -s installation
	python_clean_installation_image

	python_generate_wrapper_scripts -E -f "${ED}"usr/bin/xml2po
}

pkg_postinst() {
	python_mod_optimize xml2po
	gnome2_pkg_postinst
}

pkg_postrm() {
	python_mod_cleanup xml2po
	gnome2_pkg_postrm
}
