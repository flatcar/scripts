# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/vanessa-adt/vanessa-adt-0.0.4_beta4.ebuild,v 1.7 2005/01/21 21:47:18 xmerlin Exp $

DESCRIPTION="Provides Abstract Data Types (ADTs) Includes queue, dynamic array, hash and key value ADT."
HOMEPAGE="http://www.vergenet.net/linux/vanessa/"
SRC_URI="http://www.vergenet.net/linux/perdition/download/BETA/1.11beta5/vanessa_adt-0.0.4beta4.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86 ~ppc"
IUSE=""

DEPEND=">=dev-libs/vanessa-logger-0.0.4_beta2"
S=${WORKDIR}/vanessa_adt-0.0.4beta4

src_install() {
	einstall || die
	dodoc AUTHORS NEWS README TODO
}
