# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/httparty/httparty-0.6.1.ebuild,v 1.4 2010/10/09 09:25:17 graaff Exp $

EAPI=2

# ruby19 → testsuite fails (might be crack's bug)
# jruby → testsuite fails (seems like a testuite bug)
USE_RUBY="ruby18"

# We have a custom test function, but don't null this out so that the
# deps are still added
RUBY_FAKEGEM_TASK_TEST="none"

RUBY_FAKEGEM_DOCDIR="rdoc"
RUBY_FAKEGEM_EXTRADOC="README.rdoc History"

inherit ruby-fakegem

DESCRIPTION="Makes http fun! Also, makes consuming restful web services dead easy."
HOMEPAGE="http://httparty.rubyforge.org/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE=""

# Code should most likely be patched, but for now…
ruby_add_rdepend '~dev-ruby/crack-0.1.8'

ruby_add_bdepend 'dev-ruby/rspec:0 dev-ruby/fakeweb'

USE_RUBY=ruby18 \
	ruby_add_bdepend 'test? ( dev-util/cucumber dev-ruby/activesupport:2.3 www-servers/mongrel )'

all_ruby_prepare() {
	# as often, Rakefile depends on Jeweler's presence
	sed -i \
		-e '/check_dependencies/s:^:#:' \
		Rakefile || die
}

each_ruby_test() {
	case ${RUBY} in
		*ruby18)
			# Cucumber-based tests only work on Ruby 1.8, as of today, so we only call them
			${RUBY} -S rake spec features || die "cucumber tests failed"
			;;
		*)
			${RUBY} -S rake spec || die "cucumber tests failed"
			;;
	esac
}

all_ruby_install() {
	all_fakegem_install

	docinto examples
	dodoc examples/* || die
}
