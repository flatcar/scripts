# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libfm/libfm-9999.ebuild,v 1.32 2012/12/23 14:40:40 hwoarang Exp $

EAPI=5

EGIT_REPO_URI="git://pcmanfm.git.sourceforge.net/gitroot/pcmanfm/${PN}"

inherit autotools git-2 fdo-mime vala

DESCRIPTION="A library for file management"
HOMEPAGE="http://pcmanfm.sourceforge.net/"

LICENSE="GPL-2"
SLOT="0"
IUSE="debug doc examples vala"
KEYWORDS=""

COMMON_DEPEND=">=dev-libs/glib-2.18:2
	>=x11-libs/gtk+-2.16:2
	>=lxde-base/menu-cache-0.3.2:="
RDEPEND="${COMMON_DEPEND}
	x11-misc/shared-mime-info
	|| ( gnome-base/gvfs[udev,udisks] gnome-base/gvfs[udev,gdu] )"
DEPEND="${COMMON_DEPEND}
	>=dev-lang/vala-0.14.0
	dev-util/gtk-doc-am
	doc? (
		dev-util/gtk-doc
	)
	>=dev-util/intltool-0.40
	virtual/pkgconfig
	sys-devel/gettext"

DOCS=( AUTHORS TODO )

src_prepare() {
	if ! use doc; then
		sed -ie "/^SUBDIRS_DOCS/d" Makefile.am || die "sed failed"
		sed -ie "/^[[:space:]]*docs/d" configure.ac || die "sed failed"
	else
		gtkdocize --copy || die
	fi
	intltoolize --force --copy --automake || die
	#disable unused translations. Bug #356029
	for trans in app-chooser ask-rename exec-file file-prop preferred-apps \
		progress;do
		echo "data/ui/"${trans}.ui >> po/POTFILES.in
	done
	sed -i -e "s:-O0::" -e "/-DG_ENABLE_DEBUG/s: -g::" "${S}"/configure.ac || die
	#Remove -Werror for automake-1.12. Bug #421101
	sed -i "s:-Werror::" configure.ac || die
	# Drop the symlink. We will create it later on. 439580
	sed -i "/@LN_S@ @PACKAGE@-@FMLIBVER@/d" src/Makefile.am \
		|| die "failed to remove the includedir symlink"

	eautoreconf
	rm -r autom4te.cache || die
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
		$(use_enable doc gtk-doc) \
		--with-html-dir=/usr/share/doc/${PF}/html
}

src_install() {
	default
	find "${D}" -name '*.la' -exec rm -f '{}' +
	# 439570
	[[ -d ${D}/usr/include/${PN} ]] \
		&& rm -r ${D}/usr/include/${PN}
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
