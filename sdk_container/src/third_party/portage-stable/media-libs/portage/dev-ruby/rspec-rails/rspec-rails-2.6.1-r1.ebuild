# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rspec-rails/rspec-rails-2.6.1-r1.ebuild,v 1.2 2012/05/17 10:50:48 tomka Exp $

EAPI=2

USE_RUBY="ruby18 ruby19 ree18"

RUBY_FAKEGEM_TASK_TEST=""

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="History.md README.md Upgrade.md"

RUBY_FAKEGEM_EXTRAINSTALL="templates"

inherit ruby-fakegem

DESCRIPTION="RSpec's official Ruby on Rails plugin"
HOMEPAGE="http://rspec.info/"

LICENSE="MIT"
SLOT="2"
KEYWORDS="~amd64 ~x86"
IUSE=""

ruby_add_rdepend "=dev-ruby/activesupport-3*
	=dev-ruby/actionpack-3*
	=dev-ruby/railties-3*
	dev-ruby/rspec:2"

each_ruby_test() {
	${RUBY} -S rspec spec || die "Tests failed."

	# There are also features but they require aruba which we don't have
	# yet and it requires local install of various rails versions.
}
