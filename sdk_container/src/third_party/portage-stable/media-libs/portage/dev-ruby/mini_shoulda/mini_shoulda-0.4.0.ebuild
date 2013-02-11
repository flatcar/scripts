# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/mini_shoulda/mini_shoulda-0.4.0.ebuild,v 1.1 2012/08/02 09:58:04 graaff Exp $

EAPI=4
USE_RUBY="ruby18 ruby19 ree18 jruby"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="CHANGELOG README.rdoc"

inherit ruby-fakegem

DESCRIPTION="A minimal shoulda DSL built on top of MiniTest::Spec."
HOMEPAGE="https://github.com/seattlerb/minitest"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

ruby_add_rdepend ">dev-ruby/minitest-2.1.0"

all_ruby_prepare() {
	sed -i -e '/git ls-files/d' mini_shoulda.gemspec || die
	sed -i -e '/[Bb]undler/ s:^:#:' Rakefile test/test_helper.rb || die

	# Avoid a test that is supposed to fail
	sed -i -e '/DuppedScopeTest/,$ s:^:#:' test/scope_test.rb || die
}
