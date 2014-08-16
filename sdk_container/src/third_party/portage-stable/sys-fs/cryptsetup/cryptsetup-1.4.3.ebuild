# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/cryptsetup/cryptsetup-1.4.3.ebuild,v 1.11 2014/07/25 19:59:09 ssuominen Exp $

EAPI="4"

inherit linux-info libtool

MY_P=${P/_rc/-rc}
DESCRIPTION="Tool to setup encrypted devices with dm-crypt"
HOMEPAGE="http://code.google.com/p/cryptsetup/"
SRC_URI="http://cryptsetup.googlecode.com/files/${MY_P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86"
IUSE="nls selinux static static-libs udev"

S=${WORKDIR}/${MY_P}

LIB_DEPEND="dev-libs/libgpg-error[static-libs(+)]
	>=dev-libs/popt-1.7[static-libs(+)]
	>=sys-apps/util-linux-2.17.2[static-libs(+)]
	>=dev-libs/libgcrypt-1.1.42:0[static-libs(+)]
	>=sys-fs/lvm2-2.02.64[static-libs(+)]
	>=sys-libs/e2fsprogs-libs-1.41[static-libs(+)]
	udev? ( virtual/libudev[static-libs(+)] )"
# We have to always depend on ${LIB_DEPEND} rather than put behind
# static? () because we provide a shared library which links against
# these other packages. #414665
RDEPEND="static-libs? ( ${LIB_DEPEND} )
	${LIB_DEPEND//\[static-libs(+)]}
	!<sys-apps/baselayout-2
	!sys-fs/cryptsetup-luks
	selinux? ( sys-libs/libselinux )"
DEPEND="${RDEPEND}
	static? ( ${LIB_DEPEND} )"

pkg_setup() {
	local CONFIG_CHECK="~DM_CRYPT ~CRYPTO ~CRYPTO_CBC"
	local WARNING_DM_CRYPT="CONFIG_DM_CRYPT:\tis not set (required for cryptsetup)\n"
	local WARNING_CRYPTO_CBC="CONFIG_CRYPTO_CBC:\tis not set (required for kernel 2.6.19)\n"
	local WARNING_CRYPTO="CONFIG_CRYPTO:\tis not set (required for cryptsetup)\n"
	check_extra_config
}

src_prepare() {
	sed -i '/^LOOPDEV=/s:$: || exit 0:' tests/{compat,mode}-test
	elibtoolize
}

src_configure() {
	econf \
		--sbindir=/sbin \
		--enable-shared \
		$(use_enable static static-cryptsetup) \
		$(use_enable static-libs static) \
		$(use_enable nls) \
		$(use_enable selinux) \
		$(use_enable udev)
}

src_test() {
	if [[ ! -e /dev/mapper/control ]] ; then
		ewarn "No /dev/mapper/control found -- skipping tests"
		return 0
	fi
	local p
	for p in /dev/mapper /dev/loop* ; do
		addwrite ${p}
	done
	default
}

src_install() {
	default
	use static && { mv "${ED}"/sbin/cryptsetup{.static,} || die ; }
	use static-libs || find "${ED}"/usr -name '*.la' -delete

	newconfd "${FILESDIR}"/1.0.6-dmcrypt.confd dmcrypt
	newinitd "${FILESDIR}"/dmcrypt.rc dmcrypt
}

pkg_postinst() {
	ewarn "This ebuild introduces a new set of scripts and configuration"
	ewarn "than the last version. If you are currently using /etc/conf.d/cryptfs"
	ewarn "then you *MUST* copy your old file to:"
	ewarn "/etc/conf.d/dmcrypt"
	ewarn "Or your encrypted partitions will *NOT* work."
	elog "Please see the example for configuring a LUKS mountpoint"
	elog "in /etc/conf.d/dmcrypt"
	elog
	elog "If you are using baselayout-2 then please do:"
	elog "rc-update add dmcrypt boot"
	elog "This version introduces a command line arguement 'key_timeout'."
	elog "If you want the search for the removable key device to timeout"
	elog "after 10 seconds add the following to your bootloader config:"
	elog "key_timeout=10"
	elog "A timeout of 0 will mean it will wait indefinitely."
	elog
	elog "Users using cryptsetup-1.0.x (dm-crypt plain) volumes must use"
	elog "a compatibility mode when using cryptsetup-1.1.x. This can be"
	elog "done by specifying the cipher (-c), key size (-s) and hash (-h)."
	elog "For more info, see http://code.google.com/p/cryptsetup/wiki/FrequentlyAskedQuestions#6._Issues_with_Specific_Versions_of_cryptsetup"
}
