# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/oauth/oauth-0.4.6.ebuild,v 1.2 2012/08/04 14:14:14 graaff Exp $

EAPI="2"
USE_RUBY="ruby18 ree18 ruby19"

RUBY_FAKEGEM_TASK_DOC=""

RUBY_FAKEGEM_EXTRADOC="HISTORY README.rdoc TODO"

inherit ruby-fakegem

DESCRIPTION="A RubyGem for implementing both OAuth clients and servers."
HOMEPAGE="http://oauth.rubyforge.org/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~x86-macos"
IUSE=""

ruby_add_bdepend "test? (
		dev-ruby/mocha
		dev-ruby/webmock )"
USE_RUBY="ruby18 ree18" ruby_add_bdepend "test? ( >=dev-ruby/actionpack-2.3.8:2.3 )"

all_ruby_prepare() {
	# Ensure a consistent test order to avoid loading issues with e.g. rack
	sed -i -e "s/.rb']/.rb'].sort/" Rakefile || die
}

each_ruby_prepare() {
	case ${RUBY} in
		*ruby18)
			# Ignore hash ordering test failures
			sed -i -e '183s:^:#:' -e '224s:^:#:' test/integration/consumer_test.rb || die
			;;
		*rubyee18)
			# Ignore hash ordering test failures
			sed -i -e '183s:^:#:' -e '224s:^:#:' test/integration/consumer_test.rb || die
			;;
		*ruby19)
			# Remove tests depending on rails.
			rm test/test_action_controller_request_proxy.rb || die
			;;
		*)
			;;
	esac
}
