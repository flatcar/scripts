# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/win32codecs/win32codecs-20071007-r4.ebuild,v 1.5 2012/05/29 15:45:01 aballier Exp $

inherit multilib

DESCRIPTION="Windows 32-bit binary codecs for video and audio playback support"
SRC_URI="mirror://mplayer/releases/codecs/all-${PV}.tar.bz2"
HOMEPAGE="http://www.mplayerhq.hu/"
LICENSE="as-is"
SLOT="0"
KEYWORDS="-* ~amd64 x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~x86-linux"
IUSE="real"

RDEPEND="real? ( =virtual/libstdc++-3.3* )"

S="${WORKDIR}/all-${PV}"

RESTRICT="strip binchecks"

pkg_setup() {
	# This is a binary x86 package => ABI=x86
	# Please keep this in future versions
	# Daniel Gryniewicz <dang@gentoo.org>
	has_multilib_profile && ABI="x86"
}

src_install() {
	use prefix || EPREFIX=

	insinto /usr/$(get_libdir)/win32
	doins *.dll *.ax *.xa *.acm *.vwp *.drv *.DLL || die "Failed to install win32 codecs"

	if use real
	then
		insinto /usr/$(get_libdir)/real
		doins *so.6.0 || die "Failed to install realplayer codecs"

		# copy newly introduced codecs from realplayer10
		# see the ChangeLog online
		doins *.so || die "Failed to install realplayer10 codecs"

		# fix bug #80321
		local x
		for x in *so.6.0 *.so; do
			dosym ../real/$x /usr/$(get_libdir)/win32 || die "Failed to make symlink to $x"
		done
	fi

	dodoc README

	cat > "${T}/50${PN}" <<EOF
SEARCH_DIRS_MASK="${EPREFIX}/usr/$(get_libdir)/real ${EPREFIX}/usr/$(get_libdir)/win32"
EOF
	insinto /etc/revdep-rebuild
	doins "${T}/50${PN}"
}
