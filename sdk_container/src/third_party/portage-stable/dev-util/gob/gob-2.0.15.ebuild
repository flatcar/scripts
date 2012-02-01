# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-util/gob/gob-2.0.15.ebuild,v 1.9 2008/09/27 16:36:38 armin76 Exp $

inherit gnome2

MY_PN=gob2
MY_P=${MY_PN}-${PV}
S=${WORKDIR}/${MY_P}
PVP=(${PV//[-\._]/ })

DESCRIPTION="Preprocessor for making GTK+ objects with inline C code"
HOMEPAGE="http://www.5z.com/jirka/gob.html"
SRC_URI="mirror://gnome/sources/${MY_PN}/${PVP[0]}.${PVP[1]}/${MY_P}.tar.bz2"

LICENSE="GPL-2"
SLOT="2"
KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 sh sparc x86"
IUSE=""

RDEPEND=">=dev-libs/glib-2"
DEPEND="${RDEPEND}
	dev-util/pkgconfig
	sys-devel/flex"

DOCS="AUTHORS ChangeLog NEWS README TODO"
