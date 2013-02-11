# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ammeter/ammeter-0.2.5.ebuild,v 1.3 2012/08/16 03:51:20 flameeyes Exp $

EAPI=4
USE_RUBY="ruby18 ruby19 ree18"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_TASK_TEST="spec"

RUBY_FAKEGEM_EXTRADOC="README.md"

RUBY_FAKEGEM_GEMSPEC="${PN}.gemspec"

inherit ruby-fakegem

DESCRIPTION="Write specs for your Rails 3+ generators"
HOMEPAGE="https://github.com/alexrothenberg/ammeter"
LICENSE="MIT"

SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"

ruby_add_rdepend "
	>=dev-ruby/activesupport-3.0
	>=dev-ruby/railties-3.0
	>=dev-ruby/rspec-2.2
	>=dev-ruby/rspec-rails-2.2
"

ruby_add_bdepend "
	test? (
		>=dev-ruby/rails-3.1
		dev-ruby/uglifier
		dev-ruby/rake
		dev-ruby/coffee-rails
		dev-ruby/sass-rails
		dev-ruby/jquery-rails
		dev-util/cucumber
		dev-util/aruba
		dev-ruby/sqlite3
	)"

all_ruby_prepare() {
	# fix the gemspec; we remove the version dependencies from there, as
	# it requires _older_ versions of its dependencies.. it doesn't
	# really seem to be the case though. Also remove the references to
	# git ls-files to avoid calling it.
	sed -i \
		-e '/git ls-files/d' \
		-e '/\(cucumber\|aruba\)/s:,.*$::' \
		${RUBY_FAKEGEM_GEMSPEC} || die
}
