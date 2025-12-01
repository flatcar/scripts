# Copyright 2025 Flatcar Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit libtool autotools bash-completion-r1 linux-mod-r1 systemd toolchain-funcs

DESCRIPTION="Lustre client filesystem modules and utilities"
HOMEPAGE="https://github.com/microsoft/amlFilesystem-lustre"

MY_PN=amlFilesystem-lustre

if [[ ${PV} == 9999* ]]; then
	SRC_URI=""
else
	SRC_URI="https://github.com/microsoft/${MY_PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="amd64 ~amd64"
fi

LICENSE="GPL-2"
SLOT="0"
IUSE=""

RESTRICT="test"

COMMON_DEPEND="
	dev-libs/libnl:3
	dev-libs/libpcre2:=
	dev-libs/libyaml:=
	dev-libs/openssl:=
	sys-apps/keyutils
	sys-apps/util-linux
	sys-fs/e2fsprogs
	sys-libs/libselinux
	sys-libs/ncurses:=
	sys-libs/readline:=
	sys-libs/zlib
"
DEPEND="${COMMON_DEPEND}"
RDEPEND="${COMMON_DEPEND}"
BDEPEND="
	sys-devel/bison
	sys-devel/flex
	virtual/pkgconfig
"

S="${WORKDIR}/${MY_PN}-${PV}"

DOCS=( ChangeLog README )

pkg_setup() {
	linux-mod-r1_pkg_setup

	[[ -n ${KV_DIR} ]] || die "Unable to determine kernel source directory"
	[[ -n ${KV_OUT_DIR} ]] || die "Unable to determine kernel build directory"
}

src_prepare() {
	if [[ "${PV}" == 2.15* ]]; then
		eapply "${FILESDIR}/${PN}-2.15-configure-ac.patch"
	fi
	eapply_user
	eautoreconf
}

src_configure() {
	local myeconfargs=(
		--disable-server
		--enable-client
		--disable-doc
		--disable-manpages
		--disable-tests
		--disable-mpitests
		--disable-efence
		--disable-gss
#		--bindir="${EPREFIX}/usr/bin"
#		--sbindir="${EPREFIX}//sbin"
#		--libdir="${EPREFIX}/usr/$(get_libdir)"
#		--sysconfdir="${EPREFIX}/etc"
#		--with-bash-completion-dir="$(get_bashcompdir)"
		--with-linux="${KV_DIR}"
		--with-linux-obj="${KV_OUT_DIR}"
#		--with-systemdsystemunitdir="$(systemd_get_systemunitdir)"
	)
	set_arch_to_kernel
	econf "${myeconfargs[@]}"
}

src_compile() {
	emake "${MODULES_MAKEARGS[@]}"
}

src_install() {
	emake "${MODULES_MAKEARGS[@]}" DESTDIR="${ED}" install
	if use modules-compress; then
		ko2iblnd=$(find "${ED}"/lib/modules -name "ko2iblnd.ko*")
		test -n "${ko2iblnd}" || die "module ko2iblnd.ko not found"
		# replace symlink with copy of file
		target="$(readlink -f "${ko2iblnd}")"
		rm -f "${ko2iblnd}" || die "remove symlink"
		cp -a "${target}" "${ko2iblnd}" || die "copy module"
	fi
	modules_post_process
	# Drop DKMS helper that is not used on Flatcar
	rm -f "${ED}"/etc/sysconfig/dkms-lustre || die

	einstalldocs
}

pkg_postinst() {
	linux-mod-r1_pkg_postinst
}
