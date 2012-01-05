# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/bluez-hcidump/bluez-hcidump-2.1.ebuild,v 1.1 2011/11/04 20:43:01 ssuominen Exp $

EAPI=4

DESCRIPTION="Bluetooth HCI packet analyzer"
HOMEPAGE="http://www.bluez.org/"
SRC_URI="mirror://debian/pool/main/b/${PN}/${PN}_${PV}.orig.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~hppa ~ppc ~x86"
IUSE=""

RDEPEND=">=net-wireless/bluez-4.96"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

DOCS=( AUTHORS ChangeLog README )
