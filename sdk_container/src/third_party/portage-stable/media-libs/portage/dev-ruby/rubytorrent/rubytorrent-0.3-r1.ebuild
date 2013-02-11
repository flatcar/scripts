# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rubytorrent/rubytorrent-0.3-r1.ebuild,v 1.2 2012/05/01 18:24:03 armin76 Exp $

EAPI=2
USE_RUBY="ruby18"

inherit ruby-ng

DESCRIPTION="A pure-Ruby BitTorrent peer library and toolset"
HOMEPAGE="http://rubytorrent.rubyforge.org/"
SRC_URI="http://rubyforge.org/frs/download.php/3017/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE=""

each_ruby_install() {
	local sitelibdir=$(ruby_rbconfig_value "sitelibdir")
	doruby rubytorrent.rb || die
	insinto "${sitelibdir}/rubytorrent"
	doins rubytorrent/* || die
}

all_ruby_install() {
	dodoc doc/* README ReleaseNotes.txt
	docinto examples
	dodoc dump-metainfo.rb dump-peers.rb make-metainfo.rb \
		rtpeer-ncurses.rb rtpeer.rb
}
