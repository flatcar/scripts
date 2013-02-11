# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/net-geoip/net-geoip-0.07.ebuild,v 1.7 2012/05/01 18:24:24 armin76 Exp $

EAPI="2"
USE_RUBY="ruby18"

inherit ruby-ng

IUSE=""

DESCRIPTION="Ruby bindings for the GeoIP library"
HOMEPAGE="http://www.maxmind.com/app/ruby"
SRC_URI="http://geolite.maxmind.com/download/geoip/api/ruby/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 ppc ppc64 x86"

DEPEND="${DEPEND} >=dev-libs/geoip-1.2.1"
RDEPEND="${RDEPEND} >=dev-libs/geoip-1.2.1"

each_ruby_configure() {
	${RUBY} extconf.rb || die
}

each_ruby_compile() {
	emake || die
}

each_ruby_install () {
	emake install DESTDIR="${D}" || die
}

all_ruby_install() {
	dodoc README TODO
}
