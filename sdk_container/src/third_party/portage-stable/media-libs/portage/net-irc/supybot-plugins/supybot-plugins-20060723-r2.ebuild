# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-irc/supybot-plugins/supybot-plugins-20060723-r2.ebuild,v 1.3 2010/11/04 12:48:54 maekke Exp $

EAPI="3"
PYTHON_DEPEND="2"
SUPPORT_PYTHON_ABIS="1"

inherit eutils python

MY_PN="Supybot-plugins"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Official set of extra plugins for Supybot"
HOMEPAGE="http://supybot.com"
SRC_URI="mirror://sourceforge/supybot/${MY_P}.tar.bz2"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE=""

DEPEND=""
RDEPEND=">=net-irc/supybot-0.83.4
		 >=dev-python/twisted-conch-8.1.0
		 >=dev-python/twisted-web-1.0"
RESTRICT_PYTHON_ABIS="3.*"

S="${WORKDIR}/${MY_P}"

src_prepare(){
	epatch "${FILESDIR}/${PN}_credentials.patch"
}

src_install() {
	installation() {
		for plugin in *; do
			case ${plugin} in
				BadWords|Dunno|Success)
					# These plugins are part of supybot-0.83.4 now, so skip them here.
					continue
					;;
				*)
					;;
			esac

			insinto $(python_get_sitedir)/supybot/plugins/${plugin}
			doins ${plugin}/*
		done
	}
	python_execute_function installation
}

pkg_postinst() {
	python_mod_optimize supybot/plugins
}

pkg_postrm() {
	python_mod_cleanup supybot/plugins
}
