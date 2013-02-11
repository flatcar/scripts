# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-chasen/ruby-chasen-1.7-r1.ebuild,v 1.4 2011/06/30 15:02:21 ranger Exp $

EAPI=2
USE_RUBY="ruby18"

inherit ruby-ng

MY_P="chasen${PV}"
DESCRIPTION="ChaSen module for Ruby"
HOMEPAGE="http://raa.ruby-lang.org/list.rhtml?name=ruby-chasen"
SRC_URI="https://sites.google.com/a/ixenon.net/ruby-chasen/home/chasen1.7.tar.gz?attredirects=0 -> chasen-1.7.tar.gz"

LICENSE="Ruby"
SLOT="0"
KEYWORDS="amd64 ppc x86"
IUSE=""

DEPEND="${DEPEND} >=app-text/chasen-2.3.3-r2"
RDEPEND="${RDEPEND} >=app-text/chasen-2.3.3-r2"

S="${WORKDIR}/${MY_P}"

each_ruby_configure() {
	${RUBY} extconf.rb || die
}

each_ruby_compile() {
	emake || die
}

each_ruby_install() {
	DESTDIR="${D}" emake install || die
}

all_ruby_install() {
	insinto /usr/share/doc/${PF}
	doins -r sample || die
}
