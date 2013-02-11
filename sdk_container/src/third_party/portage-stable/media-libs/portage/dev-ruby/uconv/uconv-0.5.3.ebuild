# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/uconv/uconv-0.5.3.ebuild,v 1.6 2012/05/01 18:24:03 armin76 Exp $

EAPI="2"
USE_RUBY="ruby18"

inherit ruby-ng

DESCRIPTION="A module to convert ISO/IEC 10646 (Unicode) string and Japanese strings"
HOMEPAGE="http://www.yoshidam.net/Ruby.html#uconv"
SRC_URI="http://www.yoshidam.net/${P}.tar.gz"
LICENSE="Ruby"
SLOT="0"
KEYWORDS="~amd64 ppc ppc64 x86"
IUSE=""
S=${WORKDIR}/${PN}

all_ruby_prepare() {
	sed -i -e '/^\$CFLAGS = ""/d' extconf.rb || die "Unable to remove CFLAGS line"
}

each_ruby_configure() {
	ruby extconf.rb || die
}

each_ruby_compile() {
	emake || die
}

each_ruby_install() {
	emake DESTDIR="${D}" install || die
}

all_ruby_install() {
	dodoc README*
}
