# Copyright (c) 2013 The CoreOS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/flatcar/nss-altfiles.git"
	inherit git-r3
else
	EGIT_VERSION="fb9a49c9548c5487c7a7c50a9c108c0ebcf12b16"
	SRC_URI="https://github.com/jcpunk/nss-altfiles/archive/${EGIT_VERSION}.tar.gz -> ${PN}-${EGIT_VERSION}.tar.gz"
	S="${WORKDIR}/nss-altfiles-${EGIT_VERSION}"
	KEYWORDS="amd64 arm arm64 x86"
fi

inherit toolchain-funcs

DESCRIPTION="NSS module for data sources under /usr on for Flatcar"
HOMEPAGE="https://github.com/flatcar/nss-altfiles"

LICENSE="LGPL-2.1+"
SLOT="0"

src_configure() {
	tc-export CC
	unset LDFLAGS
	econf \
		--datadir="${EPREFIX}/usr/share/baselayout" \
		--with-module-name=usrfiles \
		--with-types=all
}

src_install() {
	dolib.so libnss_usrfiles.so.2
}
