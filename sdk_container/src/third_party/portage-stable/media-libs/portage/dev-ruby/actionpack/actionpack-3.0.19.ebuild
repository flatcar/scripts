# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/actionpack/actionpack-3.0.19.ebuild,v 1.1 2013/01/09 09:17:19 graaff Exp $

EAPI=4

USE_RUBY="ruby18 ree18"

# The default test task tries to test activerecord with SQLite as well.
RUBY_FAKEGEM_TASK_TEST="test_action_pack"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="CHANGELOG README.rdoc"

RUBY_FAKEGEM_GEMSPEC="actionpack.gemspec"

inherit ruby-fakegem

DESCRIPTION="Eases web-request routing, handling, and response."
HOMEPAGE="http://rubyforge.org/projects/actionpack/"
SRC_URI="http://github.com/rails/rails/tarball/v${PV} -> rails-${PV}.tgz"

LICENSE="MIT"
SLOT="3.0"
KEYWORDS="~amd64 ~ppc ~ppc64 ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE=""

RUBY_S="rails-rails-*/actionpack"

ruby_add_rdepend "
	~dev-ruby/activemodel-${PV}
	~dev-ruby/activesupport-${PV}
	>=dev-ruby/builder-2.1.2:0
	>=dev-ruby/erubis-2.6.6
	>=dev-ruby/i18n-0.5.0:0.5
	>=dev-ruby/rack-1.2.5:1.2
	>=dev-ruby/rack-mount-0.6.14:0.6
	>=dev-ruby/rack-test-0.5.7:0.5
	>=dev-ruby/tzinfo-0.3.23"

ruby_add_bdepend "
	test? (
		dev-ruby/bundler
		>=dev-ruby/mocha-0.10.5
		~dev-ruby/activerecord-${PV}
		~dev-ruby/actionmailer-${PV}
	)"

all_ruby_prepare() {
	# Remove items from the common Gemfile that we don't need for this
	# test run. This also requires handling some gemspecs.
	sed -i -e '/\(system_timer\|horo\|faker\|rbench\|ruby-debug\|pg\|mysql2\)/d' ../Gemfile || die
	sed -i -e '/thor/d' ../railties/railties.gemspec || die
	sed -i -e '/mail/d' ../actionmailer/actionmailer.gemspec || die

	# Loosen erubis dependency since this is not slotted.
	sed -i -e 's/~> 2.6.6/>= 2.6.6/' actionpack.gemspec || die

	# Loosen mocha version restriction
	sed -i -e 's/0.10.5/>= 0.10.5/' ../Gemfile || die

	# Ignore failure introduced by security measures in 3.0.17.
	sed -i -e '/test_select_tag_escapes_prompt/,/end/ s:^:#:' test/template/form_tag_helper_test.rb || die
}
