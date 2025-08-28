# Copyright (c) 2013 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="OEM suite for Hyper-V"
HOMEPAGE=""
SRC_URI=""

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

RDEPEND="
  app-emulation/hv-daemons
"

OEM_NAME="Microsoft Hyper-V"

# no source directory
S="${WORKDIR}"
