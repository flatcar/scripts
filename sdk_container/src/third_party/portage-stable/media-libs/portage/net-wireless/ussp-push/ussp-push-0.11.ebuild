# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/ussp-push/ussp-push-0.11.ebuild,v 1.4 2011/12/18 20:01:31 phajdan.jr Exp $

EAPI="2"

DESCRIPTION="OBEX object push client for Linux"
HOMEPAGE="http://www.xmailserver.org/ussp-push.html"
SRC_URI="http://www.xmailserver.org/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~ppc x86"
IUSE=""

DEPEND="net-wireless/bluez
		dev-libs/openobex"

RDEPEND="${DEPEND}"

src_configure(){
	# patch for bluez 4.x
	sed 's:hci_remote_name:hci_read_remote_name:g' -i src/obex_socket.c || \
		die "sed failed"

	econf || die "configure failed"
}

src_install() {
	emake DESTDIR="${D}" install || die 'emake install failed'
	dodoc AUTHORS README
}

pkg_postinst() {
	einfo
	einfo "You can use ussp-push in three ways:"
	einfo "1. rfcomm bind /dev/rcomm0 00:11:22:33:44:55 10"
	einfo "   ussp-push /dev/rfcomm0 localfile remotefile"
	einfo "2. ussp-push 00:11:22:33:44:55@10 localfile remotefile"
	einfo "3. ussp-push 00:11:22:33:44:55@ localfile remotefile"
	einfo
	einfo "See the README in /usr/share/doc/${PF}/ for more details."
	einfo
}
