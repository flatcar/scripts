# Copyright (c) 2024-2025 The Flatcar Maintainers.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

declare -A ARCHES
ARCHES[amd64]="x64"
ARCHES[arm64]="aa64"

DESCRIPTION="Signed UEFI Shim loader"
HOMEPAGE="https://github.com/rhboot/shim"
S="${WORKDIR}"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 arm64"

for arch in ${KEYWORDS}; do
	SRC_URI+="${arch}? ( https://mirror.release.flatcar-linux.net/coreos/shim${ARCHES[$arch]}-${PVR}.efi.signed ) "
done

src_install() {
	insinto /usr/lib/shim
	newins "${DISTDIR}/shim${ARCHES[$ARCH]}-${PVR}.efi.signed" "shim${ARCHES[$ARCH]}.efi.signed"
}
