# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-net-ldap/ruby-net-ldap-0.0.4-r1.ebuild,v 1.2 2010/06/30 18:47:03 graaff Exp $

EAPI="2"
# ruby19: test failed
USE_RUBY="ruby18 ree18 jruby"

RUBY_FAKEGEM_TASK_TEST=""
RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="ChangeLog README"

inherit ruby-fakegem

DESCRIPTION="Pure ruby LDAP client implementation."
HOMEPAGE="http://net-ldap.rubyforge.org/"
LICENSE="GPL-2"

KEYWORDS="~amd64 ~x86"
SLOT="0"
IUSE="test"

ruby_add_bdepend "test? ( virtual/ruby-test-unit )"

# There are more tests but these require a live LDAP server. Only run
# the standalone tests.
each_ruby_test() {
	${RUBY} -Ilib -rtest/unit tests/testber.rb || die "tests failed"
	${RUBY} -Ilib -rtest/unit tests/testpsw.rb || die "tests failed"
}
