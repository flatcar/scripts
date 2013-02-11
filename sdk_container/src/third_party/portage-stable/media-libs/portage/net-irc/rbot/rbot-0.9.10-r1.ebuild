# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-irc/rbot/rbot-0.9.10-r1.ebuild,v 1.6 2013/01/12 08:24:44 ulm Exp $

inherit ruby gems

DESCRIPTION="rbot is a ruby IRC bot"
HOMEPAGE="http://www.linuxbrit.co.uk/rbot/"
SRC_URI="http://www.linuxbrit.co.uk/downloads/${P}.gem"

LICENSE="feh"
SLOT="0"
KEYWORDS="~amd64 ~ppc x86 ~x86-fbsd"
IUSE="spell"

RDEPEND="=dev-lang/ruby-1.8*
	dev-ruby/ruby-bdb"
DEPEND="${RDEPEND}"

pkg_postinst() {
	elog
	elog "Default configuration file location has changed from /etc/rbot to ~/.rbot"
	elog
}
