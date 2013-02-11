# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libfm/libfm-1.0.2.ebuild,v 1.3 2012/11/13 19:24:45 hwoarang Exp $

EAPI=4

inherit autotools fdo-mime vala

MY_PV=${PV/_/}
MY_P="${PN}-${MY_PV}"
DESCRIPTION="A library for file management"
HOMEPAGE="http://pcmanfm.sourceforge.net/"
SRC_URI="http://dev.gentoo.org/~hwoarang/distfiles/${MY_P}.tar.gz"

KEYWORDS="~alpha ~amd64 ~arm ~ppc ~x86 ~amd64-linux ~x86-linux"
LICENSE="GPL-2"
SLOT="0"
IUSE="debug doc examples vala"

COMMON_DEPEND=">=dev-libs/glib-2.18:2
	>=x11-libs/gtk+-2.16:2
	>=lxde-base/menu-cache-0.3.2"
RDEPEND="${COMMON_DEPEND}
	x11-misc/shared-mime-info
	|| ( gnome-base/gvfs[udev,udisks] gnome-base/gvfs[udev,gdu] )"
DEPEND="${COMMON_DEPEND}
	vala? ( $(vala_depend) )
	dev-util/gtk-doc-am
	>=dev-util/intltool-0.40
	virtual/pkgconfig
	sys-devel/gettext"

S="${WORKDIR}"/${MY_P}

src_prepare() {
	if ! use doc; then
		sed -ie '/SUBDIRS=/s#docs##' "${S}"/Makefile.am || die "sed failed"
		sed -ie '/^[[:space:]]*docs/d' configure.ac || die "sed failed"
	fi
	sed -i -e "s:-O0::" -e "/-DG_ENABLE_DEBUG/s: -g::" \
		configure.ac || die "sed failed"
	#Remove -Werror for automake-1.12. Bug #421101
	sed -i "s:-Werror::" configure.ac || die
	eautoreconf
	use vala && export VALAC="$(type -p valac-$(vala_best_api_version))"
}

src_configure() {
	econf \
		--sysconfdir="${EPREFIX}/etc" \
		--disable-dependency-tracking \
		--disable-static \
		--disable-udisks \
		$(use_enable examples demo) \
		$(use_enable debug) \
		$(use_enable vala actions) \
		$(use_enable doc gtk-doc)
		--with-html-dir=/usr/share/doc/${PF}/html
}

src_install() {
	default
	find "${D}" -name '*.la' -exec rm -f '{}' +
	# Remove broken symlink #439570
	# Sometimes a directory is created instead of a symlink. No idea why...
	# It is wrong anyway. We expect a libfm-1.0 directory and then a libfm
	# symlink to it.
	if [[ -h ${D}/usr/include/${PN} || -d ${D}/usr/include/${PN} ]]; then
		rm -r "${D}"/usr/include/${PN}
	fi
}

pkg_preinst() {
	# Resolve the symlink mess. Bug #439570
	[[ -d "${ROOT}"/usr/include/${PN} ]] && \
		rm -rf "${ROOT}"/usr/include/${PN}
	if [[ -d "${D}"/usr/include/${PN}-1.0 ]]; then
		cd ${D}/usr/include
		ln -s --force ${PN}-1.0 ${PN}
	fi
}

pkg_postinst() {
	fdo-mime_mime_database_update
}

pkg_postrm() {
	fdo-mime_mime_database_update
}
