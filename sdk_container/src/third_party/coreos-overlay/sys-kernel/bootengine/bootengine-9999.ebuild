# Copyright (c) 2013 CoreOS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Early boot initrd (dracut) modules for Flatcar Container Linux"
HOMEPAGE="https://github.com/flatcar/bootengine"

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/flatcar/bootengine.git"
	inherit git-r3
else
	EGIT_VERSION="8854e0fd9fb77bf10eb8484a989d1b76a635264c" # chewi/sysctl-rerun
	SRC_URI="https://github.com/flatcar/bootengine/archive/${EGIT_VERSION}.tar.gz -> ${PN}-${EGIT_VERSION}.tar.gz"
	S="${WORKDIR}/${PN}-${EGIT_VERSION}"
	KEYWORDS="amd64 arm arm64 x86"
fi

LICENSE="BSD"
SLOT="0/${PVR}"

src_install() {
	insinto /usr/lib/dracut/modules.d/
	doins -r dracut/.
	dosbin update-bootengine
	dosbin minimal-init

	# must be executable since dracut's install scripts just
	# re-use existing filesystem permissions during initrd creation.
	chmod +x \
		"${ED}"/usr/lib/dracut/modules.d/51*-generator/*-generator \
		"${ED}"/usr/lib/dracut/modules.d/51diskless-generator/diskless-btrfs \
		"${ED}"/usr/lib/dracut/modules.d/51networkd-dependency-generator/*-generator \
		"${ED}"/usr/lib/dracut/modules.d/50flatcar-network/parse-ip-for-networkd.sh \
		"${ED}"/usr/lib/dracut/modules.d/53disk-uuid/disk-uuid.sh \
		"${ED}"/usr/lib/dracut/modules.d/53ignition/ignition-generator \
		"${ED}"/usr/lib/dracut/modules.d/53ignition/ignition-setup.sh \
		"${ED}"/usr/lib/dracut/modules.d/53ignition/ignition-setup-pre.sh \
		"${ED}"/usr/lib/dracut/modules.d/53ignition/ignition-kargs-helper \
		"${ED}"/usr/lib/dracut/modules.d/53ignition/retry-umount.sh \
		"${ED}"/usr/lib/dracut/modules.d/99setup-root/initrd-setup-root \
		"${ED}"/usr/lib/dracut/modules.d/99setup-root/initrd-setup-root-after-ignition \
		"${ED}"/usr/lib/dracut/modules.d/99setup-root/gpg-agent-wrapper \
		|| die chmod
}
