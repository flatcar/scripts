# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rest-client/rest-client-1.6.7-r1.ebuild,v 1.2 2012/08/13 17:29:17 flameeyes Exp $

EAPI=4
USE_RUBY="ruby18 ruby19 ree18"

RUBY_FAKEGEM_RECIPE_TEST="rspec"

RUBY_FAKEGEM_EXTRADOC="history.md README.rdoc"

inherit ruby-fakegem

DESCRIPTION="Simple Simple HTTP and REST client for Ruby"
HOMEPAGE="http://github.com/archiloque/rest-client"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RUBY_PATCHES=( "${FILESDIR}/rest-client-1.6.7-ruby19.patch" )

ruby_add_bdepend "doc? ( dev-ruby/jeweler )"
ruby_add_bdepend "test? ( dev-ruby/webmock )"

ruby_add_rdepend ">=dev-ruby/mime-types-1.16"

all_ruby_prepare() {
	# Remove spec that requires network access.
	rm spec/integration/request_spec.rb || die

	# Remove forced requirement of rspec 1.x and ruby-debug.
	sed -i -e '/\(spec\|ruby-debug\)/d' spec/base.rb || die
}
