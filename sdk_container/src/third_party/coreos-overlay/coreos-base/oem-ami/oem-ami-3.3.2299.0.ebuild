# Copyright (c) 2013 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd

DESCRIPTION="OEM suite for Amazon Machine Images"
HOMEPAGE="http://aws.amazon.com/ec2/"
SRC_URI=""

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 arm64"
IUSE=""

RDEPEND="
  ~app-emulation/amazon-ssm-agent-${PV}
  coreos-base/flatcar-eks
"

# for coreos-base/common-oem-files
OEM_NAME="Amazon EC2"

S="${WORKDIR}"

src_install() {
	systemd_dounit "${FILESDIR}/setup-oem.service"

	insinto "$(systemd_get_systemunitdir)/multi-user.target.d"
	doins "${FILESDIR}/10-oem-ami.conf"

	systemd_enable_service multi-user.target ntpd.service
}
