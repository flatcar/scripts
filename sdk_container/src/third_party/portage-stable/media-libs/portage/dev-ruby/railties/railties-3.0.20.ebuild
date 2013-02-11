# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/railties/railties-3.0.20.ebuild,v 1.1 2013/01/28 22:24:35 graaff Exp $

EAPI=4
USE_RUBY="ruby18 ree18"

RUBY_FAKEGEM_TASK_TEST="test:regular"
RUBY_FAKEGEM_TASK_DOC="generate_guides"
RUBY_FAKEGEM_DOCDIR="guides/output"
RUBY_FAKEGEM_EXTRADOC="CHANGELOG README.rdoc"

RUBY_FAKEGEM_GEMSPEC="railties.gemspec"

inherit ruby-fakegem

DESCRIPTION="Tools for creating, working with, and running Rails applications."
HOMEPAGE="http://github.com/rails/rails"
SRC_URI="http://github.com/rails/rails/tarball/v${PV} -> rails-${PV}.tgz"

LICENSE="MIT"
SLOT="3.0"
KEYWORDS="~amd64 ~ppc ~ppc64 ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
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
	>=dev-ruby/thor-0.14.4
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
	# allow newer thor
	sed -i -e '/dependency.*thor/s:~>:>=:' ${RUBY_FAKEGEM_GEMSPEC} || die
}
