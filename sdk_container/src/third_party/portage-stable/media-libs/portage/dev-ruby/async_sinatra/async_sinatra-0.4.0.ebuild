# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/async_sinatra/async_sinatra-0.4.0.ebuild,v 1.1 2011/02/20 14:15:24 graaff Exp $

EAPI="2"
USE_RUBY="ruby18 ree18"

RUBY_FAKEGEM_DOCDIR="html"
RUBY_FAKEGEM_EXTRADOC="CHANGELOG.rdoc README.rdoc"

RUBY_FAKEGEM_TASK_TEST=""

# the documentation-building requires the gemspec file that is not
# packaged, this is very unfortunate for us, but the doc does not
# really tell us much so we're not going out of our way to get this
# from GIT. Upstream bug filed.
RUBY_FAKEGEM_TASK_DOC=""

inherit ruby-fakegem

DESCRIPTION="Asynchronous response API for Sinatra and Thin"
HOMEPAGE="http://libraggi.rubyforge.org/async_sinatra"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"

RUBY_PATCHES=( "${FILESDIR}/${P}-rack.patch" )

ruby_add_bdepend "test? ( dev-ruby/test-unit:2 dev-ruby/eventmachine )"

ruby_add_rdepend '>=dev-ruby/sinatra-1.0
	>=www-servers/thin-1.2.0'

each_ruby_test() {
	${RUBY} -Ilib test/test_async.rb || die "Tests failed."
}

all_ruby_install() {
	all_fakegem_install

	insinto /usr/share/doc/${PF}/
	doins -r examples || die "Failed to install examples"
}
