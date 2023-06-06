# Copyright 2013 The CoreOS Authors
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=7

DESCRIPTION="Meta ebuild for building all binary packages."
HOMEPAGE="http://coreos.com/docs/sdk/"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm64"
IUSE=""

# Depend on everything OEMs need, but not the OEMs themselves.
# This makes the built packages available for image_vm_util.sh but
# avoids copying the oem specific files (e.g. grub configs) before
# the oem partition is set up.
DEPEND=""
RDEPEND="
	amd64? (
		app-emulation/open-vm-tools
		coreos-base/coreos-oem-gce
		coreos-base/nova-agent-container
		coreos-base/nova-agent-watcher
	)
	arm64? (
		sys-boot/grub
		sys-firmware/edk2-ovmf-bin
	)
	app-emulation/amazon-ssm-agent
	app-emulation/wa-linux-agent
	coreos-base/coreos
	coreos-base/coreos-dev
	coreos-base/flatcar-eks
	x11-drivers/nvidia-drivers
	"
