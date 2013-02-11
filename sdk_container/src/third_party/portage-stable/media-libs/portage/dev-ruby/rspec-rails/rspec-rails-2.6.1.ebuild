# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rspec-rails/rspec-rails-2.6.1.ebuild,v 1.4 2012/05/01 18:24:11 armin76 Exp $

EAPI=2

USE_RUBY="ruby18 ree18"

RUBY_FAKEGEM_TASK_TEST=""

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="History.md README.md Upgrade.md"

RUBY_FAKEGEM_EXTRAINSTALL="templates"

inherit ruby-fakegem

DESCRIPTION="RSpec's official Ruby on Rails plugin"
HOMEPAGE="http://rspec.info/"

LICENSE="MIT"
SLOT="2"
KEYWORDS="~amd64 ~ppc ~ppc64 ~x86"
IUSE=""

ruby_add_rdepend "dev-ruby/activesupport:3.0
	dev-ruby/actionpack:3.0
	dev-ruby/railties:3.0
	dev-ruby/rspec:2"

each_ruby_test() {
	${RUBY} -S rspec spec || die "Tests failed."

	# There are also features but they require aruba which we don't have
	# yet and it requires local install of various rails versions.
}
