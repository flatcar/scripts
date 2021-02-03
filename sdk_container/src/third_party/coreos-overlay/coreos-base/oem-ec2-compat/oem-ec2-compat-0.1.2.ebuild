# Copyright (c) 2013 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=5

DESCRIPTION="OEM suite for EC2 compatible images"
HOMEPAGE=""
SRC_URI=""

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 arm64 x86"
IUSE="ec2 openstack brightbox aws_pro"
REQUIRED_USE="^^ ( ec2 openstack brightbox aws_pro )"

# TODO: The AWS SSM Agent is currently too big for the OEM partition
# but if it fits, uncomment the following and revert
# b6abb59c544be13e923a3e7240b5c9395c281fca
#RDEPEND="
#       ec2? ( app-emulation/amazon-ssm-agent )
#"
RDEPEND="
       aws_pro? ( coreos-base/flatcar-eks )
"

# no source directory
S="${WORKDIR}"

src_prepare() {
	if use ec2 || use aws_pro ; then
		ID="ami"
		if use ec2; then
			NAME="Amazon EC2"
		else
			NAME="Amazon EC2 (Pro)"
		fi
		HOME_URL="http://aws.amazon.com/ec2/"
	elif use openstack ; then
		ID="openstack"
		NAME="Openstack"
		HOME_URL="https://www.openstack.org/"
	elif use brightbox ; then
		ID="brightbox"
		NAME="Brightbox"
		HOME_URL="http://brightbox.com/"
	else
		die "Unknown OEM!"
	fi

	sed -e "s\\@@OEM_ID@@\\${ID}\\g" \
	    -e "s\\@@OEM_NAME@@\\${NAME}\\g" \
	    -e "s\\@@OEM_VERSION_ID@@\\${PVR}\\g" \
	    -e "s\\@@OEM_HOME_URL@@\\${HOME_URL}\\g" \
	    "${FILESDIR}/oem-release" > "${T}/oem-release" || die
}

src_install() {
	insinto "/usr/share/oem"
	doins "${T}/oem-release"
	if use ec2 || use aws_pro ; then
		newins "${FILESDIR}/grub-ec2.cfg" grub.cfg
	elif use openstack ; then
		newins "${FILESDIR}/grub-openstack.cfg" grub.cfg
	elif use brightbox ; then
		newins "${FILESDIR}/grub-brightbox.cfg" grub.cfg
	fi

	insinto "/usr/share/oem/base"
	doins "${FILESDIR}/base/README"
	doins "${FILESDIR}/base/default.ign"
	if use ec2 ; then
		newins "${FILESDIR}/base/base-ec2.ign" base.ign
	elif use aws_pro ; then
		newins "${FILESDIR}/base/base-aws-pro.ign" base.ign
	fi
}
