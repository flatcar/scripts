# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/guile-gtk/guile-gtk-1.2.0.60.ebuild,v 1.3 2009/05/05 07:43:45 ssuominen Exp $

MAJOR_PV=${PV%.[0-9]*.[0-9]*}
MINOR_PV=${PV#[0-9]*.[0-9]*.}
MY_P="${PN}-${MINOR_PV}"
DESCRIPTION="GTK+ bindings for guile"
HOMEPAGE="http://www.gnu.org/software/guile-gtk/"
SRC_URI="mirror://gnu/guile-gtk/${MY_P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE=""

RDEPEND=">=dev-scheme/guile-1.6
	=x11-libs/gtk+-1.2*"
DEPEND="${RDEPEND}"

S=${WORKDIR}/${MY_P}

src_install() {
	make DESTDIR="${D}" install || die

	dodoc README* AUTHORS ChangeLog NEWS TODO
	insinto /usr/share/guile-gtk/examples
	doins "${S}"/examples/*.scm
}
