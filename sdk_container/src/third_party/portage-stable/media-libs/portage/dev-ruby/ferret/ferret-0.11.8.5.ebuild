# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ferret/ferret-0.11.8.5.ebuild,v 1.1 2012/12/20 07:26:20 graaff Exp $

EAPI=4

# ruby19 fails tests
USE_RUBY="ruby18 ruby19 ree18"

RUBY_FAKEGEM_NAME="ferret"

RUBY_FAKEGEM_RECIPE_TEST="none"

RUBY_FAKEGEM_TASK_DOC="doc"
RUBY_FAKEGEM_DOCDIR="doc/api"

RUBY_FAKEGEM_EXTRADOC="CHANGELOG RELEASE_CHANGES RELEASE_NOTES README TODO TUTORIAL"

inherit multilib ruby-fakegem

MY_P="${P/ruby-/}"
DESCRIPTION="A ruby indexing/searching library"
HOMEPAGE="http://ferret.davebalmain.com/trac/"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

each_ruby_configure() {
	${RUBY} -Cext extconf.rb || die
}

each_ruby_compile() {
	emake -Cext CFLAGS="${CFLAGS} -fPIC" archflag="${LDFLAGS}"
	cp ext/ferret_ext$(get_modname) lib/ || die
}

each_ruby_test() {
	${RUBY} -Ilib test/test_all.rb || die
}
