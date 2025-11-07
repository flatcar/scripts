# Copyright 2025 The Flatcar Container Linux Maintainers
# Distributed under the terms of the Apache License 2.0

EAPI=8

inherit cmake git-r3 systemd tmpfiles

DESCRIPTION="Novel layering block-level image format for containers"
HOMEPAGE="https://containerd.github.io/overlaybd"
EGIT_REPO_URI="https://github.com/containerd/overlaybd.git"

if [[ ${PV} == 9999* ]]; then
	KEYWORDS="~amd64 ~arm64"
else
	EGIT_COMMIT="v${PV}"
	KEYWORDS="amd64 arm64"
fi

LICENSE="Apache-2.0"
SLOT="0"
IUSE="cpu_flags_x86_avx2 dsa qat isal"
REQUIRED_USE="dsa? ( cpu_flags_x86_avx2 )"
RESTRICT="test"

# FIXME HACK ALERT: overlaybd build pulls sources during src_configure.
# (https://github.com/alibaba/PhotonLibOS.git/
# This fails if network sandbox is enabled.
RESTRICT="${RESTRICT} network-sandbox"

DEPEND="
	app-arch/zstd:=
	dev-libs/libaio
	dev-libs/libnl:3
	dev-libs/openssl:=
	net-misc/curl
	sys-fs/e2fsprogs
	sys-libs/zlib
	dsa? ( sys-apps/pciutils )
	qat? ( sys-apps/pciutils )
"

RDEPEND="
	${DEPEND}
"

PATCHES=(
	"${FILESDIR}"/0001-Patch-Photon-after-fetching-to-fix-cross-issues.patch
	"${FILESDIR}"/0002-Patch-yaml-cpp-after-fetching-to-fix-cmake-issues.patch
)

src_prepare() {
	cmake_src_prepare
	sed -i "s:@FILESDIR@:${FILESDIR}:g" CMakeLists.txt CMake/Findphoton.cmake || die
}

src_configure() {
	# crc32c.cpp explicitly uses special instructions but checks for them at
	# runtime. Only DSA hard requires at least AVX2. However, the code doesn't
	# try especially hard to avoid these instructions from being implicitly used
	# outside these runtime checks. :(
	# ISAL similarly leads to "illegal instruction" termination on QEMU.
	local mycmakeargs=(
		-DBUILD_SHARED_LIBS=no
		-DBUILD_TESTING=no
		-DENABLE_DSA=$(usex dsa)
		-DENABLE_ISAL=$(usex isal)
		-DENABLE_QAT=$(usex qat)
		-DORIGIN_EXT2FS=yes
	)

	# Make erofs-utils configure work when cross-compiling.
	host_alias="${CHOST}" build_alias="${CBUILD:-${CHOST}}" \
	cmake_src_configure
}

src_install() {
	cmake_src_install

	# We want to ship our binaries in /usr/local (so we're sysext compatible)
	# but upstream has hard-wired everything to /opt/overlaybd.

	sed "s,/opt/${PN},/usr/local/${PN},g" \
		"${ED}"/opt/${PN}/${PN}-tcmu.service |
		systemd_newunit - ${PN}-tcmu.service
	rm "${ED}"/opt/${PN}/${PN}-tcmu.service || die
	systemd_enable_service multi-user.target ${PN}-tcmu.service

	dodir /usr/local/${PN}/etc
	mv "${ED}"/opt/${PN}/* "${ED}"/usr/local/${PN}/ || die
	mv "${ED}"/etc/${PN}/* "${ED}"/usr/local/${PN}/etc/ || die

	# Handle /etc (overlaybd.json), create /opt/overlaybd and symlink
	# all contents of /usr/local/overlaybd to /opt/overlaybd.
	elog "Scanning '${ED}/usr/local/${PN}/' and generating tmpfiles symlink entries..."
	cat "${FILESDIR}"/10-${PN}.conf <(
		for entry in "${ED}"/usr/local/${PN}/*; do
			echo "L /opt/overlaybd/${entry##*/} - - - - /usr/local/${PN}/${entry##*/}"
		done
	) | tee /dev/stderr | newtmpfiles - 10-${PN}.conf
}
