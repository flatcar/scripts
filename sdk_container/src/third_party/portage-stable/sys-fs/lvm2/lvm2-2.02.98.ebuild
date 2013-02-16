# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/lvm2/lvm2-2.02.98.ebuild,v 1.3 2013/01/18 03:39:06 ssuominen Exp $

EAPI=5
inherit eutils multilib toolchain-funcs autotools linux-info udev

DESCRIPTION="User-land utilities for LVM2 (device-mapper) software."
HOMEPAGE="http://sources.redhat.com/lvm2/"
SRC_URI="ftp://sources.redhat.com/pub/lvm2/${PN/lvm/LVM}.${PV}.tgz
		 ftp://sources.redhat.com/pub/lvm2/old/${PN/lvm/LVM}.${PV}.tgz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-linux ~x86-linux"

IUSE="readline static static-libs clvm cman +lvm1 selinux +udev +thin"

DEPEND_COMMON="!!sys-fs/device-mapper
	readline? ( sys-libs/readline )
	clvm? ( =sys-cluster/libdlm-3*
			cman? ( =sys-cluster/cman-3* ) )
	udev? ( virtual/udev )"

# /run is now required for locking during early boot. /var cannot be assumed to
# be available.
RDEPEND="${DEPEND_COMMON}
	!<sys-apps/openrc-0.10.1
	>=sys-apps/baselayout-2.1-r1
	!!sys-fs/lvm-user
	!!sys-fs/clvm
	>=sys-apps/util-linux-2.16
	thin? ( sys-block/thin-provisioning-tools )"

# Upgrading to this LVM will break older cryptsetup
RDEPEND="${RDEPEND}
		!<sys-fs/cryptsetup-1.1.2"

DEPEND="${DEPEND_COMMON}
		virtual/pkgconfig
		>=sys-devel/binutils-2.20.1-r1
		static? ( virtual/udev[static-libs] )"

S="${WORKDIR}/${PN/lvm/LVM}.${PV}"

pkg_setup() {
	local CONFIG_CHECK="~SYSVIPC"
	use udev && local WARNING_SYSVIPC="CONFIG_SYSVIPC:\tis not set (required for udev sync)\n"
	check_extra_config
	# 1. Genkernel no longer copies /sbin/lvm blindly.
	if use static; then
		elog "Warning, we no longer overwrite /sbin/lvm and /sbin/dmsetup with"
		elog "their static versions. If you need the static binaries,"
		elog "you must append .static to the filename!"
	fi
}

src_prepare() {
	epatch "${FILESDIR}"/lvm.conf-2.02.67.patch

	# Should not be needed due to upstream re-arrangement of build
	#epatch "${FILESDIR}"/${PN}-2.02.56-dmeventd.patch
	# Should not be need with new upstream udev rules
	#epatch "${FILESDIR}"/${PN}-2.02.56-device-mapper-export-format.patch

	# Merged upstream:
	#epatch "${FILESDIR}"/${PN}-2.02.51-as-needed.patch
	# Merged upstream:
	#epatch "${FILESDIR}"/${PN}-2.02.48-fix-pkgconfig.patch
	# Merged upstream:
	#epatch "${FILESDIR}"/${PN}-2.02.51-fix-pvcreate.patch
	# Fixed differently upstream:
	#epatch "${FILESDIR}"/${PN}-2.02.51-dmsetup-selinux-linking-fix-r3.patch

	epatch "${FILESDIR}"/${PN}-2.02.63-always-make-static-libdm.patch
	epatch "${FILESDIR}"/lvm2-2.02.56-lvm2create_initrd.patch
	# bug 318513 - merged upstream
	#epatch "${FILESDIR}"/${PN}-2.02.64-dmeventd-libs.patch
	# bug 301331
	epatch "${FILESDIR}"/${PN}-2.02.67-createinitrd.patch
	# bug 330373
	epatch "${FILESDIR}"/${PN}-2.02.92-locale-muck.patch
	# --as-needed
	epatch "${FILESDIR}"/${PN}-2.02.70-asneeded.patch
	# bug 332905
	epatch "${FILESDIR}"/${PN}-2.02.92-dynamic-static-ldflags.patch
	# bug 361429 - merged upstream in .85
	#epatch "${FILESDIR}"/${PN}-2.02.84-udev-pkgconfig.patch

	# Merged upstream
	#epatch "${FILESDIR}"/${PN}-2.02.73-asneeded.patch

	epatch "${FILESDIR}"/${PN}-2.02.88-respect-cc.patch

	# Upstream bug of LVM path
	# Merged upstream
	#epatch "${FILESDIR}"/${PN}-2.02.95-lvmpath.patch

	# Upstream patch for http://bugs.gentoo.org/424810
	# Merged upstream
	#epatch "${FILESDIR}"/${PN}-2.02.95-udev185.patch

	# Upstream patch for https://bugs.gentoo.org/444328
	# Merged upstream
	#epatch "${FILESDIR}"/${PN}-2.02.97-strict-aliasing.patch

	# Fix calling AR directly with USE static, bug #444082
	if use static ; then
		sed -i -e "s:\$(AR) rs \$@ \$(OBJECTS) lvmcmdlib.o lvm2cmd-static.o:$(tc-getAR) rs \$@ \$(OBJECTS) lvmcmdlib.o lvm2cmd-static.o:" \
			tools/Makefile.in || die "sed failed"
	fi

	eautoreconf
}

