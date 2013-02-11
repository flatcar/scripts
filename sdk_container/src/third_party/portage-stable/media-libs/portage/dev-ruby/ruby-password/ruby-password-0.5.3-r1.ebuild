# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-password/ruby-password-0.5.3-r1.ebuild,v 1.2 2012/09/16 09:41:35 graaff Exp $

EAPI=4

# ruby19 → compilation failure.
USE_RUBY="ruby18"

inherit multilib ruby-ng

DESCRIPTION="Ruby/Password comprises a set of useful methods for creating, verifying and manipulating passwords."
HOMEPAGE="http://www.caliban.org/ruby/"
SRC_URI="http://www.caliban.org/files/ruby/${P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
IUSE="test"
KEYWORDS="~amd64 ~x86"

ruby_add_rdepend ">=dev-ruby/ruby-termios-0.9.4"

DEPEND="${DEPEND} sys-libs/cracklib"
RDEPEND="${RDEPEND} sys-libs/cracklib"

each_ruby_configure() {
	${RUBY} extconf.rb || die
}

each_ruby_compile() {
	emake || die
}

each_ruby_test() {
	${RUBY} -I.:lib test/tc_password.rb || die
}

each_ruby_install() {
	DESTDIR="${D}" emake install || die
}

all_ruby_install() {
	dodoc Changelog CHANGES README

	insinto /usr/share/doc/${PF}
	doins -r example
}
