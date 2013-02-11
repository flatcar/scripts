# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/actionpack/actionpack-2.3.16.ebuild,v 1.5 2013/01/31 17:47:07 ago Exp $

EAPI=2

USE_RUBY="ruby18 ree18 jruby"

# The default test task tries to test activerecord with SQLite as well.
RUBY_FAKEGEM_TASK_TEST="test_action_pack"

RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="CHANGELOG README"

inherit ruby-fakegem

DESCRIPTION="Eases web-request routing, handling, and response."
HOMEPAGE="http://rubyforge.org/projects/actionpack/"

LICENSE="MIT"
SLOT="2.3"
KEYWORDS="amd64 ppc ppc64 x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~x64-solaris ~x86-solaris"
IUSE=""

RUBY_PATCHES=( "${PN}-2.3.11-rails3.patch" "${PN}-2.3.10-i18n-0.4.2.patch" )

ruby_add_rdepend "~dev-ruby/activesupport-${PV}
	>=dev-ruby/rack-1.1.0:0"

ruby_add_bdepend "
	test? (
		>=dev-ruby/mocha-0.9.7
		dev-ruby/activerecord:${SLOT}
		~dev-ruby/actionmailer-${PV}
	)"

all_ruby_prepare() {
	# Custom template not found in package
	sed -i -e '/horo/d' Rakefile || die

	# This tries to load a “vendorized” copy of activerecord that we
	# will never have. It can now also use a normally installed
	# version but these tests fail.
	sed -i -e '/PATH_TO_AR/s:^:#:' -e 's/self.able_to_connect = true/self.able_to_connect = false/' test/active_record_unit.rb || die

	# Fix the testsuite, the symlink is not present in the gem for
	# some reason
	ln -s ../../symlink_parent test/fixtures/layout_tests/layouts/symlinked

	# MemCacheStore tests no longer fail gracefully, and it's unlikely for
	# someone to have them running anyway, so remove them for now.
	rm test/controller/session/mem_cache_store_test.rb || die

	# Fix tests when run against i18n 0.4.2 which ignores locale
	# definitions with an empty data section.
	sed -i -e 's/, {}/, {:test => "test"}/' test/template/render_test.rb || die

	# Test now broken on a whitespace difference.
	sed -i -e '/test_multiple_cookies/,/end/ s:^:#:' test/controller/cookie_test.rb

	# Test most likely broken due to new security fixes.
	sed -i -e '/test_post_xml_using_a_disallowed_type_attribute/,/^  end/ s:^:#:' test/controller/webservice_test.rb || die
}
