# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-java/icedtea-bin/icedtea-bin-6.1.11.5-r1.ebuild,v 1.3 2012/12/03 20:48:55 ago Exp $

EAPI="4"

inherit java-vm-2 multilib prefix

dist="http://dev.gentoo.org/~caster/distfiles/"
TARBALL_VERSION="${PV}"
PLUGIN_VERSION="${PVR}"

DESCRIPTION="A Gentoo-made binary build of the IcedTea JDK"
HOMEPAGE="http://icedtea.classpath.org"
SRC_URI="
	amd64? ( ${dist}/${PN}-core-${TARBALL_VERSION}-amd64.tar.bz2 )
	x86? ( ${dist}/${PN}-core-${TARBALL_VERSION}-x86.tar.bz2 )
	doc? ( ${dist}/${PN}-doc-${TARBALL_VERSION}.tar.bz2 )
	examples? (
		amd64? ( ${dist}/${PN}-examples-${TARBALL_VERSION}-amd64.tar.bz2 )
		x86? ( ${dist}/${PN}-examples-${TARBALL_VERSION}-x86.tar.bz2 )
	)
	nsplugin? (
		amd64? ( ${dist}/${PN}-nsplugin-${PLUGIN_VERSION}-amd64.tar.bz2 )
		x86? ( ${dist}/${PN}-nsplugin-${PLUGIN_VERSION}-x86.tar.bz2 )
	)
	source? ( ${dist}/${PN}-src-${TARBALL_VERSION}.tar.bz2 )"

LICENSE="GPL-2-with-linking-exception"
SLOT="6"
KEYWORDS="-* amd64 x86"

IUSE="+X +alsa cjk +cups doc examples nsplugin source"
REQUIRED_USE="nsplugin? ( X )"
RESTRICT="strip"

# 423161
QA_PREBUILT="opt/.*"

ALSA_COMMON_DEP="
	>=media-libs/alsa-lib-1.0.20"
CUPS_COMMON_DEP="
	>=net-print/cups-1.4"
X_COMMON_DEP="
	dev-libs/glib
	>=media-libs/freetype-2.3.9:2
	>=x11-libs/gtk+-2.20.1:2
	>=x11-libs/libX11-1.3
	>=x11-libs/libXext-1.1
	>=x11-libs/libXi-1.3
	>=x11-libs/libXtst-1.1"

COMMON_DEP="
	>=media-libs/giflib-4.1.6-r1
	>=media-libs/libpng-1.5
	>=sys-devel/gcc-4.3
	>=sys-libs/glibc-2.11.2
	>=sys-libs/zlib-1.2.3-r1
	virtual/jpeg
	nsplugin? (
		>=dev-libs/atk-1.30.0
		>=dev-libs/glib-2.20.5:2
		>=dev-libs/nspr-4.8
		>=x11-libs/cairo-1.8.8
		>=x11-libs/pango-1.24.5

	)"

RDEPEND="${COMMON_DEP}
	X? (
		${X_COMMON_DEP}
		media-fonts/dejavu
		cjk? (
			media-fonts/arphicfonts
			media-fonts/baekmuk-fonts
			media-fonts/lklug
			media-fonts/lohit-fonts
			media-fonts/sazanami
		)
	)
	alsa? ( ${ALSA_COMMON_DEP} )
	cups? ( ${CUPS_COMMON_DEP} )"

src_install() {
	local dest="/opt/${P}"
	local ddest="${ED}/${dest}"
	dodir "${dest}"

	# Ensures HeadlessGraphicsEnvironment is used.
	if ! use X; then
		rm -r jre/lib/$(get_system_arch)/xawt || die
	fi

	# doins can't handle symlinks.
	cp -pRP bin include jre lib man "${ddest}" || die

	# Remove on next bump as the needed marks are already set by icedtea ebuild.
	java-vm_set-pax-markings "${ddest}"

	dodoc ../doc/{ASSEMBLY_EXCEPTION,THIRD_PARTY_README}

	if use doc; then
		dohtml -r ../doc/html/*
	fi

	if use examples; then
		cp -pRP share/{demo,sample} "${ddest}" || die
	fi

	if use source; then
		cp src.zip "${ddest}" || die
	fi

	if use nsplugin; then
		cp -pPR ../icedtea-web-bin-${SLOT} "${ddest}"/.. || die
		install_mozilla_plugin "/opt/icedtea-web-bin-${SLOT}/$(get_libdir)/IcedTeaPlugin.so"
		docinto icedtea-web
		dodoc ../doc/icedtea-web/*
	fi

	# Remove after next bump, handled by icedtea ebuild. Bug 390663
	cp "${FILESDIR}"/fontconfig.Gentoo.properties.src "${T}"/fontconfig.Gentoo.properties || die
	eprefixify "${T}"/fontconfig.Gentoo.properties
	insinto "${dest}"/jre/lib
	doins "${T}"/fontconfig.Gentoo.properties

	set_java_env
	java-vm_revdep-mask "${dest}"
}

pkg_preinst() {
	if has_version "<=dev-java/icedtea-bin-1.10.4:${SLOT}"; then
		# portage would preserve the symlink otherwise, related to bug #384397
		rm -f "${EROOT}/usr/lib/jvm/icedtea6-bin"
		elog "To unify the layout and simplify scripts, the identifier of Icedtea-bin-6*"
		elog "has changed from 'icedtea6-bin' to 'icedtea-bin-6' starting from version 6.1.10.4"
		elog "If you had icedtea6-bin as system VM, the change should be automatic, however"
		elog "build VM settings in /etc/java-config-2/build/jdk.conf are not changed"
		elog "and the same holds for any user VM settings. Sorry for the inconvenience."
	fi
}

pkg_postinst() {
	# Set as default VM if none exists
	java-vm-2_pkg_postinst

	if use nsplugin && [[ -z ${REPLACING_VERSIONS} ]]; then
		elog "The icedtea-bin-${SLOT} browser plugin can be enabled using eselect java-nsplugin"
		elog "Note that the plugin works only in browsers based on xulrunner-1.9.1+"
		elog "such as Firefox 3.5+ and recent Chromium versions."
	fi
}
