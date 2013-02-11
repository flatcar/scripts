# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-eb/ruby-eb-2.6-r1.ebuild,v 1.2 2012/05/01 18:24:24 armin76 Exp $

EAPI=2
USE_RUBY="ruby18"

inherit ruby-ng

IUSE=""

MY_P="${P/-/}"
S=${WORKDIR}/${MY_P/a/}

DESCRIPTION="RubyEB is a ruby extension for EB Library"
HOMEPAGE="http://rubyeb.sourceforge.net/"
SRC_URI="http://rubyeb.sourceforge.net/${MY_P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~ppc ~x86"

COMMON_DEPEND="sys-libs/zlib
	>=dev-libs/eb-4.0-r1"
DEPEND="${DEPEND} ${COMMON_DEPEND}"
RDEPEND="${RDEPEND} ${COMMON_DEPEND}"

each_ruby_configure() {
	${RUBY} extconf.rb || die
}

each_ruby_compile() {
	emake || die
}

each_ruby_install() {
	DESTDIR="${D}" emake install || die
}

all_ruby_install() {
	dodoc ChangeLog || die
	dohtml eb.html  || die
}
