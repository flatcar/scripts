# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rspec-rails/rspec-rails-2.12.2.ebuild,v 1.1 2013/01/16 07:24:15 graaff Exp $

EAPI=5

USE_RUBY="ruby18 ruby19 ree18"

RUBY_FAKEGEM_RECIPE_TEST="rspec"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="Changelog.md README.md"

inherit ruby-fakegem versionator

DESCRIPTION="RSpec's official Ruby on Rails plugin"
HOMEPAGE="http://rspec.info/"

LICENSE="MIT"
SLOT="2"
KEYWORDS="~amd64"
IUSE=""

SUBVERSION="$(get_version_component_range 1-2)"

ruby_add_rdepend "=dev-ruby/activesupport-3*
	=dev-ruby/actionpack-3*
	=dev-ruby/railties-3*
	=dev-ruby/rspec-${SUBVERSION}*"

# Depend on the package being already installed for tests, because
# requiring ammeter will load it, and we need a consistent set of rspec
# and rspec-rails for that to work.
ruby_add_bdepend "test? ( >=dev-ruby/ammeter-0.2.5 ~dev-ruby/rspec-rails-${PV} )"
