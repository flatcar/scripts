# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/tclink/tclink-3.4.4-r1.ebuild,v 1.1 2010/07/11 19:55:16 graaff Exp $

EAPI=2
USE_RUBY="ruby18"

inherit ruby-ng

MY_P=${P}-ruby

DESCRIPTION="Make-like scripting in Ruby"
HOMEPAGE="http://www.trustcommerce.com/tclink.html"
SRC_URI="http://www.trustcommerce.com/downloads/${MY_P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

# Tests use a live server.
RESTRICT="test"

S=${WORKDIR}/${MY_P}

RDEPEND="${RDEPEND}	>=dev-libs/openssl-0.9.8"
DEPEND="${DEPEND} >=dev-libs/openssl-0.9.8"

each_ruby_prepare() {
	echo \#define TCLINK_VERSION \"${PV}-Ruby-`uname -sm | tr ' ' -`\" > config.h
}

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
	dodoc README || die
	dohtml doc/TCDevGuide.html || die
}
