EAPI=8

inherit rpm

DESCRIPTION="Fedora's build of edk2 ARM64 EFI firmware"
HOMEPAGE="https://packages.fedoraproject.org/pkgs/edk2/edk2-aarch64/"
SRC_URI="https://kojipkgs.fedoraproject.org//packages/edk2/20230524/3.fc38/noarch/edk2-aarch64-20230524-3.fc38.noarch.rpm"

LICENSE="BSD-2-Clause-Patent openssl"
SLOT="0"
KEYWORDS="amd64 arm64"

S="${WORKDIR}"

src_install() {
	# Avoid collision with qemu installed config file
	mv usr/share/qemu/firmware/{60,61}-edk2-aarch64.json
	insinto /
	doins -r *
}
