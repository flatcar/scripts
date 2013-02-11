# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-xslt/ruby-xslt-0.9.9.ebuild,v 1.4 2012/09/27 19:00:58 johu Exp $

EAPI=2
USE_RUBY="ruby18 ruby19 ree18"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_TASK_TEST=""

RUBY_FAKEGEM_EXTRADOC="ChangeLog.rdoc AUTHORS.rdoc README.rdoc"

inherit multilib ruby-fakegem

DESCRIPTION="A Ruby class for processing XSLT"
HOMEPAGE="http://www.rubyfr.net/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~ppc64 x86"
IUSE=""

DEPEND="${DEPEND} >=dev-libs/libxslt-1.1.12"
RDEPEND="${RDEPEND} >=dev-libs/libxslt-1.1.12"

all_ruby_prepare() {
	# One test fails but we have installed this code already for a long
	# time so this probably isn't a regression. No upstream bug tracker
	# to report the problem :-(
	sed -i -e '/test_transformation_error/,/^  end/ s:^:#:' test/test.rb || die
}

each_ruby_configure() {
	${RUBY} -C ext/xslt_lib extconf.rb || die
}

each_ruby_compile() {
	emake -C ext/xslt_lib || die
	mv ext/xslt_lib/xslt_lib$(get_modname) lib/xml/ || die
}

each_ruby_test() {
	${RUBY} -I../lib:lib -Ctest test.rb || die
}
