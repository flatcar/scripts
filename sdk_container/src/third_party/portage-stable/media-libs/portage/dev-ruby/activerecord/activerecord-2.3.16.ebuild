# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/activerecord/activerecord-2.3.16.ebuild,v 1.5 2013/01/31 17:47:28 ago Exp $

EAPI=2
USE_RUBY="ruby18 ree18 jruby"

# this is not null so that the dependencies will actually be filled
RUBY_FAKEGEM_TASK_TEST="none"

RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="CHANGELOG README"

inherit ruby-fakegem

DESCRIPTION="Implements the ActiveRecord pattern (Fowler, PoEAA) for ORM"
HOMEPAGE="http://rubyforge.org/projects/activerecord/"

LICENSE="MIT"
SLOT="2.3"
KEYWORDS="amd64 ~hppa ppc ppc64 x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~x64-solaris ~x86-solaris"
IUSE="mysql postgres sqlite3" #sqlite

ruby_add_rdepend "~dev-ruby/activesupport-${PV}"

#ruby_add_rdepend sqlite ">=dev-ruby/sqlite-ruby-2.2.2"
USE_RUBY=ruby18 \
	ruby_add_rdepend "
		sqlite3? ( dev-ruby/sqlite3 )
		mysql? ( >=dev-ruby/mysql-ruby-2.7 )
		postgres? ( dev-ruby/pg )"

ruby_add_bdepend "
	test? (
		dev-ruby/rdoc
		=dev-ruby/mocha-0.10*
	)"

all_ruby_prepare() {
	# Custom template not found in package
	sed -i -e '/horo/d' Rakefile || die

	# Remove test cases with hash ordering failures.
	sed -i -e '/test_bind_enumerable/,/end/ s:^:#:' test/cases/finder_test.rb || die
	sed -i -e '/test_should_automatically_build_new_associated/,/^  end/ s:^:#:' test/cases/nested_attributes_test.rb || die

	# Make sure we load a compatible version of activesupport for tests.
	sed -i -e '10igem "activesupport", "~>2.3.15"' test/cases/helper.rb || die

	# Drop test now broken by security fixes.
	rm test/cases/serialization_test.rb
}

each_ruby_test() {
	case ${RUBY} in
		*jruby)
			;;
		*)
			if use sqlite3; then
				${RUBY} -S rake test_sqlite3 || die "sqlite3 tests failed"
			fi
			;;
	esac
}
