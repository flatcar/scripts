# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/libseccomp/libseccomp-2.2.0.ebuild,v 1.1 2015/04/09 17:59:44 vapier Exp $

# TODO: Add python support.

EAPI="5"

inherit eutils multilib-minimal

DESCRIPTION="high level interface to Linux seccomp filter"
HOMEPAGE="https://github.com/seccomp/libseccomp"
SRC_URI="https://github.com/seccomp/libseccomp/releases/download/v${PV}/${P}.tar.gz"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm ~arm64 ~mips ~x86"
IUSE="static-libs"

src_prepare() {
	sed -i \
		-e '/_LDFLAGS/s:-static::' \
		tools/Makefile.in || die
}

multilib_src_configure() {
	ECONF_SOURCE=${S} \
	econf \
		$(use_enable static-libs static) \
		--disable-python
}

multilib_src_install_all() {
	find "${ED}" -name libseccomp.la -delete
}
