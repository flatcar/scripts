# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libpwquality/libpwquality-1.2.0-r1.ebuild,v 1.1 2012/12/05 08:54:27 tetromino Exp $

EAPI="5"
PYTHON_DEPEND="python? 2:2.7"

inherit eutils multilib pam python

DESCRIPTION="Library for password quality checking and generating random passwords"
HOMEPAGE="https://fedorahosted.org/libpwquality/"
SRC_URI="https://fedorahosted.org/releases/l/i/${PN}/${P}.tar.bz2"

LICENSE="|| ( BSD GPL-2 )"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="pam python static-libs"

RDEPEND=">=sys-libs/cracklib-2.8
	pam? ( virtual/pam )"
DEPEND="${RDEPEND}
	sys-devel/libtool
	virtual/pkgconfig"

pkg_setup() {
	if use python; then
		python_set_active_version 2
		python_pkg_setup
	fi
}

src_prepare() {
	# ensure pkgconfig files go in /usr
	sed -e 's:\(pkgconfigdir *=\).*:\1 '${EPREFIX}/usr/$(get_libdir)'/pkgconfig:' \
		-i src/Makefile.{am,in} || die "sed failed"
}

src_configure() {
	# Install library in /lib for pam
	local sitedir
	use python && sitedir="${EPREFIX}$(python_get_sitedir)"
	econf \
		--libdir="${EPREFIX}/$(get_libdir)" \
		$(use_enable pam) \
		--with-securedir="${EPREFIX}/$(getpam_mod_dir)" \
		$(use_enable python python-bindings) \
		--with-pythonsitedir="${sitedir}" \
		$(use_enable static-libs static)
}

src_install() {
	default
	prune_libtool_files --modules
}
