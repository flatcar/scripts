# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/i18n/i18n-0.6.0-r1.ebuild,v 1.7 2013/01/16 01:08:23 zerochaos Exp $

EAPI=4

USE_RUBY="ruby18 jruby ree18 ruby19"

# doc regeneration seem to need Jeweler, which is not currently
# available
RUBY_FAKEGEM_TASK_DOC=""

RUBY_FAKEGEM_EXTRADOC="README.textile CHANGELOG.textile"

inherit ruby-fakegem versionator

DESCRIPTION="Add Internationalization support to your Ruby application."
HOMEPAGE="http://rails-i18n.org/"

SRC_URI="http://github.com/svenfuchs/${PN}/tarball/v${PV} -> ${PN}-git-${PV}.tgz"
RUBY_S="svenfuchs-${PN}-*"

LICENSE="MIT"
SLOT="$(get_version_component_range 1-2)"
KEYWORDS="~amd64 ~arm ~hppa ~ppc ~ppc64 ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

# The testsuite uses the activerecord gem to run some tests; they
# require sqlite3-ruby, and that is not available on JRuby.
#USE_RUBY="${USE_RUBY/jruby/}" \
#	ruby_add_bdepend "
#			test? (
#				dev-ruby/activerecord
#				dev-ruby/sqlite3
#				dev-ruby/ruby2ruby
#			)"

# mocha is optionally used by the testsuite, try to increase coverage
# of testing by depending on it.
#
# One further test dependency would be ruby-cldr
# (http://rubygems.org/gems/ruby-cldr) but we don't have it in tree
# yet.
ruby_add_bdepend "
	test? (
		dev-ruby/mocha
		dev-ruby/test_declarative
	)"

all_ruby_prepare() {
	sed -i -e '/bundler/ s:^:#:' test/test_helper.rb || die
}

each_ruby_prepare() {
	case ${RUBY} in
		*ruby19)
			# Remove tests that require a UTF-8 locale.
			rm test/gettext/backend_test.rb || die

			# Remove tests that contains a 1.9.3-specific failure.
			# https://github.com/svenfuchs/i18n/issues/114
			rm test/i18n/load_path_test.rb || die
			;;
		*)
			;;
	esac
}

src_compile() {
	# permissions need to be stricter for Ruby-Inline to work properly.
	chmod 0755 "${HOME}" || die "Failed to fix permissions on home"
	ruby-ng_src_compile
}

src_test() {
	# permissions need to be stricter for Ruby-Inline to work properly.
	chmod 0755 "${HOME}" || die "Failed to fix permissions on home"
	ruby-ng_src_test
}

each_ruby_test() {
	# Make sure the optional activerecord tests are not run for jruby
	# because we don't ship a compatible sqlite3
	case ${RUBY} in
		*jruby)
			;;
		*)
			each_fakegem_test
	esac
}
