# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/activesupport/activesupport-3.0.19.ebuild,v 1.1 2013/01/09 09:16:15 graaff Exp $

EAPI=4

# jruby fails tests.
USE_RUBY="ruby18 ree18"

RUBY_FAKEGEM_TASK_DOC=""

RUBY_FAKEGEM_EXTRADOC="CHANGELOG README.rdoc"

RUBY_FAKEGEM_GEMSPEC="activesupport.gemspec"

RUBY_FAKEGEM_BINWRAP=""

inherit ruby-fakegem

DESCRIPTION="Utility Classes and Extension to the Standard Library"
HOMEPAGE="http://rubyforge.org/projects/activesupport/"
SRC_URI="https://github.com/rails/rails/tarball/v${PV} -> rails-${PV}.tgz"

LICENSE="MIT"
SLOT="3.0"
KEYWORDS="~amd64 ~ppc ~ppc64 ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE=""

RUBY_S="rails-rails-*/${PN}"

ruby_add_rdepend ">=dev-ruby/memcache-client-1.5.8"

# libxml-ruby and nokogiri are not strictly needed, but there are tests
# using this code.
ruby_add_bdepend "test? ( >=dev-ruby/libxml-2.0.0 dev-ruby/nokogiri >=dev-ruby/mocha-0.10.5 )"

all_ruby_prepare() {
	# don't support older mocha versions as the optional codepath
	# breaks JRuby
	epatch "${FILESDIR}"/${PN}-3.0.3-mocha-0.9.5.patch

	# Set test environment to our hand.
	rm "${S}/../Gemfile" || die "Unable to remove Gemfile"
	sed -i -e '/load_paths/d' test/abstract_unit.rb || die "Unable to remove load paths"

	# Avoid tests that do not work with newer versions of mocha.
	rm test/whiny_nil_test.rb || die

	# Avoid tests failing due to slightly different builder semantics.
	sed -i -e '/test_one_level_with_nils/,/end/ s:^:#:' \
		-e '/test_one_level_with_skipping_types/,/end/ s:^:#:' \
		test/core_ext/hash_ext_test.rb || die
}
