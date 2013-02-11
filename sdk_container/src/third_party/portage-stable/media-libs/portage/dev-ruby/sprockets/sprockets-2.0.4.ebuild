# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/sprockets/sprockets-2.0.4.ebuild,v 1.2 2013/01/16 00:32:50 zerochaos Exp $

EAPI=4
USE_RUBY="ruby18 ruby19 ree18"

RUBY_FAKEGEM_TASK_DOC=""

RUBY_FAKEGEM_GEMSPEC="sprockets.gemspec"

inherit ruby-fakegem versionator

DESCRIPTION="Ruby library for compiling and serving web assets."
HOMEPAGE="https://github.com/sstephenson/sprockets"
SRC_URI="https://github.com/sstephenson/sprockets/tarball/v${PV} -> ${P}.tgz"
RUBY_S="sstephenson-sprockets-*"

LICENSE="MIT"
SLOT="$(get_version_component_range 1-2)"
KEYWORDS="~amd64 ~arm ~ppc64 ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"

IUSE=""

ruby_add_rdepend "
	=dev-ruby/hike-1* >=dev-ruby/hike-1.2
	=dev-ruby/rack-1*
	>=dev-ruby/tilt-1.3.1"

ruby_add_bdepend "test? (
		dev-ruby/json
		dev-ruby/rack-test
	)"

# Restrict tests for now since they require quite lot of new
# dependencies related to javascript. To be revisited later.
RESTRICT="test"
#  s.add_development_dependency "coffee-script", "~> 2.0"
#  s.add_development_dependency "eco", "~> 1.0"
#  s.add_development_dependency "ejs", "~> 1.0"
#  s.add_development_dependency "execjs", "~> 1.0"
