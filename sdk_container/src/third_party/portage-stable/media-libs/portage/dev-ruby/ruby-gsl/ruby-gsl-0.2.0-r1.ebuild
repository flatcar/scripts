# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-gsl/ruby-gsl-0.2.0-r1.ebuild,v 1.1 2010/07/04 18:48:35 graaff Exp $

EAPI=2
USE_RUBY="ruby18"

inherit ruby-ng

DESCRIPTION="Ruby wrapper for GNU Scientific Library"
HOMEPAGE="http://ruby-gsl.sourceforge.net"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE=""

DEPEND="${DEPEND} sci-libs/gsl"
RDEPEND="${RDEPEND} sci-libs/gsl"

RUBY_PATCHES=( "${P}-remove-const.patch" )

each_ruby_configure() {
	${RUBY} -Cext extconf.rb || die
}

each_ruby_compile() {
	emake -Cext || die
}

each_ruby_install() {
	DESTDIR="${D}" emake -Cext install || die
}

all_ruby_install() {
	dodoc doc/* || die
	insinto /usr/share/doc/${PF}
	doins -r contrib samples || die
}
