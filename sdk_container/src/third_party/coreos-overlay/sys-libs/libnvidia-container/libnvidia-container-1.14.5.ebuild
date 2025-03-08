# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit coreos-go-depend toolchain-funcs

DESCRIPTION="NVIDIA container runtime library"
HOMEPAGE="https://github.com/NVIDIA/libnvidia-container"

NVIDIA_MODPROBE_VERSION=495.44
TIRPC_VERSION=1.3.2
SRC_URI="
	https://github.com/NVIDIA/${PN}/archive/v${PV/_rc/-rc.}.tar.gz -> ${P}.tar.gz
	https://github.com/NVIDIA/nvidia-modprobe/archive/${NVIDIA_MODPROBE_VERSION}.tar.gz -> nvidia-modprobe-${NVIDIA_MODPROBE_VERSION}.tar.gz
	https://downloads.sourceforge.net/project/libtirpc/libtirpc/${TIRPC_VERSION}/libtirpc-${TIRPC_VERSION}.tar.bz2
"
S="${WORKDIR}/${PN}-${PV/_rc/-rc.}"
KEYWORDS="~amd64"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 arm64"

DEPEND="
	sys-libs/libcap
	sys-libs/libseccomp
	virtual/libelf
"
RDEPEND="${DEPEND}"
BDEPEND="
	net-libs/rpcsvc-proto
	virtual/pkgconfig
"


src_prepare() {
	# sanity check:
	grep -q "${NVIDIA_MODPROBE_VERSION}" mk/nvidia-modprobe.mk || die
	mkdir -p "${S}/deps/src/" || die
	local nvmoddir="nvidia-modprobe-${NVIDIA_MODPROBE_VERSION}"
	ln -s "${WORKDIR}/${nvmoddir}" "${S}/deps/src/" || die
	patch -d "${S}/deps/src/${nvmoddir}" -p1 <"${S}/mk/nvidia-modprobe.patch" || die
	touch "${S}/deps/src/${nvmoddir}/.download_stamp" || die

	grep -q "${TIRPC_VERSION}" mk/libtirpc.mk || die
	local tirpcdir="libtirpc-${TIRPC_VERSION}"
	ln -s "${WORKDIR}/${tirpcdir}" "${S}/deps/src/" || die
	touch "${S}/deps/src/${tirpcdir}/.download_stamp" || die

	default
}

src_compile() {
	go_export
	tc-export CC OBJCOPY LD AR STRIP PKG_CONFIG
	MAKE_ARGS=(
		LIB_VERSION="${PV/v/}"
		prefix="${EPREFIX}/usr"
		libdir="${EPREFIX}/usr/$(get_libdir)"
		REVISION="${PV}"
		WITH_LIBELF=yes
		WITH_SECCOMP=yes
		WITH_TIRPC=yes
		CURL=die
		OBJCPY="${OBJCOPY}"
		LDCONFIG=${ROOT}/usr/sbin/ldconfig
	)
	emake "${MAKE_ARGS[@]}" || die "emake failed"
}

src_install() {
	emake DESTDIR="${ED}" "${MAKE_ARGS[@]}" install || die "emake install failed"
}
