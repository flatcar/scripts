# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/nora/nora-0.0.20041114-r1.ebuild,v 1.2 2012/05/01 18:24:26 armin76 Exp $

EAPI=2
USE_RUBY="ruby18"

inherit ruby-ng

IUSE=""

DESCRIPTION="Nora - ruby libraries for web application library"
HOMEPAGE="http://raa.ruby-lang.org/list.rhtml?name=nora"
SRC_URI="http://www.moonwolf.com/ruby/archive/${P}.tar.gz"

LICENSE="Ruby"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~ppc64 ~x86"

each_ruby_configure() {
	${RUBY} setup.rb config --prefix=/usr || die
}

each_ruby_compile() {
	${RUBY} setup.rb setup || die
}

each_ruby_install() {
	${RUBY} setup.rb install --prefix="${D}" || die
}

all_ruby_install() {
	dodoc README.ja || die

	insinto /usr/share/doc/${PF}
	doins -r sample || die
}
