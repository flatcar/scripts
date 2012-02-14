# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-drivers/xf86-video-vmware/xf86-video-vmware-10.16.9.ebuild,v 1.3 2010/02/08 15:30:19 fauli Exp $

# Must be before x-modular eclass is inherited
#SNAPSHOT="yes"

inherit x-modular

DESCRIPTION="VMware SVGA video driver"
KEYWORDS="amd64 x86 ~x86-fbsd"
IUSE=""

RDEPEND=">=x11-base/xorg-server-1.0.99.901"
DEPEND="${RDEPEND}
	x11-proto/fontsproto
	x11-proto/randrproto
	x11-proto/renderproto
	x11-proto/xextproto
	x11-proto/xineramaproto
	x11-proto/xproto"
