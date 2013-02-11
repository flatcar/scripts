# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/unf/unf-0.0.5-r1.ebuild,v 1.4 2012/11/25 19:17:18 tomka Exp $

EAPI=4

USE_RUBY="ruby18 ruby19 ree18 jruby"

RUBY_FAKEGEM_RECIPE_TEST="none"
RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="README.md"

RUBY_FAKEGEM_GEMSPEC="${PN}.gemspec"

inherit ruby-fakegem

DESCRIPTION="A wrapper library to bring Unicode Normalization Form support to Ruby/JRuby."
HOMEPAGE="https://github.com/knu/ruby-unf"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~ppc64 ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~x86-solaris"
IUSE="test"

# jruby already has support for UNF so it does not need the extension.
USE_RUBY=${USE_RUBY/jruby/} ruby_add_rdepend "dev-ruby/unf_ext"

ruby_add_bdepend "
	test? (
		>=dev-ruby/test-unit-2.5.1-r1
		dev-ruby/shoulda
	)"

all_ruby_prepare() {
	sed -i -e '/bundler/,/end/ d' test/helper.rb || die

	# Remove development dependencies; also remove platform as we don't
	# care about it as it is, they only use it to avoid the unf_ext dep
	# that we tackle on our own; finally remove git ls-files usage.
	sed -i -e '/dependency.*\(shoulda\|bundler\|jeweler\|rcov\)/d' \
		-e '/platform/d' \
		-e '/git ls/d' \
		${RUBY_FAKEGEM_GEMSPEC} || die
}

each_ruby_prepare() {
	if [[ ${RUBY} == *jruby ]]; then
		# Remove dependency over unf_ext which does not exist for JRuby
		# remove platform, we don't set it.
		sed -i -e '/dependency.*unf_ext/d' \
			${RUBY_FAKEGEM_GEMSPEC} || die
	fi
}

each_ruby_test() {
	ruby-ng_testrb-2 test/test_*.rb
}
