# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/httparty/httparty-0.9.0.ebuild,v 1.1 2012/12/22 15:02:43 graaff Exp $

EAPI=2

# jruby → testsuite fails (seems like a testuite bug)
USE_RUBY="ruby18 ruby19 ree18"

# We have a custom test function, but don't null this out so that the
# deps are still added
RUBY_FAKEGEM_TASK_TEST="none"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="README.md History"

inherit ruby-fakegem

DESCRIPTION="Makes http fun! Also, makes consuming restful web services dead easy."
HOMEPAGE="http://httparty.rubyforge.org/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE=""

ruby_add_rdepend '=dev-ruby/multi_json-1* dev-ruby/multi_xml'

ruby_add_bdepend 'dev-ruby/rspec:0 dev-ruby/fakeweb'

USE_RUBY=ruby18 \
	ruby_add_bdepend 'test? ( dev-util/cucumber www-servers/mongrel )'

all_ruby_prepare() {
	# Remove bundler
	rm Gemfile || die
	sed -i -e '/[Bb]undler/ s:^:#:' Rakefile || die

#	sed -i -e '/git ls-files/ s:^:#:' ${PN}.gemspec || die
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
