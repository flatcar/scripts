# Copyright (c) 2013 CoreOS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Early boot initrd (dracut) modules for Flatcar Container Linux"
HOMEPAGE="https://github.com/flatcar/bootengine"

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/flatcar/bootengine.git"
	inherit git-r3
else
	EGIT_VERSION="003a67d93a99705391a0a1fa825f018b074d8e8b" # flatcar-master
	SRC_URI="https://github.com/flatcar/bootengine/archive/${EGIT_VERSION}.tar.gz -> ${PN}-${EGIT_VERSION}.tar.gz"
	S="${WORKDIR}/${PN}-${EGIT_VERSION}"
	KEYWORDS="amd64 arm arm64 x86"
fi

LICENSE="BSD"
SLOT="0/${PVR}"

src_install() {
	dosbin update-bootengine
	dosbin minimal-init

	insinto /usr/lib/dracut/modules.d
	doins -r dracut/.

	# must be executable since dracut's install scripts just
	# re-use existing filesystem permissions during initrd creation.
	cd "${ED}"/usr/lib/dracut/modules.d || die
	find "${S}"/dracut -type f -executable -printf "%P\0" | xargs -0 chmod +x || die
}
