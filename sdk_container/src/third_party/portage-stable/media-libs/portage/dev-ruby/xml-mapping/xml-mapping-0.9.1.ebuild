# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/xml-mapping/xml-mapping-0.9.1.ebuild,v 1.4 2012/09/24 16:30:05 graaff Exp $

EAPI=4
# ruby19, jruby → fails tests
USE_RUBY="ruby18"

RUBY_FAKEGEM_TASK_TEST=""
RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="ChangeLog README README_XPATH TODO.txt doc/xpath_impl_notes.txt"

inherit ruby-fakegem

DESCRIPTION="XML-to-object (and back) mapper for Ruby, including XPath interpreter"
HOMEPAGE="http://xml-mapping.rubyforge.org/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

each_ruby_test() {
	${RUBY} -I. test/all_tests.rb || die "Failed to run tests."
}

all_ruby_install() {
	all_fakegem_install

	insinto /usr/share/doc/${PF}
	doins -r examples || die
}
