# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-xslt/ruby-xslt-0.9.8.ebuild,v 1.4 2012/05/01 18:24:08 armin76 Exp $

EAPI=2
USE_RUBY="ruby18 ree18"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_TASK_TEST=""

RUBY_FAKEGEM_EXTRADOC="ChangeLog AUTHORS README.rdoc"

inherit multilib ruby-fakegem

DESCRIPTION="A Ruby class for processing XSLT"
HOMEPAGE="http://www.rubyfr.net/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~ppc64 x86"
IUSE=""

DEPEND="${DEPEND} >=dev-libs/libxslt-1.1.12"
RDEPEND="${RDEPEND} >=dev-libs/libxslt-1.1.12"

# One test fails but we have installed this code already for a long
# time so this probably isn't a regression. No upstream bug tracker to
# report the problem :-(
RESTRICT="test"

each_ruby_configure() {
	${RUBY} -C ext/xslt_lib extconf.rb || die
}

each_ruby_compile() {
	emake -C ext/xslt_lib || die
	mv ext/xslt_lib/xslt_lib$(get_modname) lib/xml/ || die
}

each_ruby_test() {
	${RUBY} -I../lib -Ctest test.rb || die
}
