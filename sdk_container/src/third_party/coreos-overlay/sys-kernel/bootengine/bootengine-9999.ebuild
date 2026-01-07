# Copyright (c) 2013 CoreOS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
EGIT_REPO_URI="https://github.com/flatcar/bootengine.git"

if [[ "${PV}" == 9999 ]]; then
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
else
	EGIT_COMMIT="7d9895ce55617b18a78294975197975ac17b5bc3" # flatcar-master
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
	dosbin minimal-init

	# must be executable since dracut's install scripts just
	# re-use existing filesystem permissions during initrd creation.
	chmod +x "${D}"/usr/lib/dracut/modules.d/51*-generator/*-generator \
		"${D}"/usr/lib/dracut/modules.d/51diskless-generator/diskless-btrfs \
		"${D}"/usr/lib/dracut/modules.d/51networkd-dependency-generator/*-generator \
		"${D}"/usr/lib/dracut/modules.d/50flatcar-network/parse-ip-for-networkd.sh \
		"${D}"/usr/lib/dracut/modules.d/53disk-uuid/disk-uuid.sh \
		"${D}"/usr/lib/dracut/modules.d/53ignition/ignition-generator \
		"${D}"/usr/lib/dracut/modules.d/53ignition/ignition-setup.sh \
		"${D}"/usr/lib/dracut/modules.d/53ignition/ignition-setup-pre.sh \
		"${D}"/usr/lib/dracut/modules.d/53ignition/ignition-kargs-helper \
		"${D}"/usr/lib/dracut/modules.d/53ignition/retry-umount.sh \
		"${D}"/usr/lib/dracut/modules.d/99setup-root/initrd-setup-root \
		"${D}"/usr/lib/dracut/modules.d/99setup-root/initrd-setup-root-after-ignition \
		"${D}"/usr/lib/dracut/modules.d/99setup-root/gpg-agent-wrapper \
		|| die chmod
}
