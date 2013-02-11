# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/coffee-rails/coffee-rails-3.2.2.ebuild,v 1.3 2013/01/16 00:50:10 zerochaos Exp $

EAPI=4
USE_RUBY="ruby18 ruby19 ree18"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="README.markdown"

inherit ruby-fakegem

DESCRIPTION="Coffee Script adapter for the Rails asset pipeline."
HOMEPAGE="https://github.com/rails/coffee-rails"

LICENSE="MIT"
SLOT="3.2"
KEYWORDS="~amd64 ~arm ~x86 ~x64-macos"

IUSE=""

ruby_add_rdepend ">=dev-ruby/coffee-script-2.2.0
	dev-ruby/railties:3.2"

all_ruby_prepare() {
	# Apply upstream fix for failing test
	sed -i -e 's/this.CoffeeScript/CoffeeScript Compiler/' test/assets_test.rb || die
}
