# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-yadis/ruby-yadis-0.3.4-r1.ebuild,v 1.2 2012/09/22 08:06:11 graaff Exp $

EAPI=4
USE_RUBY="ruby18 ruby19 jruby"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_TASK_TEST=""

RUBY_FAKEGEM_EXTRADOC="README"

inherit ruby-fakegem

DESCRIPTION="A ruby library for performing Yadis service discovery"
HOMEPAGE="http://yadis.rubyforge.org/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~ppc ~x86 ~amd64"
IUSE="test"

each_ruby_prepare() {
	# Remove live tests that require content that is no longer available.
	rm test/test_discovery.rb || die
	sed -i -e '/test_discovery/d' test/runtests.rb || die
}

each_ruby_test() {
	${RUBY} -I../lib:lib:test -Ctest runtests.rb || die
}

all_ruby_install() {
	all_fakegem_install

	insinto /usr/share/doc/${PF}
	doins -r examples
}
