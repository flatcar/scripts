# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-pcap/ruby-pcap-0.6-r1.ebuild,v 1.2 2010/07/11 13:50:29 mr_bones_ Exp $

EAPI=2
USE_RUBY="ruby18"

inherit ruby-ng

IUSE=""

DESCRIPTION="Extension library to use libpcap from Ruby"
HOMEPAGE="http://www.goto.info.waseda.ac.jp/%7efukusima/ruby/pcap-e.html"
SRC_URI="http://www.goto.info.waseda.ac.jp/%7efukusima/ruby/${P}.tar.gz"

SLOT="0"
LICENSE="GPL-2"
KEYWORDS="~amd64 ~x86"

S="${WORKDIR}/pcap"

PATCHES=( "${FILESDIR}/ruby-pcap-0.6-fixnum.patch" )

DEPEND="${DEPEND} net-libs/libpcap"
RDEPEND="${RDEPEND} net-libs/libpcap"

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
	dodoc ChangeLog README README.ja
	dohtml -r doc doc-ja

	insinto /usr/share/doc/${PF}
	doins -r examples
}
