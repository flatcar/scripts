# Copyright (c) 2014 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

COREOS_GO_PACKAGE="github.com/flatcar/updateservicectl"
COREOS_GO_GO111MODULE="on"
inherit coreos-go

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/flatcar/updateservicectl.git"
	inherit git-r3
else
	EGIT_VERSION="bfcb21e4c5ef7077231ef1d879c867f1655da09a" # main
	SRC_URI="https://github.com/flatcar/updateservicectl/archive/${EGIT_VERSION}.tar.gz -> ${PN}-${EGIT_VERSION}.tar.gz"
	S="${WORKDIR}/${PN}-${EGIT_VERSION}"
	KEYWORDS="amd64 arm64"
fi

DESCRIPTION="Flatcar Container Linux update service CLI"
HOMEPAGE="https://github.com/flatcar/updateservicectl"

LICENSE="Apache-2.0"
SLOT="0"
