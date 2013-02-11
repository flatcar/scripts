# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-elf/ruby-elf-1.0.6.1.ebuild,v 1.2 2011/10/20 17:59:26 graaff Exp $

EAPI=2

USE_RUBY="ruby18 ruby19 ree18 jruby"
SRC_URI="mirror://rubyforge/${PN}/${P}.tar.bz2"
KEYWORDS="~amd64"

inherit ruby-ng

DESCRIPTION="Ruby library to access ELF files information"
HOMEPAGE="http://www.flameeyes.eu/projects/ruby-elf"

LICENSE="GPL-2"
SLOT="0"
IUSE="test"

ruby_add_bdepend "
	test? (
		dev-ruby/rake
		virtual/rubygems
		|| ( virtual/ruby-test-unit dev-ruby/test-unit:2 )
	)"

RDEPEND="${RDEPEND}
	virtual/man"

each_ruby_install() {
	doruby -r lib/* || die
}

each_ruby_test() {
	${RUBY} -S rake test || die "${RUBY} test failed"
}

all_ruby_install() {
	dobin bin/* || die
	doman manpages/*.1 || die "doman failed"
	dodoc DONATING || die "dodoc failed"
}
