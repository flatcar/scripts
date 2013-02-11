# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/diff/diff-0.4-r1.ebuild,v 1.6 2012/05/01 18:24:20 armin76 Exp $

EAPI="2"
USE_RUBY="ruby18"

inherit ruby-ng

DESCRIPTION="Computes the differences between two arrays of elements"
HOMEPAGE="http://users.cybercity.dk/~dsl8950/ruby/diff.html"
#SRC_URI="http://users.cybercity.dk/~dsl8950/ruby/${P}.tar.gz"
SRC_URI="http://www.rubynet.org/mirrors/diff/${P}.tar.gz"

LICENSE="GPL-2"
KEYWORDS="~amd64 ppc ppc64 x86"

IUSE=""
SLOT="0"

each_ruby_test() {
	pushd test
	${RUBY} -I../lib test_diff.rb || die "test_diff.rb failed."
	popd
}

each_ruby_install() {
	${RUBY} install.rb config --prefix="${D}"/usr
	${RUBY} install.rb install
}

all_ruby_install() {
	dodoc README TODO
	docinto samples
	dodoc samples/*.rb
}
