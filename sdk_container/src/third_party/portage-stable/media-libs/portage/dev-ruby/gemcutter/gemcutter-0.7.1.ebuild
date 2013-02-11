# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/gemcutter/gemcutter-0.7.1.ebuild,v 1.1 2012/05/12 09:11:53 graaff Exp $

EAPI=4

USE_RUBY="ruby18 ree18 ruby19"

RUBY_FAKEGEM_TASK_TEST="test"
RUBY_FAKEGEM_TASK_DOC=""

inherit ruby-fakegem

DESCRIPTION="Provides the gem yank and gem webhook commands to RubyGems."
HOMEPAGE="http://github.com/rubygems/gemcutter"
SRC_URI="https://github.com/rubygems/gemcutter/tarball/v${PV} -> ${P}-git.tgz"
RUBY_S="rubygems-gemcutter-*"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~ppc64 ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~x64-solaris ~x86-solaris"
IUSE=""

ruby_add_bdepend "
	test? (
		dev-ruby/shoulda
		>=dev-ruby/webmock-1.4.0
		dev-ruby/rr
		dev-ruby/activesupport
		dev-ruby/i18n
		dev-ruby/bundler
	)"

each_ruby_test() {
	# Tests fail unless being run through bundler.
	${RUBY} -S bundle exec rake test || die
}
