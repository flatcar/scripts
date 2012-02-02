# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/tetex.eclass,v 1.60 2009/01/06 19:25:20 grobian Exp $
#
# Author: Jaromir Malenko <malenko@email.cz>
# Author: Mamoru KOMACHI <usata@gentoo.org>
# Author: Martin Ehmsen <ehmsen@gentoo.org>
# Author: Alexandre Buisse <nattfodd@gentoo.org>
#
# A generic eclass to install tetex distributions. This shouldn't be
# inherited directly in any ebuilds. It should be inherited from
# tetex-{2,3}.eclass.

inherit eutils flag-o-matic toolchain-funcs

EXPORT_FUNCTIONS src_unpack src_compile src_install pkg_postinst

if [ -z "${TETEX_PV}" ] ; then
	TETEX_PV=${PV}
fi

IUSE="X doc tk"

S=${WORKDIR}/tetex-src-${TETEX_PV}
TETEX_SRC="tetex-src-${TETEX_PV}.tar.gz"
TETEX_TEXMF="tetex-texmf-${TETEX_PV}.tar.gz"
TETEX_TEXMF_SRC="tetex-texmfsrc-${TETEX_PV}.tar.gz"

DESCRIPTION="a complete TeX distribution"
HOMEPAGE="http://tug.org/teTeX/"
SRC_PATH_TETEX=ftp://cam.ctan.org/tex-archive/systems/unix/teTeX/2.0/distrib
SRC_URI="${SRC_PATH_TETEX}/${TETEX_SRC}
	${SRC_PATH_TETEX}/${TETEX_TEXMF}
	${SRC_PATH_TETEX}/${TETEX_TEXMF_SRC}
	mirror://gentoo/tetex-${TETEX_PV}-gentoo.tar.gz
	http://dev.gentoo.org/~usata/distfiles/tetex-${TETEX_PV}-gentoo.tar.gz"

SLOT="0"
LICENSE="GPL-2"
KEYWORDS="~ia64 ~x86 ~ppc ~sparc ~alpha ~amd64"

# tetex, ptex, cstetex must not block itself, fix for bug 121727
if [[ "${PN}" = "tetex" ]] ; then
	# >=app-text/ptex-3.1.9 work with app-text/tetex
	DEPEND="!<app-text/ptex-3.1.9"
fi
if [[ "${PN}" = "ptex" ]] ; then
	# >=app-text/ptex-3.1.9 does not co-exist with tetex-2
	DEPEND="!<app-text/tetex-3"
fi
if [[ "${PN}" = "cstetex" ]] ; then
	DEPEND="!app-text/ptex
		!app-text/tetex"
fi

DEPEND="${DEPEND}
	sys-apps/ed
	sys-libs/zlib
	X? (
				x11-libs/libXmu
				x11-libs/libXp
				x11-libs/libXpm
				x11-libs/libICE
				x11-libs/libSM
				x11-libs/libXaw
				x11-libs/libXfont
	)
	>=media-libs/libpng-1.2.1
	sys-libs/ncurses
	>=net-libs/libwww-5.3.2-r1"
RDEPEND="${DEPEND}
	!app-text/dvipdfm
	!dev-tex/currvita
	>=dev-lang/perl-5.2
	tk? ( dev-perl/perl-tk )
	dev-util/dialog"

