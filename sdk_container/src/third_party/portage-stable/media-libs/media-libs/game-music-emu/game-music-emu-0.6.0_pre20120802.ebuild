# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/game-music-emu/game-music-emu-0.6.0_pre20120802.ebuild,v 1.2 2012/08/04 15:15:56 jer Exp $

EAPI=3

inherit cmake-utils

DESCRIPTION="Video game music file emulators"
HOMEPAGE="http://code.google.com/p/game-music-emu/"
SRC_URI="http://dev.gentoo.org/~angelos/${P}.tbz2"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ppc ~ppc64 ~x86 ~amd64-fbsd ~x86-fbsd"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

DOCS="changes.txt design.txt gme.txt readme.txt"
