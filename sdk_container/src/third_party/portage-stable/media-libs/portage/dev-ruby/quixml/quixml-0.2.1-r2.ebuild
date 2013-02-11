# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/quixml/quixml-0.2.1-r2.ebuild,v 1.3 2012/05/01 18:24:09 armin76 Exp $

EAPI=2
USE_RUBY="ruby18"

inherit ruby-ng

DESCRIPTION="A fast Ruby XML API written in C"
HOMEPAGE="http://quixml.rubyforge.org/"
SRC_URI="http://rubyforge.org/download.php/89/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~hppa ~ppc ~x86"
IUSE=""

DEPEND="${DEPEND} dev-libs/expat"
RDEPEND="${RDEPEND} dev-libs/expat"

each_ruby_configure() {
	${RUBY} extconf.rb || die
}

each_ruby_compile() {
	emake || die
}

each_ruby_install() {
	emake install DESTDIR="${D}" || die
}

all_ruby_install() {
	dodoc BUGS CHANGELOG README
	dohtml DOC.html
}
