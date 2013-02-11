# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/semacode/semacode-0.7.4.ebuild,v 1.1 2011/09/18 12:31:16 flameeyes Exp $

EAPI=4

# jruby → it's a native extension
# ruby19 → needs trivial patching
USE_RUBY="ruby18 ree18"

RUBY_FAKEGEM_TASK_TEST="test"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_DOCDIR=""

RUBY_FAKEGEM_EXTRADOC="CHANGELOG README"

inherit ruby-fakegem

DESCRIPTION="DataMatrix encoder for Ruby"
HOMEPAGE="http://sohne.net/projects/semafox/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

each_ruby_configure() {
	${RUBY} -C ext extconf.rb || die "extconf.rb failed"
}

each_ruby_compile() {
	emake -C ext \
		CFLAGS="${CFLAGS} -fPIC" archflag="${LDFLAGS}" || die "emake failed"
	cp ext/semacode_native.so lib || die
}

each_ruby_test() {
	${RUBY} -Ilib tests/test.rb || die "tests failed"
}
