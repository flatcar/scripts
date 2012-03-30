# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-misc/x11vnc/x11vnc-0.9.9.ebuild,v 1.14 2011/11/01 03:56:58 ssuominen Exp $

EAPI="2"

inherit eutils

DESCRIPTION="A VNC server for real X displays"
HOMEPAGE="http://www.karlrunge.com/x11vnc/"
SRC_URI="mirror://sourceforge/libvncserver/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 sh sparc x86 ~x86-fbsd ~x86-interix ~amd64-linux ~x86-linux ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="fbcon +jpeg +zlib threads ssl crypt xinerama avahi system-libvncserver"

RDEPEND="system-libvncserver? ( >=net-libs/libvncserver-0.9.7[threads=,jpeg=,zlib=] )
	!system-libvncserver? (
		zlib? ( sys-libs/zlib )
		jpeg? ( virtual/jpeg:0 )
	)
	ssl? ( dev-libs/openssl )
	avahi? ( >=net-dns/avahi-0.6.4 )
	xinerama? ( x11-libs/libXinerama )
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libX11
	>=x11-libs/libXtst-1.1.0
	x11-libs/libXdamage
	x11-libs/libXext"

DEPEND="${RDEPEND}
	x11-libs/libXt
	xinerama? ( x11-proto/xineramaproto )
	x11-proto/inputproto
	x11-proto/trapproto
	x11-proto/recordproto
	x11-proto/xproto
	x11-proto/xextproto"

pkg_setup() {
	if use avahi && ! use threads
	then
		ewarn "Non-native avahi support has been enabled."
		ewarn "Native avahi support can be enabled by also enabling the threads USE flag."
	fi
}

src_prepare() {
	epatch \
		"${FILESDIR}"/${PN}-0.9.11-rename-pointer.patch \
		"${FILESDIR}"/${PN}-0.9.12-warnings.patch
}

src_configure() {
	# --without-v4l because of missing video4linux 2.x support wrt #389079
	econf \
		$(use_with system-libvncserver) \
		$(use_with avahi) \
		$(use_with xinerama) \
		$(use_with ssl) \
		$(use_with ssl crypto) \
		$(use_with crypt) \
		--without-v4l \
		$(use_with jpeg) \
		$(use_with zlib) \
		$(use_with threads pthread) \
		$(use_with fbcon fbdev)
}

src_install() {
	emake DESTDIR="${D}" install || die "make install failed"
	dodoc x11vnc/{ChangeLog,README}
}
