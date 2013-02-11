# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rspec-rails/rspec-rails-1.3.4.ebuild,v 1.5 2012/05/01 18:24:11 armin76 Exp $

EAPI=2

USE_RUBY="ruby18 ree18"

# would be spec, but it needs to be in the same filesystem tree as
# rspec (and cannot use the install-reduced code), so we cannot run
# them for now.
RUBY_FAKEGEM_TASK_TEST=""

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="Contribute.rdoc History.rdoc README.rdoc Upgrade.rdoc TODO.txt"

RUBY_FAKEGEM_EXTRAINSTALL="generators"

inherit ruby-fakegem

DESCRIPTION="RSpec's official Ruby on Rails plugin"
HOMEPAGE="http://rspec.info/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 ppc ~ppc64 x86 ~x86-macos"
IUSE=""

ruby_add_rdepend ">=dev-ruby/rspec-1.3.1 >=dev-ruby/rack-1.0.0"
