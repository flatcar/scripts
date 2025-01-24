# Copyright 2022-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Flatcar: inherit from systemd because we need to use systemd_enable_service below
inherit meson systemd

DESCRIPTION="Automated Encryption Framework"
HOMEPAGE="https://github.com/latchset/clevis"
SRC_URI="https://github.com/latchset/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+luks +tpm"

# Flatcar: add dependency for Dracut module
DEPEND="
	dev-libs/jose
	sys-fs/cryptsetup
	sys-kernel/dracut
	luks? (
		dev-libs/libpwquality
		dev-libs/luksmeta
	)
	tpm? ( app-crypt/tpm2-tools )
"
# Flatcar: The Clevis meson build will not build certain features if certain executables are not found at build time, such as `tpm2_createprimary`.
# The meson function `find_program` that checks for the existence of the executables does not seem to search paths under ${ROOT}, but rather 
# under `/`. A fix to make meson find all binaries and include all desired features is to install such runtime dependencies into the SDK.
BDEPEND="
	luks? (
		app-misc/jq
		dev-libs/libpwquality
		dev-libs/luksmeta
	)
	tpm? ( app-crypt/tpm2-tools )
"
RDEPEND="${DEPEND}"

PATCHES=(
	# From https://github.com/latchset/clevis/pull/347
	# Allows using dracut without systemd
	"${FILESDIR}/clevis-dracut.patch"
	# Fix for systemd on Gentoo
	"${FILESDIR}/clevis-meson.patch"
	# Flatcar: 
	# * install `clevis-pin-tang` dracut module in the absence of dracut `network` 
	#   module; Flatcar uses a custom network module
	# * skip copying `/etc/services` into initramfs when installing `clevis` dracut 
	# 	module, which would fail
	"${FILESDIR}/clevis-dracut-flatcar.patch"
)

post_src_install() {
	# Flatcar: the meson build for app-crypt/clevis installs some files to ${D}${ROOT}. After that, Portage
	# copies from ${D} to ${ROOT}, leading to files ending up in, e.g., /build/amd64-usr/build/amd64-usr/.
	# As a workaround, we move everything from ${D}${ROOT} to ${D} after the src_install phase.
 	rsync -av ${D}${ROOT}/ ${D}
 	rm -rfv ${D}${ROOT}

	# Flatcar: enable the systemd unit that triggers Clevis's automatic response to LUKS
	# disk decryption password prompts.
 	systemd_enable_service cryptsetup.target clevis-luks-askpass.path
}
