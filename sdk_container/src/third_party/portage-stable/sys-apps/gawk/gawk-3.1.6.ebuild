# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/gawk/gawk-3.1.6.ebuild,v 1.11 2008/11/28 07:28:08 ulm Exp $

inherit eutils toolchain-funcs multilib

DESCRIPTION="GNU awk pattern-matching language"
HOMEPAGE="http://www.gnu.org/software/gawk/gawk.html"
SRC_URI="mirror://gnu/gawk/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc ~sparc-fbsd x86 ~x86-fbsd"
IUSE="nls"

RDEPEND=""
DEPEND="${RDEPEND}
	nls? ( sys-devel/gettext )"

SFFS=${WORKDIR}/filefuncs

src_unpack() {
	unpack ${A}

	# Copy filefuncs module's source over ...
	cp -r "${FILESDIR}"/filefuncs "${SFFS}" || die "cp failed"

	cd "${S}"
	epatch "${FILESDIR}"/autoconf-mktime-2.61.patch #220040
	epatch "${FILESDIR}"/${PN}-3.1.3-getpgrp_void.patch
	epatch "${FILESDIR}"/${P}-gnuinfo.patch #249130
}

src_compile() {
	local bindir=/usr/bin
	use userland_GNU && bindir=/bin
	econf \
		--bindir=${bindir} \
		--libexec='$(libdir)/misc' \
		$(use_enable nls) \
		--enable-switch \
		|| die
	emake || die "emake failed"

	cd "${SFFS}"
	emake CC=$(tc-getCC) || die "filefuncs emake failed"
}

src_install() {
	emake install DESTDIR="${D}" || die "install failed"
	cd "${SFFS}"
	emake LIBDIR="$(get_libdir)" install || die "filefuncs install failed"

	dodir /usr/bin
	# In some rare cases, (p)gawk gets installed as (p)gawk- and not
	# (p)gawk-${PV} ...  Also make sure that /bin/(p)gawk is a symlink
	# to /bin/(p)gawk-${PV}.
	local bindir=/usr/bin binpath= x=
	use userland_GNU && bindir=/bin
	for x in gawk pgawk igawk ; do
		[[ ${x} == "gawk" ]] \
			&& binpath=${bindir} \
			|| binpath=/usr/bin

		if [[ -f ${D}/${bindir}/${x} && ! -f ${D}/${bindir}/${x}-${PV} ]] ; then
			mv -f "${D}"/${bindir}/${x} "${D}"/${binpath}/${x}-${PV}
		elif [[ -f ${D}/${bindir}/${x}- && ! -f ${D}/${bindir}/${x}-${PV} ]] ; then
			mv -f "${D}"/${bindir}/${x}- "${D}"/${binpath}/${x}-${PV}
		elif [[ ${binpath} == "/usr/bin" && -f ${D}/${bindir}/${x}-${PV} ]] ; then
			mv -f "${D}"/${bindir}/${x}-${PV} "${D}"/${binpath}/${x}-${PV}
		fi

		rm -f "${D}"/${bindir}/${x}
		[[ -x "${D}"/${binpath}/${x}-${PV} ]] && dosym ${x}-${PV} ${binpath}/${x}
		if use userland_GNU ; then
			[[ ${binpath} == "/usr/bin" ]] && dosym /usr/bin/${x}-${PV} /bin/${x}
		fi
	done

	rm -f "${D}"/bin/awk
	dodir /usr/bin
	# Compat symlinks
	dosym gawk-${PV} ${bindir}/awk
	dosym ${bindir}/gawk-${PV} /usr/bin/awk
	if use userland_GNU ; then
		dosym /bin/gawk-${PV} /usr/bin/gawk
	else
		rm -f "${D}"/{,usr/}bin/awk{,-${PV}}
	fi

	# Install headers
	insinto /usr/include/awk
	doins "${S}"/*.h || die "ins headers failed"
	# We do not want 'acconfig.h' in there ...
	rm -f "${D}"/usr/include/awk/acconfig.h

	cd "${S}"
	rm -f "${D}"/usr/share/man/man1/pgawk.1
	dosym gawk.1 /usr/share/man/man1/pgawk.1
	if use userland_GNU ; then
		dosym gawk.1 /usr/share/man/man1/awk.1
	fi
	dodoc AUTHORS ChangeLog FUTURES LIMITATIONS NEWS PROBLEMS POSIX.STD README
	docinto README_d
	dodoc README_d/*
	docinto awklib
	dodoc awklib/ChangeLog
	docinto pc
	dodoc pc/ChangeLog
	docinto posix
	dodoc posix/ChangeLog
}
