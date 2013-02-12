# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-boot/grub/grub-0.94-r1.ebuild,v 1.28 2012/02/29 23:09:30 floppym Exp $

inherit mount-boot eutils flag-o-matic toolchain-funcs

PATCHVER=0.1
DESCRIPTION="GNU GRUB boot loader"
HOMEPAGE="http://www.gnu.org/software/grub/"
SRC_URI="mirror://gnu-alpha/grub/${P}.tar.gz
	http://dev.gentoo.org/~seemant/distfiles/${P}-gentoo-${PATCHVER}.tar.bz2
	http://dev.gentoo.org/~seemant/distfiles/splash.xpm.gz
	mirror://gentoo/splash.xpm.gz
	mirror://gentoo/${P}-gentoo-${PATCHVER}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="-* x86 amd64"
IUSE="static"

RDEPEND=">=sys-libs/ncurses-5.2-r5"
DEPEND="${RDEPEND}
	>=sys-devel/automake-1.7
	>=sys-devel/autoconf-2.5"

PATCHDIR="${WORKDIR}/gentoo"

pkg_setup() {
	if use amd64; then
		ABI_ALLOW="x86"
		ABI="x86"
	fi
}

src_unpack() {
	unpack ${A}; cd "${S}"

	EPATCH_SUFFIX="patch"

	epatch "${PATCHDIR}"
}

src_compile() {
	unset BLOCK_SIZE #73499

	### i686-specific code in the boot loader is a bad idea; disabling to ensure
	### at least some compatibility if the hard drive is moved to an older or
	### incompatible system.
	unset CFLAGS

	filter-ldflags -pie
	append-flags -DNDEBUG
	[ `gcc-major-version` -eq 3 ] && append-flags -minline-all-stringops
	use static && append-ldflags -static

	autoconf || die
	aclocal || die
	WANT_AUTOMAKE=1.7 automake || die

	# build the net-bootable grub first
	CFLAGS="" \
	econf \
		--libdir=/lib \
		--datadir=/usr/lib/grub \
		--exec-prefix=/ \
		--disable-auto-linux-mem-opt \
		--enable-diskless \
		--enable-{3c{5{03,07,09,29,95},90x},cs89x0,davicom,depca,eepro{,100}} \
		--enable-{epic100,exos205,ni5210,lance,ne2100,ni{50,65}10,natsemi} \
		--enable-{ne,ns8390,wd,otulip,rtl8139,sis900,sk-g16,smc9000,tiara} \
		--enable-{tulip,via-rhine,w89c840} || die

	emake w89c840_o_CFLAGS="-O" || die "making netboot stuff"

	mv stage2/{nbgrub,pxegrub} "${S}"
	mv stage2/stage2 stage2/stage2.netboot

	make clean || die

	# now build the regular grub
	CFLAGS="${CFLAGS}" \
	econf \
			--libdir=/lib \
			--datadir=/usr/lib/grub \
			--exec-prefix=/ \
			--disable-auto-linux-mem-opt || die
	emake || die "making regular stuff"
}

src_install() {
	make DESTDIR="${D}" install || die
	exeinto /usr/lib/grub/${CHOST}
	doexe nbgrub pxegrub stage2/stage2 stage2/stage2.netboot

	insinto /boot/grub
	doins "${DISTDIR}"/splash.xpm.gz
	newins docs/menu.lst grub.conf.sample

	dodoc AUTHORS BUGS ChangeLog NEWS README THANKS TODO
	newdoc docs/menu.lst grub.conf.sample

	docinto gentoo
	dodoc "${PATCHDIR}"/README*
}

pkg_postinst() {
	[ "$ROOT" != "/" ] && return 0

	# change menu.lst to grub.conf
	if [ ! -e /boot/grub/grub.conf -a -e /boot/grub/menu.lst ]
	then
		mv /boot/grub/menu.lst /boot/grub/grub.conf
		ewarn
		ewarn "*** IMPORTANT NOTE: menu.lst has been renamed to grub.conf"
		ewarn
	fi
	einfo "Linking from new grub.conf name to menu.lst"
	ln -s grub.conf /boot/grub/menu.lst

	[ -e /boot/grub/stage2 ] && mv /boot/grub/stage2{,.old}

	einfo "Copying files from /usr/lib/grub to /boot"
	cp -p /usr/lib/grub/* /boot/grub
	cp -p /usr/lib/grub/grub/*/* /boot/grub

	[ -e /boot/grub/grub.conf ] \
		&& /usr/sbin/grub \
			--batch \
			--device-map=/boot/grub/device.map \
			< /boot/grub/grub.conf > /dev/null 2>&1
}
