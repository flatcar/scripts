# Copyright 2025 The Flatcar Container Linux Maintainers
# Distributed under the terms of the Apache License 2.0

EAPI=8

inherit cmake systemd tmpfiles

DESCRIPTION="Novel layering block-level image format for containers"
HOMEPAGE="https://containerd.github.io/overlaybd"

if [[ ${PV} == 9999* ]]; then
	EGIT_REPO_URI="https://github.com/containerd/overlaybd.git"
	inherit git-r3
	RESTRICT="network-sandbox"
else
	EROFS_UTILS_COMMIT="eec6f7a2755dfccc8f655aa37cf6f26db9164e60"
	PHOTON_COMMIT="v0.6.17"
	TCMU_COMMIT="813fd65361bb2f348726b9c41478a44211847614"
	OCF_COMMIT="c2dd2259e47c2e5e72dc77f99d0150a5d05496d7"
	SRC_URI="https://github.com/containerd/overlaybd/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
		https://git.kernel.org/pub/scm/linux/kernel/git/xiang/erofs-utils.git/snapshot/erofs-utils-${EROFS_UTILS_COMMIT}.tar.gz
		https://github.com/alibaba/PhotonLibOS/archive/${PHOTON_COMMIT}.tar.gz -> PhotonLibOS-${PHOTON_COMMIT}.tar.gz
		https://github.com/data-accelerator/photon-libtcmu/archive/${TCMU_COMMIT}.tar.gz -> photon-libtcmu-${TCMU_COMMIT}.tar.gz
		https://github.com/Open-CAS/ocf/archive/${OCF_COMMIT}.tar.gz -> ocf-${OCF_COMMIT}.tar.gz"
	KEYWORDS="amd64 arm64"
fi

LICENSE="Apache-2.0"
SLOT="0"
IUSE="cpu_flags_x86_avx2 cpu_flags_x86_avx512f dsa isal qat test"
REQUIRED_USE="
	dsa? ( cpu_flags_x86_avx2 )
	isal? ( cpu_flags_x86_avx512f )
"
RESTRICT+=" test" # Mostly fails with operation not supported?
PROPERTIES="test_network"

RDEPEND="
	app-arch/zstd:=
	dev-libs/libaio
	dev-libs/libnl:3
	dev-libs/openssl:=
	net-misc/curl
	sys-fs/e2fsprogs
	virtual/zlib:=
	dsa? ( sys-apps/pciutils )
	qat? ( sys-apps/pciutils )
"
DEPEND="
	${RDEPEND}
	dev-libs/rapidjson
	test? (
		dev-cpp/gflags
		dev-cpp/gtest
	)
"
BDEPEND="
	virtual/pkgconfig
"

PATCHES=(
	"${FILESDIR}"/0001-Patch-Photon-after-fetching-to-fix-cross-issues.patch
	"${FILESDIR}"/0002-overlaybd-offline-build.patch
	"${FILESDIR}"/0003-Fix-build-with-gcc15.patch
)

src_prepare() {
	cmake_src_prepare
	sed -i "s:@FILESDIR@:${FILESDIR}:g" CMake/Findphoton.cmake || die

	if [[ ${PV} != 9999* ]]; then
		rmdir src/overlaybd/cache/ocf_cache/ocf || die
		ln -sr "${WORKDIR}/ocf-${OCF_COMMIT#v}" src/overlaybd/cache/ocf_cache/ocf || die

		mkdir -p "${BUILD_DIR}"/_deps || die
		cd "${BUILD_DIR}"/_deps || die

		ln -sr "${WORKDIR}/erofs-utils-${EROFS_UTILS_COMMIT}" erofs-utils-src || die
		ln -sr "${WORKDIR}/PhotonLibOS-${PHOTON_COMMIT#v}" photon-src || die
		ln -sr "${WORKDIR}/photon-libtcmu-${TCMU_COMMIT#v}" tcmu-src || die

		cd photon-src || die
		eapply "${FILESDIR}"/photon-cross.patch
	fi
}

src_configure() {
	# crc32c.cpp explicitly uses special instructions but checks for them at
	# runtime. However, the code doesn't try especially hard to avoid these
	# instructions from being implicitly used outside these runtime checks. :(
	local mycmakeargs=(
		-DBUILD_SHARED_LIBS=no
		-DBUILD_STREAM_CONVERTOR=no
		-DBUILD_TESTING=$(usex test)
		-DENABLE_DSA=$(usex dsa)
		-DENABLE_ISAL=$(usex isal)
		-DENABLE_QAT=$(usex qat)
		-DORIGIN_EXT2FS=yes
	)

	# Ensure we're building offline.
	[[ ${PV} == 9999* ]] || mycmakeargs+=( -DFETCHCONTENT_FULLY_DISCONNECTED=yes )

	# Make erofs-utils configure work when cross-compiling.
	# Set dummy gflags/gtest dirs because they are in standard dirs anyway.
	host_alias="${CHOST}" build_alias="${CBUILD:-${CHOST}}" \
	GFLAGS=/no/where GTEST=/no/where \
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
