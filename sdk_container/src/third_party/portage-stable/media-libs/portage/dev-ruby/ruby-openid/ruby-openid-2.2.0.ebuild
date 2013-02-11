# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-openid/ruby-openid-2.2.0.ebuild,v 1.3 2012/10/17 03:53:20 phajdan.jr Exp $

EAPI="2"
USE_RUBY="ruby18 ruby19 jruby"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_TASK_TEST=""

RUBY_FAKEGEM_EXTRADOC="CHANGELOG.md README.md NOTICE UPGRADE.md"

inherit ruby-fakegem

DESCRIPTION="A robust library for verifying and serving OpenID identities"
HOMEPAGE="http://ruby-openid.rubyforge.org/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~ppc x86 ~x86-macos"
IUSE="test"

all_ruby_prepare() {
	# Comment out test failing due to hash ordering randomization:
	# https://github.com/openid/ruby-openid/issues/34
	rm test/test_xrires.rb || die

	sed -i -e 's/127.0.0.1/localhost/' test/test_fetchers.rb || die
	sed -i -e '134i :BindAddress => "localhost",' test/test_fetchers.rb || die
}

each_ruby_test() {
	${RUBY} -Ctest -I.:../lib -e "Dir['test_*.rb'].each {|f| require f}" || die
}

all_ruby_install() {
	all_fakegem_install

	insinto /usr/share/doc/${PF}
	doins -r examples || die
}
