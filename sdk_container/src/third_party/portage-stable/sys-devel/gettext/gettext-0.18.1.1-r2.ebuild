# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/gettext/gettext-0.18.1.1-r2.ebuild,v 1.6 2012/09/06 18:19:33 vapier Exp $

EAPI="2"

inherit flag-o-matic eutils multilib toolchain-funcs mono libtool java-pkg-opt-2

DESCRIPTION="GNU locale utilities"
HOMEPAGE="http://www.gnu.org/software/gettext/"
SRC_URI="mirror://gnu/${PN}/${P}.tar.gz"

LICENSE="GPL-3 LGPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~sparc-fbsd ~x86-fbsd"
IUSE="acl doc emacs git java nls +cxx openmp elibc_glibc"

DEPEND="virtual/libiconv
	dev-libs/libxml2
	sys-libs/ncurses
	dev-libs/expat
	acl? ( virtual/acl )
	java? ( >=virtual/jdk-1.4 )"
RDEPEND="${DEPEND}
	git? ( dev-vcs/git )
	java? ( >=virtual/jre-1.4 )"
PDEPEND="emacs? ( app-emacs/po-mode )"

src_prepare() {
	java-pkg-opt-2_src_prepare
	epunt_cxx
	elibtoolize
	epatch "${FILESDIR}"/${P}-uclibc-sched_param-def.patch
	epatch "${FILESDIR}"/${P}-no-gets.patch
}

src_configure() {
	local myconf=""
	# Build with --without-included-gettext (on glibc systems)
	if use elibc_glibc ; then
		myconf="${myconf} --without-included-gettext $(use_enable nls)"
	else
		myconf="${myconf} --with-included-gettext --enable-nls"
	fi
	use cxx || export CXX=$(tc-getCC)

	# --without-emacs: Emacs support is now in a separate package
	# --with-included-glib: glib depends on us so avoid circular deps
	# --with-included-libcroco: libcroco depends on glib which ... ^^^
	#
	# --with-included-libunistring will _disable_ libunistring (since
	# --it's not bundled), see bug #326477
	econf \
		--docdir="/usr/share/doc/${PF}" \
		--without-emacs \
		--without-lispdir \
		$(use_enable java) \
		--with-included-glib \
		--with-included-libcroco \
		--with-included-libunistring \
		$(use_enable acl) \
		$(use_enable openmp) \
		$(use_with git) \
		--without-cvs
}

src_install() {
	emake install DESTDIR="${D}" || die "install failed"
	use nls || rm -r "${D}"/usr/share/locale
	dosym msgfmt /usr/bin/gmsgfmt #43435
	dobin gettext-tools/misc/gettextize || die "gettextize"

	# remove stuff that glibc handles
	if use elibc_glibc ; then
		rm -f "${D}"/usr/include/libintl.h
		rm -f "${D}"/usr/$(get_libdir)/libintl.*
	fi
	rm -f "${D}"/usr/share/locale/locale.alias "${D}"/usr/lib/charset.alias

	if [[ ${USERLAND} == "BSD" ]] ; then
		libname="libintl$(get_libname)"
		# Move dynamic libs and creates ldscripts into /usr/lib
		dodir /$(get_libdir)
		mv "${D}"/usr/$(get_libdir)/${libname}* "${D}"/$(get_libdir)/
		gen_usr_ldscript ${libname}
	fi

	if use java ; then
		java-pkg_dojar "${D}"/usr/share/${PN}/*.jar
		rm -f "${D}"/usr/share/${PN}/*.jar
		rm -f "${D}"/usr/share/${PN}/*.class
		if use doc ; then
			java-pkg_dojavadoc "${D}"/usr/share/doc/${PF}/javadoc2
			rm -rf "${D}"/usr/share/doc/${PF}/javadoc2
		fi
	fi

	if use doc ; then
		dohtml "${D}"/usr/share/doc/${PF}/*.html
	else
		rm -rf "${D}"/usr/share/doc/${PF}/{csharpdoc,examples,javadoc2,javadoc1}
	fi
	rm -f "${D}"/usr/share/doc/${PF}/*.html

	dodoc AUTHORS ChangeLog NEWS README THANKS
}

pkg_preinst() {
	# older gettext's sometimes installed libintl ...
	# need to keep the linked version or the system
	# could die (things like sed link against it :/)
	preserve_old_lib /{,usr/}$(get_libdir)/libintl$(get_libname 7)

	java-pkg-opt-2_pkg_preinst
}

pkg_postinst() {
	preserve_old_lib_notify /{,usr/}$(get_libdir)/libintl$(get_libname 7)
}