tetex_src_unpack() {

	[ -z "$1" ] && tetex_src_unpack all

	while [ "$1" ]; do
	case $1 in
		unpack)
			unpack ${TETEX_SRC}
			unpack tetex-${TETEX_PV}-gentoo.tar.gz

			mkdir ${S}/texmf; cd ${S}/texmf
			umask 022
			unpack ${TETEX_TEXMF}
			;;
		patch)
			# Do not run config. Also fix local texmf tree.
			cd ${S}
			for p in ${WORKDIR}/patches/* ; do
				epatch $p
			done
			;;
		all)
			tetex_src_unpack unpack patch
			;;
	esac
	shift
	done
}

tetex_src_compile() {

	filter-flags "-fstack-protector"
	# filter -Os; bug #74708.
	# replace by -O2 instead, bug #191244
	replace-flags -Os -O2

	einfo "Building teTeX"

	local xdvik

	if useq X ; then
		addwrite /var/cache/fonts
		xdvik="--with-xdvik --with-oxdvik"
		#xdvik="$xdvik --with-system-t1lib"
	else
		xdvik="--without-xdvik --without-oxdvik"
	fi

	econf --bindir=/usr/bin \
		--datadir=${S} \
		--with-system-wwwlib \
		--with-libwww-include=/usr/include/w3c-libwww \
		--with-system-ncurses \
		--with-system-pnglib \
		--without-texinfo \
		--without-dialog \
		--without-texi2html \
		--with-system-zlib \
		--disable-multiplatform \
		--with-epsfwin \
		--with-mftalkwin \
		--with-regiswin \
		--with-tektronixwin \
		--with-unitermwin \
		--with-ps=gs \
		--enable-ipc \
		--with-etex \
		$(use_with X x) \
		${xdvik} \
		${TETEX_ECONF} || die

	emake -j1 CC="$(tc-getCC)" CXX="$(tc-getCXX)" texmf=${TEXMF_PATH:-/usr/share/texmf} || die "make teTeX failed"
}

tetex_src_install() {

	if [ -z "$1" ]; then
		tetex_src_install all
	fi

	while [ "$1" ]; do
	case $1 in
		base)
			dodir /usr/share/
			# Install texmf files
			einfo "Installing texmf ..."
			cp -Rv texmf ${D}/usr/share

			# Install teTeX files
			einfo "Installing teTeX ..."
			dodir ${TEXMF_PATH:-/usr/share/texmf}/web2c
			einstall bindir=${D}/usr/bin texmf=${D}${TEXMF_PATH:-/usr/share/texmf} || die

			dosbin ${T}/texmf-update
			;;
		doc)
			dodoc PROBLEMS README
			docinto texk
			dodoc texk/ChangeLog texk/README
			docinto kpathesa
			cd ${S}/texk/kpathsea
			dodoc README* NEWS PROJECTS HIER
			docinto dviljk
			cd ${S}/texk/dviljk
			dodoc AUTHORS README NEWS
			docinto dvipsk
			cd ${S}/texk/dvipsk
			dodoc AUTHORS ChangeLog INSTALLATION README
			docinto makeindexk
			cd ${S}/texk/makeindexk
			dodoc CONTRIB COPYING NEWS NOTES PORTING README
			docinto ps2pkm
			cd ${S}/texk/ps2pkm
			dodoc ChangeLog CHANGES.type1 INSTALLATION README*
			docinto web2c
			cd ${S}/texk/web2c
			dodoc AUTHORS ChangeLog NEWS PROJECTS README
			#docinto xdvik
			#cd ${S}/texk/xdvik
			#dodoc BUGS FAQ README*

			# move docs to /usr/share/doc/${PF}
			if useq doc ; then
				dodir /usr/share/doc/${PF}
				mv ${D}/usr/share/texmf/doc/* \
					${D}/usr/share/doc/${PF} \
					|| die "mv doc failed."
				cd ${D}/usr/share/texmf
				rmdir doc
				ln -s ../doc/${PF} doc \
					|| die "ln -s doc failed."
				cd -
			else
				rm -rf ${D}/usr/share/texmf/doc
			fi
			;;
		fixup)
			#fix for conflicting readlink binary:
			rm -f ${D}/bin/readlink
			rm -f ${D}/usr/bin/readlink

			#add /var/cache/fonts directory
			dodir /var/cache/fonts

			#fix for lousy upstream permisssions on /usr/share/texmf files
			#NOTE: do not use fowners, as its not recursive ...
			einfo "Fixing permissions ..."
			# root group name doesn't necessarily exist on non-Linux
			chown -R 0:0 ${D}/usr/share/texmf
			find ${D} -name "ls-R" -exec rm {} \;
			;;
		all)
			tetex_src_install base doc fixup
			;;
	esac
	shift
	done
}

tetex_pkg_postinst() {

	if [ "$ROOT" = "/" ] ; then
		/usr/sbin/texmf-update
	fi
	if [ -d "/etc/texmf" ] ; then
		elog
		elog "If you have configuration files in /etc/texmf to merge,"
		elog "please update them and run /usr/sbin/texmf-update."
		elog
	fi
}
