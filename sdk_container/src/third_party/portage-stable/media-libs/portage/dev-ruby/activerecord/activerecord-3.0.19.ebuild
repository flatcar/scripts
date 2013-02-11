# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/activerecord/activerecord-3.0.19.ebuild,v 1.1 2013/01/09 09:18:01 graaff Exp $

EAPI=4
USE_RUBY="ruby18 ree18"

# this is not null so that the dependencies will actually be filled
RUBY_FAKEGEM_TASK_TEST="test"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="CHANGELOG README.rdoc"

RUBY_FAKEGEM_GEMSPEC="activerecord.gemspec"

inherit ruby-fakegem

DESCRIPTION="Implements the ActiveRecord pattern (Fowler, PoEAA) for ORM"
HOMEPAGE="http://rubyforge.org/projects/activerecord/"
SRC_URI="http://github.com/rails/rails/tarball/v${PV} -> rails-${PV}.tgz"

LICENSE="MIT"
SLOT="3.0"
KEYWORDS="~amd64 ~ppc ~ppc64 ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="mysql postgres sqlite3"

RUBY_S="rails-rails-*/activerecord"

ruby_add_rdepend "~dev-ruby/activesupport-${PV}
	~dev-ruby/activemodel-${PV}
	>=dev-ruby/arel-2.0.10-r1:2.0
	>=dev-ruby/tzinfo-0.3.23
	sqlite3? ( >=dev-ruby/sqlite3-1.3.3 )
	mysql? ( dev-ruby/mysql2:0.2 )
	postgres? ( dev-ruby/pg )"

ruby_add_bdepend "
	test? (
		dev-ruby/bundler
		~dev-ruby/actionpack-${PV}
		>=dev-ruby/sqlite3-1.3.3
		>=dev-ruby/mocha-0.10.5
	)"

all_ruby_prepare() {
	# Remove items from the common Gemfile that we don't need for this
	# test run. This also requires handling some gemspecs.
	sed -i -e '/\(uglifier\|system_timer\|sdoc\|w3c_validators\|pg\|jquery-rails\|"mysql"\|mysql2\)/d' ../Gemfile || die
	sed -i -e '/thor/d' ../railties/railties.gemspec || die
	sed -i -e '/mail/d' ../actionmailer/actionmailer.gemspec || die
	sed -i -e '/\(system_timer\|horo\|faker\|rbench\|ruby-debug\|pg\)/d' ../Gemfile || die

	# Loosen erubis dependency since this is not slotted.
	sed -i -e 's/~> 2.6.6/>= 2.6.6/' ../actionpack/actionpack.gemspec || die

	# Loosen mocha version restriction and skip incompatible tests
	sed -i -e 's/0.10.5/>= 0.10.5/' ../Gemfile || die
	rm test/cases/autosave_association_test.rb || die

	# Avoid test broken by security updates.
	sed -i -e '/test_serialize_should_be_reversible/,/^  end/ s:^:#:' test/cases/serialization_test.rb || die
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