src_configure() {
	local myconf
	local buildmode

	myconf="${myconf} --enable-dmeventd"
	myconf="${myconf} --enable-cmdlib"
	myconf="${myconf} --enable-applib"
	myconf="${myconf} --enable-fsadm"
	myconf="${myconf} --enable-lvmetad"

	# Most of this package does weird stuff.
	# The build options are tristate, and --without is NOT supported
	# options: 'none', 'internal', 'shared'
	if use static ; then
		einfo "Building static LVM, for usage inside genkernel"
		buildmode="internal"
		# This only causes the .static versions to become available
		# We explicitly provide the .static versions so that they can be included in
		# initramfs environments.
		myconf="${myconf} --enable-static_link"
	else
		ewarn "Building shared LVM, it will not work inside genkernel!"
		buildmode="shared"
	fi

	# dmeventd requires mirrors to be internal, and snapshot available
	# so we cannot disable them
	myconf="${myconf} --with-mirrors=internal"
	myconf="${myconf} --with-snapshots=internal"
	use thin \
		&& myconf="${myconf} --with-thin=internal" \
		|| myconf="${myconf} --with-thin=none"

	if use lvm1 ; then
		myconf="${myconf} --with-lvm1=${buildmode}"
	else
		myconf="${myconf} --with-lvm1=none"
	fi

	# disable O_DIRECT support on hppa, breaks pv detection (#99532)
	use hppa && myconf="${myconf} --disable-o_direct"

	if use clvm; then
		myconf="${myconf} --with-cluster=${buildmode}"
		# 4-state! Make sure we get it right, per bug 210879
		# Valid options are: none, cman, gulm, all
		#
		# 2009/02:
		# gulm is removed now, now dual-state:
		# cman, none
		# all still exists, but is not needed
		#
		# 2009/07:
		# TODO: add corosync and re-enable ALL
		local clvmd=""
		use cman && clvmd="cman"
		#clvmd="${clvmd/cmangulm/all}"
		[ -z "${clvmd}" ] && clvmd="none"
		myconf="${myconf} --with-clvmd=${clvmd}"
		myconf="${myconf} --with-pool=${buildmode}"
	else
		myconf="${myconf} --with-clvmd=none --with-cluster=none"
	fi

	local udevdir="${EPREFIX}/lib/udev/rules.d"
	use udev && udevdir="${EPREFIX}/$(udev_get_udevdir)/rules.d"

	econf \
		$(use_enable readline) \
		$(use_enable selinux) \
		--enable-pkgconfig \
		--with-confdir="${EPREFIX}/etc" \
		--sbindir="${EPREFIX}/sbin" \
		--with-staticdir="${EPREFIX}/sbin" \
		--libdir="${EPREFIX}/$(get_libdir)" \
		--with-usrlibdir="${EPREFIX}/usr/$(get_libdir)" \
		--with-default-run-dir=/run/lvm \
		--with-default-locking-dir=/run/lock/lvm \
		--with-dmeventd-path=/sbin/dmeventd \
		$(use_enable udev udev_rules) \
		$(use_enable udev udev_sync) \
		$(use_with udev udevdir "${udevdir}") \
		${myconf} \
		CLDFLAGS="${LDFLAGS}"
}

