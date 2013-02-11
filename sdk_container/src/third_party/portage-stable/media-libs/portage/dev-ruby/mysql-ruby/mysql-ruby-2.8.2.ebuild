# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/mysql-ruby/mysql-ruby-2.8.2.ebuild,v 1.13 2012/07/01 18:31:43 armin76 Exp $

EAPI="3"
USE_RUBY="ruby18 ree18"

RUBY_FAKEGEM_NAME="mysql"

RUBY_FAKEGEM_TASK_TEST=""
RUBY_FAKEGEM_TASK_DOC=""

inherit ruby-fakegem

DESCRIPTION="A Ruby extension library to use MySQL"
HOMEPAGE="http://www.tmtm.org/en/mysql/ruby/"
SRC_URI="mirror://rubyforge/${PN}/${P}.tar.gz"

LICENSE="Ruby"
SLOT="0"
KEYWORDS="amd64 hppa ~mips ppc ppc64 x86 ~x86-fbsd"
IUSE="test"

DEPEND="virtual/mysql[-static]"
RDEPEND="${DEPEND}"

TEST_DIR="/usr/share/${PN}/test/"

all_ruby_prepare() {
	epatch "${FILESDIR}/${P}-test2.patch"
}

each_ruby_configure() {
	${RUBY} extconf.rb --with-mysql-config "${EPREFIX}/usr/bin/mysqlconfig" || die
}

each_ruby_compile() {
	emake || die
}

each_ruby_install() {
	emake DESTDIR="${D}" install || die
	ruby_fakegem_install_gemspec
}

all_fakegem_install() {
	dohtml * || die

	if use test ; then
		insinto $TEST_DIR
		doins test.rb || die
	fi
}

src_test() {
	elog
	elog "To test the library you need to start MySQL first."
	elog "Then run:"
	elog
	elog "	% ruby ${TEST_DIR}test.rb <hostname> <user> <password>"
	elog
	elog "See /usr/share/doc/${PF}/html/README.html for details."
	elog
}
