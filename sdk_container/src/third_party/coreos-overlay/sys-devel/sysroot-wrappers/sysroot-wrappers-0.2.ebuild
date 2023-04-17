# Copyright (c) 2013 CoreOS Inc. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools

DESCRIPTION="Build tool wrappers for using custom SYSROOTs"
HOMEPAGE="https://github.com/flatcar/sysroot-wrappers"
SRC_URI="https://github.com/flatcar/${PN}/releases/download/v${PV}/${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 arm64"
IUSE=""
