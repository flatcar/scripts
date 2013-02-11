# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-irc/supybot/supybot-0.83.4.1-r2.ebuild,v 1.4 2012/05/14 21:31:01 marienz Exp $

EAPI="3"
PYTHON_DEPEND="2"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="3.*"

inherit distutils

MY_P="${P/supybot/Supybot}"
MY_P="${MY_P/_rc/rc}"

DESCRIPTION="Python based extensible IRC infobot and channel bot"
HOMEPAGE="http://supybot.sf.net/"
SRC_URI="mirror://sourceforge/supybot/${MY_P}.tar.bz2"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 ~arm ppc ~sparc x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~sparc-solaris"
IUSE="twisted"

DEPEND="twisted? (
		>=dev-python/twisted-8.1.0[crypt]
		>=dev-python/twisted-names-8.1.0
	)
	!<net-irc/supybot-plugins-20060723-r1"
RDEPEND="${DEPEND}"

S="${WORKDIR}/${MY_P}"

DOCS="ACKS RELNOTES docs/[!man]*"

src_install() {
	distutils_src_install
	doman docs/man/* || die "doman failed"
}

pkg_postinst() {
	distutils_pkg_postinst

	elog "Use supybot-wizard to create a configuration file."
	if use twisted; then
		elog "If you want to use Twisted as your supybot.driver, add it to your config file:"
		elog "supybot.drivers.module = Twisted"
	else
		elog "To allow supybot to use Twisted as driver, reinstall supybot with \"twisted\" USE flag enabled."
	fi
	elog "You will need this for SSL connections."
}
