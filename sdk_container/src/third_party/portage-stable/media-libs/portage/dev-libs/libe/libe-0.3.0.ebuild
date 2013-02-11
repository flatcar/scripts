# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libe/libe-0.3.0.ebuild,v 1.1 2013/01/24 05:46:14 patrick Exp $
EAPI=4

inherit eutils

DESCRIPTION="Hyperdex libe support library"

HOMEPAGE="http://hyperdex.org"
SRC_URI="http://hyperdex.org/src/${P}.tar.gz"
LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"

IUSE=""

RDEPEND="dev-libs/libpo6"
DEPEND="${RDEPEND}
	virtual/pkgconfig"
