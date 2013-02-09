# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/lv2core/lv2core-6.0.ebuild,v 1.2 2011/12/07 13:48:22 aballier Exp $

EAPI=4

inherit waf-utils

DESCRIPTION="LV2 is a simple but extensible successor of LADSPA"
HOMEPAGE="http://lv2plug.in/"
SRC_URI="http://lv2plug.in/spec/${P}.tar.bz2"

LICENSE="LGPL-2.1 MIT"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE=""

DEPEND=""
RDEPEND="!<media-libs/slv2-0.4.2"
DOCS=( "AUTHORS" "README" "NEWS" )
