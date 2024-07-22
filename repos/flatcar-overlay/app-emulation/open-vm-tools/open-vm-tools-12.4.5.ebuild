# Copyright 2007-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools linux-info pam systemd udev

DESCRIPTION="Tools for VMware guests"
HOMEPAGE="https://github.com/vmware/open-vm-tools"
MY_P="${P}-23787635"
SRC_URI="https://github.com/vmware/open-vm-tools/releases/download/stable-${PV}/${MY_P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 x86"
# Flatcar: TO UPSTREAM: added fuse3 USE flag
IUSE="X +deploypkg +dnet doc +fuse fuse3 gtkmm +icu multimon pam +resolutionkms +ssl +vgauth"
# Flatcar: TO UPSTREAM: made fuse and fuse3 exclusive
REQUIRED_USE="
	multimon? ( X )
	vgauth? ( ssl )
	?? ( fuse fuse3 )
"

# Flatcar: TO UPSTREAM: added optional dep on sys-fs/fuse:3
RDEPEND="
	dev-libs/glib
	net-libs/libtirpc
	deploypkg? ( dev-libs/libmspack )
	fuse? ( sys-fs/fuse:0 )
	fuse3? ( sys-fs/fuse:3 )
	pam? ( sys-libs/pam )
	!pam? ( virtual/libcrypt:= )
	ssl? ( dev-libs/openssl:0= )
	vgauth? (
		dev-libs/libxml2
		dev-libs/xmlsec:=
	)
	X? (
		x11-libs/libXext
		multimon? ( x11-libs/libXinerama )
		x11-libs/libXi
		x11-libs/libXrender
		x11-libs/libXrandr
		x11-libs/libXtst
		x11-libs/libSM
		x11-libs/libXcomposite
		x11-libs/gdk-pixbuf-xlib
		x11-libs/gtk+:3
		gtkmm? (
			dev-cpp/gtkmm:3.0
			dev-libs/libsigc++:2
		)
	)
	dnet? ( dev-libs/libdnet )
	icu? ( dev-libs/icu:= )
	resolutionkms? (
		x11-libs/libdrm[video_cards_vmware]
		virtual/libudev
	)
"

DEPEND="${RDEPEND}
	net-libs/rpcsvc-proto
"

BDEPEND="
	dev-util/glib-utils
	virtual/pkgconfig
	doc? ( app-doc/doxygen )
"

S="${WORKDIR}/${MY_P}"

PATCHES=(
	"${FILESDIR}/10.1.0-Werror.patch"
	"${FILESDIR}/11.3.5-icu.patch"
)

pkg_setup() {
	local CONFIG_CHECK="~VMWARE_BALLOON ~VMWARE_PVSCSI ~VMXNET3"
	use X && CONFIG_CHECK+=" ~DRM_VMWGFX"
	kernel_is -lt 3 9 || CONFIG_CHECK+=" ~VMWARE_VMCI ~VMWARE_VMCI_VSOCKETS"
	kernel_is -lt 3 || CONFIG_CHECK+=" ~FUSE_FS"
	kernel_is -lt 5 5 || CONFIG_CHECK+=" ~X86_IOPL_IOPERM"
	linux-info_pkg_setup
}

src_prepare() {
	eapply -p2 "${PATCHES[@]}"
	eapply_user
	eautoreconf
}

src_configure() {
	local myeconfargs=(
		--disable-glibc-check
		--without-root-privileges
		$(use_enable multimon)
		$(use_with X x)
		$(use_with X gtk3)
		$(use_with gtkmm gtkmm3)
		$(use_enable doc docs)
		--disable-tests
		$(use_enable resolutionkms)
		--disable-static
		$(use_enable deploypkg)
		$(use_with pam)
		$(use_enable vgauth)
		$(use_with dnet)
		$(use_with icu)
		--with-udev-rules-dir="$(get_udevdir)/rules.d"
		# Flatcar: TO UPSTREAM: explicitly specify fuse version
		$(use_with fuse fuse 2)
		$(use_with fuse3 fuse 3)
		# Flatcar: TO UPSTREAM: Disable it explicitly, we do
		# not yet list the containerinfo dependencies in the
		# ebuild
		--disable-containerinfo
		# Flatcar: TO UPSTREAM: Disable it explicitly, gtk2 is
		# obsolete
		--without-gtk2
		# Flatcar: TO UPSTREAM: Possibly add a separate USE
		# flag for the utility, or merge it into resolutionkms
		--disable-vmwgfxctrl
	)
	# Avoid a bug in configure.ac
	use ssl || myeconfargs+=( --without-ssl )

	econf "${myeconfargs[@]}"
}

src_install() {
	default
	find "${ED}" -name '*.la' -delete || die

	if use pam; then
		rm "${ED}"/etc/pam.d/vmtoolsd || die
		pamd_mimic_system vmtoolsd auth account
	fi

	newinitd "${FILESDIR}/open-vm-tools.initd" vmware-tools
	newconfd "${FILESDIR}/open-vm-tools.confd" vmware-tools

	if use vgauth; then
		systemd_newunit "${FILESDIR}"/vmtoolsd.vgauth.service vmtoolsd.service
		systemd_dounit "${FILESDIR}"/vgauthd.service
	else
		systemd_dounit "${FILESDIR}"/vmtoolsd.service
	fi

	# Flatcar: TO UPSTREAM: vmhgfs-fuse is built only when fuse or fuse3 are enabled
	if use fuse || use fuse3; then
		# Make fstype = vmhgfs-fuse work in fstab
		dosym vmhgfs-fuse /usr/bin/mount.vmhgfs-fuse
	fi

	if use X; then
		fperms 4711 /usr/bin/vmware-user-suid-wrapper
		dobin scripts/common/vmware-xdg-detect-de
	fi
}

pkg_postinst() {
	udev_reload
}

pkg_postrm() {
	udev_reload
}
