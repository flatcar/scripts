# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/raptor/raptor-2.0.7.ebuild,v 1.9 2012/05/18 08:48:54 aballier Exp $

# FIXME: It should be possible to use net-nntp/inn for libinn.h and -linn!

EAPI=4
inherit libtool

MY_P=${PN}2-${PV}

DESCRIPTION="The RDF Parser Toolkit"
HOMEPAGE="http://librdf.org/raptor/"
SRC_URI="http://download.librdf.org/source/${MY_P}.tar.gz"

LICENSE="Apache-2.0 GPL-2 LGPL-2.1"
SLOT="2"
KEYWORDS="amd64 arm hppa ppc ppc64 x86 ~amd64-fbsd ~x86-fbsd ~x64-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="+curl debug json static-libs unicode"

RDEPEND="dev-libs/libxml2
	dev-libs/libxslt
	curl? ( net-misc/curl )
	json? ( dev-libs/yajl )
	unicode? ( dev-libs/icu )
	!media-libs/raptor:0"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	sys-devel/flex"

S=${WORKDIR}/${MY_P}

DOCS="AUTHORS ChangeLog NEWS NOTICE README"

src_prepare() {
	elibtoolize
}

src_configure() {
	local myconf='--with-www=xml'
	use curl && myconf='--with-www=curl'

	econf \
		$(use_enable static-libs static) \
		$(use_enable debug) \
		$(use unicode && echo --with-icu-config="${EPREFIX}"/usr/bin/icu-config) \
		$(use_with json yajl) \
		--with-html-dir="${EPREFIX}"/usr/share/doc/${PF}/html \
		${myconf}
}

src_install() {
	default
	dohtml {NEWS,README,RELEASE,UPGRADING}.html
	find "${ED}" -name '*.la' -exec rm -f {} +
}
