# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/nanomsg/nanomsg-20121207.ebuild,v 1.2 2013/01/15 03:05:27 patrick Exp $

EAPI=4

RESTRICT="test" # funky failures

DESCRIPTION="High-performance messaging interface for distributed applications"
HOMEPAGE="https://github.com/250bpm/nanomsg"
SRC_URI="http://dev.gentooexperimental.org/~dreeevil/${P}.zip"

inherit eutils cmake-utils

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

S="${WORKDIR}/${PN}-master"
