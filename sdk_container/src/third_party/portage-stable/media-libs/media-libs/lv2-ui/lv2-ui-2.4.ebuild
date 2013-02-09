# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/lv2-ui/lv2-ui-2.4.ebuild,v 1.2 2012/03/01 13:46:11 tomka Exp $

EAPI=3
inherit waf-utils

DESCRIPTION="Generic UI interface for LV2 plugins"
HOMEPAGE="http://lv2plug.in/ns/extensions/ui"
SRC_URI="http://lv2plug.in/spec/${P}.tar.bz2"

LICENSE="ISC"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND=">=media-libs/lv2core-6.0"

DOCS=( "NEWS" )