src_compile() {
	einfo "Doing symlinks"
	pushd include
	emake || die "Failed to prepare symlinks"
	popd

	einfo "Starting main build"
	emake AR="$(tc-getAR)" || die "compile fail"
}

src_install() {
	emake DESTDIR="${D}" install

	dodoc README VERSION* WHATS_NEW WHATS_NEW_DM doc/*.{conf,c,txt}
	newinitd "${FILESDIR}"/lvm.rc-2.02.95-r2 lvm
	newinitd "${FILESDIR}"/lvm-monitoring.initd-2.02.67-r2 lvm-monitoring
	newconfd "${FILESDIR}"/lvm.confd-2.02.28-r2 lvm
	if use clvm; then
		newinitd "${FILESDIR}"/clvmd.rc-2.02.39 clvmd
		newconfd "${FILESDIR}"/clvmd.confd-2.02.39 clvmd
	fi

	# move shared libs to /lib(64)
	if use static-libs; then
		dolib.a libdm/ioctl/libdevmapper.a || die "dolib.a libdevmapper.a"
		#gen_usr_ldscript libdevmapper.so
	fi

	dosbin "${S}"/scripts/lvm2create_initrd/lvm2create_initrd
	doman  "${S}"/scripts/lvm2create_initrd/lvm2create_initrd.8
	newdoc "${S}"/scripts/lvm2create_initrd/README README.lvm2create_initrd

	insinto /etc
	doins "${FILESDIR}"/dmtab

	# Device mapper stuff
	newinitd "${FILESDIR}"/device-mapper.rc-2.02.95-r2 device-mapper
	newconfd "${FILESDIR}"/device-mapper.conf-1.02.22-r3 device-mapper

	newinitd "${FILESDIR}"/dmeventd.initd-2.02.67-r1 dmeventd
	if use static-libs; then
		dolib.a daemons/dmeventd/libdevmapper-event.a \
		|| die "dolib.a libdevmapper-event.a"
		#gen_usr_ldscript libdevmapper-event.so
	fi

	use static-libs || \
	rm -f "${D}"/usr/$(get_libdir)/{libdevmapper-event,liblvm2cmd,liblvm2app,libdevmapper}.a

	#insinto /etc/udev/rules.d/
	#newins "${FILESDIR}"/64-device-mapper.rules-2.02.56-r3 64-device-mapper.rules

	# do not rely on /lib -> /libXX link
	sed -i \
		-e "s|/lib/rcscripts/|/$(get_libdir)/rcscripts/|" \
		"${ED}"/etc/init.d/* || die

	elog "USE flag nocman is deprecated and replaced"
	elog "with the cman USE flag."
	elog ""
	elog "USE flags clvm and cman are masked"
	elog "by default and need to be unmasked to be used"
	elog ""
	elog "If you are using genkernel and root-on-LVM, rebuild the initramfs."
}

pkg_postinst() {
	elog "lvm volumes are no longer automatically created for"
	elog "baselayout-2 users. If you are using baselayout-2, be sure to"
	elog "run: # rc-update add lvm boot"
	elog "Do NOT add it if you are still using baselayout-1."
}

src_test() {
	einfo "Testcases disabled because of device-node mucking"
	einfo "If you want them, compile the package and see ${S}/tests"
}
