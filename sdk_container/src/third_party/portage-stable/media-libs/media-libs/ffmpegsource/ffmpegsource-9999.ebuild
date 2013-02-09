# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/ffmpegsource/ffmpegsource-9999.ebuild,v 1.4 2012/05/05 08:02:33 jdhore Exp $

EAPI=4

AUTOTOOLS_AUTORECONF=1

inherit subversion autotools-utils

DESCRIPTION="An FFmpeg based source library for easy frame accurate access"
HOMEPAGE="https://code.google.com/p/ffmpegsource/"
ESVN_REPO_URI="http://ffmpegsource.googlecode.com/svn/trunk/"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""
IUSE="static-libs"

RDEPEND="
	sys-libs/zlib
	>=virtual/ffmpeg-0.9
"
DEPEND="${RDEPEND}
	virtual/pkgconfig
"

src_configure() {
	local myeconfargs=(
		--docdir="${EPREFIX}/usr/share/doc/${PF}/html"
	)

	autotools-utils_src_configure
}
