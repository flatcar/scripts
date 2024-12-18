# Copyright (c) 2013 CoreOS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
EGIT_REPO_URI="https://github.com/flatcar/bootengine.git"

if [[ "${PV}" == 9999 ]]; then
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
else
	EGIT_COMMIT="229e279c1e1e480ccbfb33f254c23068941b1518" # flatcar-master
	KEYWORDS="amd64 arm arm64 x86"
fi

inherit git-r3

DESCRIPTION="CoreOS Bootengine"
SRC_URI=""

LICENSE="BSD"
SLOT="0/${PVR}"

src_install() {
	insinto /usr/lib/dracut/modules.d/
	doins -r dracut/.
	dosbin update-bootengine

	# must be executable since dracut's install scripts just
	# re-use existing filesystem permissions during initrd creation.
	chmod +x "${D}"/usr/lib/dracut/modules.d/10*-generator/*-generator \
		"${D}"/usr/lib/dracut/modules.d/10diskless-generator/diskless-btrfs \
		"${D}"/usr/lib/dracut/modules.d/10networkd-dependency-generator/*-generator \
		"${D}"/usr/lib/dracut/modules.d/03flatcar-network/parse-ip-for-networkd.sh \
		"${D}"/usr/lib/dracut/modules.d/30disk-uuid/disk-uuid.sh \
		"${D}"/usr/lib/dracut/modules.d/30ignition/ignition-generator \
		"${D}"/usr/lib/dracut/modules.d/30ignition/ignition-setup.sh \
		"${D}"/usr/lib/dracut/modules.d/30ignition/ignition-setup-pre.sh \
		"${D}"/usr/lib/dracut/modules.d/30ignition/ignition-kargs-helper \
		"${D}"/usr/lib/dracut/modules.d/30ignition/retry-umount.sh \
		"${D}"/usr/lib/dracut/modules.d/99setup-root/initrd-setup-root \
		"${D}"/usr/lib/dracut/modules.d/99setup-root/initrd-setup-root-after-ignition \
		"${D}"/usr/lib/dracut/modules.d/99setup-root/gpg-agent-wrapper \
		|| die chmod
}
