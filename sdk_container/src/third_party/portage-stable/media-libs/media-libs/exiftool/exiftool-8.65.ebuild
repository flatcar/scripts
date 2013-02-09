# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/exiftool/exiftool-8.65.ebuild,v 1.4 2012/02/05 18:28:15 armin76 Exp $

EAPI=2

MODULE_AUTHOR=EXIFTOOL
MY_PN=Image-ExifTool
MY_P=${MY_PN}-${PV}
S=${WORKDIR}/${MY_P}
inherit perl-module

DESCRIPTION="Read and write meta information in image, audio and video files"
HOMEPAGE="http://www.sno.phy.queensu.ca/~phil/exiftool/ ${HOMEPAGE}"
SRC_URI="${SRC_URI} http://www.sno.phy.queensu.ca/~phil/exiftool/${MY_P}.tar.gz"

SLOT="0"
KEYWORDS="amd64 ~ppc ~ppc64 x86"
IUSE=""

SRC_TEST="do"

src_install() {
	perl-module_src_install
	dohtml -r html/
}
