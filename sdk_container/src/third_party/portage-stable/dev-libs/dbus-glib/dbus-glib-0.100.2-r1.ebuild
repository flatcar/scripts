# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/dbus-glib/dbus-glib-0.100.2-r1.ebuild,v 1.12 2014/06/24 22:07:15 mgorny Exp $

EAPI=5
inherit bash-completion-r1 eutils multilib-minimal

DESCRIPTION="D-Bus bindings for glib"
HOMEPAGE="http://dbus.freedesktop.org/"
SRC_URI="http://dbus.freedesktop.org/releases/${PN}/${P}.tar.gz"

LICENSE="|| ( GPL-2 AFL-2.1 )"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 ~s390 ~sh sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-interix ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x86-macos ~m68k-mint ~sparc-solaris ~x86-solaris"
IUSE="debug doc static-libs test"

CDEPEND=">=dev-libs/expat-2.1.0-r3[${MULTILIB_USEDEP}]
	>=dev-libs/glib-2.34.3:2[${MULTILIB_USEDEP}]
	>=sys-apps/dbus-1.6.18-r1[${MULTILIB_USEDEP}]"
DEPEND="${CDEPEND}
	virtual/pkgconfig
	doc? ( >=dev-util/gtk-doc-1.4 )"
RDEPEND="${CDEPEND}
	abi_x86_32? (
		!<app-emulation/emul-linux-x86-baselibs-20131008-r8
		!app-emulation/emul-linux-x86-baselibs[-abi_x86_32(-)]
	)"

# NEWS file is obsolete
DOCS=( AUTHORS ChangeLog HACKING README )

set_TBD() {
	# out of sources build dir for make check
	export TBD="${BUILD_DIR}-tests"
}

src_prepare() {
	# Fix testsuite, bug #356699 (fixed in git master)
	epatch "${FILESDIR}"/${PN}-0.100-fix-tests.patch

	# Wrong sections.txt file in the tarball; https://bugs.freedesktop.org/show_bug.cgi?id=55830
	cp "${FILESDIR}"/${PN}-0.100-dbus-glib-sections.txt doc/reference/dbus-glib-sections.txt || die
}

multilib_src_configure() {
	local myconf=(
		--localstatedir="${EPREFIX}"/var
		--enable-bash-completion
		$(use_enable debug verbose-mode)
		$(use_enable debug asserts)
		$(use_enable static-libs static)
		$(multilib_native_use_enable doc gtk-doc)
	)

	ECONF_SOURCE="${S}" econf "${myconf[@]}"

	if use test; then
		set_TBD
		mkdir "${TBD}"
		cd "${TBD}"
		einfo "Running configure in ${TBD}"
		ECONF_SOURCE="${S}" econf \
			"${myconf[@]}" \
			$(use_enable test checks) \
			$(use_enable test tests) \
			$(use_enable test asserts) \
			$(use_with test test-socket-dir "${T}"/dbus-test-socket)
	fi
}

multilib_src_compile() {
	emake

	if use test; then
		set_TBD
		cd "${TBD}"
		einfo "Running make in ${TBD}"
		emake
	fi
}

multilib_src_test() {
	set_TBD
	cd "${TBD}"
	emake check
}

multilib_src_install_all() {
	einstalldocs

	newbashcomp "${ED}"/etc/bash_completion.d/dbus-bash-completion.sh dbus
	rm -rf "${ED}"/etc/bash_completion.d || die

	prune_libtool_files
}
