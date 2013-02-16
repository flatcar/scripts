# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/dbus-glib/dbus-glib-0.100.ebuild,v 1.6 2012/10/14 14:58:21 armin76 Exp $

EAPI=4
inherit bash-completion-r1 eutils

DESCRIPTION="D-Bus bindings for glib"
HOMEPAGE="http://dbus.freedesktop.org/"
SRC_URI="http://dbus.freedesktop.org/releases/${PN}/${P}.tar.gz"

LICENSE="|| ( GPL-2 AFL-2.1 )"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~x86-solaris"
IUSE="debug doc static-libs test"

RDEPEND=">=dev-libs/expat-2
	>=dev-libs/glib-2.26
	>=sys-apps/dbus-1.6.2"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? ( dev-util/gtk-doc )"

# out of sources build directory
BD=${WORKDIR}/${P}-build
# out of sources build dir for make check
TBD=${WORKDIR}/${P}-tests-build

src_configure() {
	local myconf=(
		--localstatedir="${EPREFIX}"/var
		--enable-bash-completion
		$(use_enable debug verbose-mode)
		$(use_enable debug asserts)
		$(use_enable static-libs static)
		$(use_enable doc gtk-doc)
		--with-html-dir="${EPREFIX}"/usr/share/doc/${PF}/html
		)

	mkdir "${BD}"
	cd "${BD}"
	einfo "Running configure in ${BD}"
	ECONF_SOURCE="${S}" econf "${myconf[@]}"

	if use test; then
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

src_compile() {
	cd "${BD}"
	einfo "Running make in ${BD}"
	emake

	if use test; then
		cd "${TBD}"
		einfo "Running make in ${TBD}"
		emake
	fi
}

src_test() {
	cd "${TBD}"
	emake check
}

src_install() {
	# NEWS file is obsolete
	dodoc AUTHORS ChangeLog HACKING README

	cd "${BD}"
	emake DESTDIR="${D}" install

	newbashcomp "${ED}"/etc/bash_completion.d/dbus-bash-completion.sh dbus
	rm -rf "${ED}"/etc/bash_completion.d || die

	prune_libtool_files
}
