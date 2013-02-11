# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rubyfilter/rubyfilter-0.12-r1.ebuild,v 1.2 2012/05/01 18:24:23 armin76 Exp $

EAPI=2
USE_RUBY="ruby18"

inherit ruby-ng

DESCRIPTION="A mail handling library for Ruby"
HOMEPAGE="http://www.lickey.com/rubyfilter/"
SRC_URI="http://www.lickey.com/rubyfilter/download/${P}.tar.gz"
LICENSE="BSD"

SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"

IUSE=""

ruby_add_rdepend "dev-ruby/rubymail"

each_ruby_configure() {
	ruby install.rb config --prefix=/usr || die
}

each_ruby_compile() {
	ruby install.rb setup || die
}

each_ruby_install() {
	ruby install.rb config --prefix="${D}/usr" || die
	ruby install.rb install || die
}

all_ruby_install() {
	dodoc NEWS README THANKS TODO || die
	dohtml -r doc/* || die
}
