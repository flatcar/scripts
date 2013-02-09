# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/webrtc-audio-processing/webrtc-audio-processing-0.1.ebuild,v 1.5 2012/11/21 10:15:02 ago Exp $

EAPI=4
inherit eutils

DESCRIPTION="AudioProcessing library from the webrtc.org code base"
HOMEPAGE="http://www.freedesktop.org/software/pulseaudio/webrtc-audio-processing/"
SRC_URI="http://freedesktop.org/software/pulseaudio/${PN}/${P}.tar.xz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 x86 ~amd64-linux"
IUSE="static-libs"

DOCS="AUTHORS NEWS README"

src_configure() {
	econf $(use_enable static-libs static)
}

src_install() {
	default
	prune_libtool_files
}
