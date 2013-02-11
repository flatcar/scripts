# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/railties/railties-3.1.3.ebuild,v 1.4 2013/01/16 00:49:20 zerochaos Exp $

EAPI=4
USE_RUBY="ruby18 ruby19 ree18"

RUBY_FAKEGEM_TASK_TEST="test:regular"
RUBY_FAKEGEM_TASK_DOC="generate_guides"
RUBY_FAKEGEM_DOCDIR="guides/output"
RUBY_FAKEGEM_EXTRADOC="CHANGELOG.md README.rdoc"

RUBY_FAKEGEM_GEMSPEC="railties.gemspec"

inherit ruby-fakegem

DESCRIPTION="Tools for creating, working with, and running Rails applications."
HOMEPAGE="http://github.com/rails/rails"
SRC_URI="http://github.com/rails/rails/tarball/v${PV} -> rails-${PV}.tgz"

LICENSE="MIT"
SLOT="3.1"
KEYWORDS="~amd64 ~arm ~ppc64 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""

RUBY_S="rails-rails-*/railties"

# The test suite has many failures, most likely due to a mismatch in
# exact dependencies or environment specifics. Needs further
# investigation.
RESTRICT="test"

ruby_add_rdepend "
	~dev-ruby/activesupport-${PV}
	~dev-ruby/actionpack-${PV}
	>=dev-ruby/rdoc-3.4
	>=dev-ruby/thor-0.14.6
	>=dev-ruby/rack-ssl-1.3.2:1.3
	>=dev-ruby/rake-0.8.7"

ruby_add_bdepend "
	test? (
		>=dev-ruby/mocha-0.9.5
		virtual/ruby-test-unit
	)
	doc? (
		>=dev-ruby/redcloth-4.1.1
	)"

all_ruby_prepare() {
	# Remove items from the common Gemfile that we don't need for this
	# test run. This also requires handling some gemspecs.
	sed -i -e '/\(uglifier\|system_timer\|sdoc\|w3c_validators\|pg\)/d' ../Gemfile || die
}
