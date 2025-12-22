# Copyright (c) 2013 The CoreOS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/flatcar/nss-altfiles.git"
	inherit git-r3
else
	EGIT_VERSION="c8e05a08a2e28eb48c6c788e3007d94f8d8de5cd" # main
	SRC_URI="https://github.com/flatcar/nss-altfiles/archive/${EGIT_VERSION}.tar.gz -> ${PN}-${EGIT_VERSION}.tar.gz"
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
	econf \
		--datadir="${EPREFIX}/usr/share/baselayout" \
		--with-module-name=usrfiles \
		--with-types=all
}

src_install() {
	dolib.so libnss_usrfiles.so.2
}
