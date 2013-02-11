# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-openid/ruby-openid-2.2.2.ebuild,v 1.2 2013/01/27 13:44:14 graaff Exp $

EAPI=4
USE_RUBY="ruby18 ruby19 jruby"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_TASK_TEST=""

RUBY_FAKEGEM_EXTRADOC="CHANGELOG.md README.md NOTICE UPGRADE.md"

inherit ruby-fakegem

DESCRIPTION="A robust library for verifying and serving OpenID identities"
HOMEPAGE="http://ruby-openid.rubyforge.org/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86 ~x86-macos"
IUSE="test"

ruby_add_bdepend "test? ( dev-ruby/test-unit:2 )"

all_ruby_prepare() {
	sed -i -e 's/127.0.0.1/localhost/' test/test_fetchers.rb || die
	sed -i -e '155i :BindAddress => "localhost",' test/test_fetchers.rb || die
}

each_ruby_prepare() {
	case ${RUBY} in
		*ruby19)
			# Fix test failures with non UTF-8 encoding, bug 454186
			sed -i -e "1i Encoding::default_external = Encoding.find('utf-8')" test/testutil.rb || die
			;;
		*)
			;;
	esac
}

each_ruby_test() {
	ruby-ng_testrb-2 test/test_*.rb
}

all_ruby_install() {
	all_fakegem_install

	insinto /usr/share/doc/${PF}
	doins -r examples || die
}
