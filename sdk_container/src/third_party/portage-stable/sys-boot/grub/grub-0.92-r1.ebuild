# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-boot/grub/grub-0.92-r1.ebuild,v 1.16 2012/02/29 23:09:30 floppym Exp $

inherit mount-boot eutils flag-o-matic toolchain-funcs

PATCHVER=0.2
DESCRIPTION="GNU GRUB boot loader"
HOMEPAGE="http://www.gnu.org/software/grub/"
SRC_URI="mirror://gnu-alpha/grub/${P}.tar.gz
	http://dev.gentoo.org/~seemant/distfiles/${P}-gentoo-${PATCHVER}.tar.bz2
	http://dev.gentoo.org/~seemant/distfiles/splash.xpm.gz
	mirror://gentoo/splash.xpm.gz
	mirror://gentoo/${P}-gentoo-${PATCHVER}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="-* x86"
IUSE=""

DEPEND=">=sys-libs/ncurses-5.2-r5"

PATCHDIR="${WORKDIR}/gentoo"

src_unpack() {
	unpack ${A} ; cd "${S}"

	EPATCH_SUFFIX="patch"

	epatch "${PATCHDIR}"

	if [ "`gcc-version`" = "3.3" ]
	then
		epatch "${PATCHDIR}"/gcc-3.3
	fi
}

src_compile() {
	filter-flags "-fstack-protector"

	unset BLOCK_SIZE #73499

	#i686-specific code in the boot loader is a bad idea; disabling to ensure
	#at least some compatibility if the hard drive is moved to an older or
	#incompatible system.
	unset CFLAGS
	./configure --prefix=/usr \
		--sbindir=/sbin \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info \
		--disable-auto-linux-mem-opt \
		|| die "Configuration of package failed."

	#the vga16.patch changes configure.in but not configure so
	#--enable-vga16 doesnt work.  config.h gets overwritten by make.
	echo "#define VGA16 1" >> config.h.in

	emake || die "Building failed!"
}

src_install() {
	make \
		prefix="${D}"/usr \
		sbindir="${D}"/sbin \
		mandir="${D}"/usr/share/man \
		infodir="${D}"/usr/share/info \
		install || die "Installation failed."

	insinto /boot/grub
	doins "${DISTDIR}"/splash.xpm.gz
	dodoc AUTHORS BUGS ChangeLog NEWS README THANKS TODO
}

pkg_postinst() {
	[ "$ROOT" != "/" ] && return 0
	if [ ! -e /boot/grub/stage1 ]
	then
		#if the boot loader files aren't in place, copy them over.
		cd /usr/share/grub/i386-pc
		cp stage1 stage2 *stage1_5 /boot/grub
	else
		einfo '*** A new GRUB has been installed. If you need to reinstall'
		einfo '*** GRUB to a boot record on your drive, please remember to'
		einfo '*** "cp /usr/share/grub/i386-pc/*stage* /boot/grub" first.'
		einfo "*** If you're using XFS, unmount and remount /boot as well."
	fi

	# change menu.lst to grub.conf
	if [ ! -e /boot/grub/grub.conf -a -e /boot/grub/menu.lst ]
	then
		mv /boot/grub/menu.lst /boot/grub/grub.conf
		ln -s grub.conf /boot/grub/menu.lst
		einfo "*** IMPORTANT NOTE: menu.lst has been renamed to grub.conf"
	fi
}
