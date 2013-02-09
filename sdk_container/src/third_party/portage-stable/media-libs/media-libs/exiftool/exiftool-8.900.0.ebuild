# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/exiftool/exiftool-8.900.0.ebuild,v 1.5 2012/08/11 13:04:43 maekke Exp $

EAPI=4

MY_PN=Image-ExifTool
MODULE_AUTHOR=EXIFTOOL
MODULE_VERSION=8.90
inherit perl-module

DESCRIPTION="Read and write meta information in image, audio and video files"
HOMEPAGE="http://www.sno.phy.queensu.ca/~phil/exiftool/ ${HOMEPAGE}"
SRC_URI+=" http://www.sno.phy.queensu.ca/~phil/exiftool/${MY_P}.tar.gz"

SLOT="0"
KEYWORDS="amd64 ppc ppc64 x86"
IUSE=""

SRC_TEST="do"

src_install() {
	perl-module_src_install
	dohtml -r html/
}
