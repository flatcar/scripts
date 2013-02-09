# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/e2fsprogs/e2fsprogs-1.41.12-r1.ebuild,v 1.6 2012/05/04 19:09:17 jdhore Exp $

EAPI="3"

inherit eutils flag-o-matic multilib toolchain-funcs

DESCRIPTION="Standard EXT2/EXT3/EXT4 filesystem utilities"
HOMEPAGE="http://e2fsprogs.sourceforge.net/"
SRC_URI="mirror://sourceforge/e2fsprogs/${P}.tar.gz"

LICENSE="GPL-2 BSD"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 -x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~m68k-mint"
IUSE="nls elibc_FreeBSD"

RDEPEND="~sys-libs/${PN}-libs-${PV}
	>=sys-apps/util-linux-2.16
	nls? ( virtual/libintl )"
DEPEND="${RDEPEND}
	nls? ( sys-devel/gettext )
	virtual/pkgconfig
	sys-apps/texinfo"

pkg_setup() {
	if [[ ! -e ${EROOT}/etc/mtab ]] ; then
		# add some crap to deal with missing /etc/mtab #217719
		ewarn "No /etc/mtab file, creating one temporarily"
		echo "${PN} crap for src_test" > "${EROOT}"/etc/mtab
	fi
}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-1.38-tests-locale.patch #99766
	epatch "${FILESDIR}"/${PN}-1.41.8-makefile.patch
	epatch "${FILESDIR}"/${PN}-1.41.12-getpagesize.patch
	epatch "${FILESDIR}"/${PN}-1.40-fbsd.patch
	# use symlinks rather than hardlinks
	sed -i \
		-e 's:$(LN) -f $(DESTDIR).*/:$(LN_S) -f :' \
		{e2fsck,misc}/Makefile.in || die
	epatch "${FILESDIR}"/${P}-darwin-makefile.patch
	if [[ ${CHOST} == *-mint* ]] ; then
		epatch "${FILESDIR}"/${PN}-1.41-mint.patch
		epatch "${FILESDIR}"/${PN}-1.41.12-mint-blkid.patch
	fi
	# blargh ... trick e2fsprogs into using e2fsprogs-libs
	rm -rf doc
	sed -i -r \
		-e 's:@LIBINTL@:@LTLIBINTL@:' \
		-e '/^LIB(COM_ERR|SS)/s:[$][(]LIB[)]/lib([^@]*)@LIB_EXT@:-l\1:' \
		-e '/^DEPLIB(COM_ERR|SS)/s:=.*:=:' \
		MCONFIG.in || die "muck libs" #122368
	sed -i -r \
		-e '/^LIB_SUBDIRS/s:lib/(et|ss)::g' \
		Makefile.in || die "remove subdirs"
	sed -i \
		-e '/^#define _XOPEN/i#define _GNU_SOURCE' \
		misc/mke2fs.c || die # needs open64() prototype

	# Avoid rebuild
	touch lib/ss/ss_err.h
}

src_configure() {
	# Keep the package from doing silly things #261411
	export VARTEXFONTS=${T}/fonts

	# We want to use the "bsd" libraries while building on Darwin, but while
	# building on other Gentoo/*BSD we prefer elf-naming scheme.
	local libtype
	case ${CHOST} in
		*-darwin*) libtype=--enable-bsd-shlibs  ;;
		*-mint*)   libtype=                     ;;
		*)         libtype=--enable-elf-shlibs  ;;
	esac

	ac_cv_path_LDCONFIG=: \
	econf \
		--with-root-prefix="${EPREFIX}/" \
		${libtype} \
		$(tc-has-tls || echo --disable-tls) \
		--without-included-gettext \
		$(use_enable nls) \
		--disable-libblkid \
		--disable-libuuid \
		--disable-fsck \
		--disable-uuidd
	if [[ ${CHOST} != *-uclibc ]] && grep -qs 'USE_INCLUDED_LIBINTL.*yes' config.{log,status} ; then
		eerror "INTL sanity check failed, aborting build."
		eerror "Please post your ${S}/config.log file as an"
		eerror "attachment to http://bugs.gentoo.org/show_bug.cgi?id=81096"
		die "Preventing included intl cruft from building"
	fi
}

src_compile() {
	emake COMPILE_ET=compile_et MK_CMDS=mk_cmds || die

	# Build the FreeBSD helper
	if use elibc_FreeBSD ; then
		cp "${FILESDIR}"/fsck_ext2fs.c .
		emake fsck_ext2fs || die
	fi
}

pkg_preinst() {
	if [[ -r ${EROOT}/etc/mtab ]] ; then
		if [[ $(<"${EROOT}"/etc/mtab) == "${PN} crap for src_test" ]] ; then
			rm -f "${EROOT}"/etc/mtab
		fi
	fi
}

src_install() {
	# need to set root_libdir= manually as any --libdir options in the
	# econf above (i.e. multilib) will screw up the default #276465
	emake \
		STRIP=: \
		root_libdir="${EPREFIX}/usr/$(get_libdir)" \
		DESTDIR="${D}" \
		install install-libs || die
	dodoc README RELEASE-NOTES

	insinto /etc
	doins "${FILESDIR}"/e2fsck.conf || die

	# Move shared libraries to /lib/, install static libraries to
	# /usr/lib/, and install linker scripts to /usr/lib/.
	set -- "${ED}"/usr/$(get_libdir)/*.a
	set -- ${@/*\/lib}
	gen_usr_ldscript -a "${@/.a}"

	if use elibc_FreeBSD ; then
		# Install helpers for us
		into /
		dosbin "${S}"/fsck_ext2fs || die
		doman "${FILESDIR}"/fsck_ext2fs.8 || die

		# filefrag is linux only
		rm \
			"${ED}"/usr/sbin/filefrag \
			"${ED}"/usr/share/man/man8/filefrag.8 || die
	fi
}
