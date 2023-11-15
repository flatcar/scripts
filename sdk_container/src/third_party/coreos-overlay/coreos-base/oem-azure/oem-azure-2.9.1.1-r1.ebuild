# Copyright (c) 2013 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="OEM suite for Azure"
HOMEPAGE="https://azure.microsoft.com/"
SRC_URI=""

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 arm64"
IUSE=""

RDEPEND="
  ~app-emulation/wa-linux-agent-${PV}
"

# for coreos-base/common-oem-files
OEM_NAME="Microsoft Azure"
