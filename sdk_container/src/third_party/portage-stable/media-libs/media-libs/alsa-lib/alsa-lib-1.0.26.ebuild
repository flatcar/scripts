# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/alsa-lib/alsa-lib-1.0.26.ebuild,v 1.2 2012/09/09 08:32:27 ssuominen Exp $

EAPI=4

PYTHON_DEPEND="python? 2:2.6"

inherit autotools eutils multilib python

DESCRIPTION="Advanced Linux Sound Architecture Library"
HOMEPAGE="http://www.alsa-project.org/"
SRC_URI="mirror://alsaproject/lib/${P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sh ~sparc ~x86 ~amd64-linux ~x86-linux"
IUSE="doc debug alisp python"

RDEPEND=""
DEPEND=">=media-sound/alsa-headers-1.0.25
	doc? ( >=app-doc/doxygen-1.2.6 )"

pkg_setup() {
	if use python; then
		python_set_active_version 2
		python_pkg_setup
	fi
}

src_prepare() {
	epatch "${FILESDIR}"/1.0.25-extraneous-cflags.diff
	eautoreconf
	epunt_cxx
}

src_configure() {
	local myconf
	use elibc_uclibc && myconf="--without-versioned"

	econf \
		--enable-shared \
		--disable-resmgr \
		--enable-rawmidi \
		--enable-seq \
		--enable-aload \
		$(use_with debug) \
		$(use_enable alisp) \
		$(use_enable python) \
		${myconf}
}

src_compile() {
	emake

	if use doc; then
		emake doc
		fgrep -Zrl "${S}" "${S}/doc/doxygen/html" | \
			xargs -0 sed -i -e "s:${S}::"
	fi
}

src_install() {
	emake DESTDIR="${D}" install

	prune_libtool_files --all
	find "${ED}"/usr/$(get_libdir)/alsa-lib -name '*.a' -exec rm -f {} +

	dodoc ChangeLog TODO
	use doc && dohtml -r doc/doxygen/html/*
}
