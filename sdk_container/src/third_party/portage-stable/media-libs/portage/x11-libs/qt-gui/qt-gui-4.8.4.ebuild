# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/qt-gui/qt-gui-4.8.4.ebuild,v 1.13 2013/01/27 00:41:32 pesa Exp $

EAPI=4

inherit eutils qt4-build

DESCRIPTION="The GUI module for the Qt toolkit"
SLOT="4"
if [[ ${QT4_BUILD_TYPE} == live ]]; then
	KEYWORDS=""
else
	KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~x64-solaris ~x86-solaris"
fi
IUSE="+accessibility cups dbus egl gif +glib gtkstyle mng nas nis qt3support tiff trace xinerama +xv"

REQUIRED_USE="
	gtkstyle? ( glib )
"

RDEPEND="
	app-admin/eselect-qtgraphicssystem
	media-libs/fontconfig
	media-libs/freetype:2
	media-libs/libpng:0
	sys-libs/zlib
	virtual/jpeg
	~x11-libs/qt-core-${PV}[aqua=,debug=,glib=,qt3support=]
	~x11-libs/qt-script-${PV}[aqua=,debug=]
	!aqua? (
		x11-libs/libICE
		x11-libs/libSM
		x11-libs/libX11
		x11-libs/libXcursor
		x11-libs/libXext
		x11-libs/libXi
		x11-libs/libXrandr
		x11-libs/libXrender
		xinerama? ( x11-libs/libXinerama )
		xv? ( x11-libs/libXv )
	)
	cups? ( net-print/cups )
	dbus? ( ~x11-libs/qt-dbus-${PV}[aqua=,debug=] )
	egl? ( media-libs/mesa[egl] )
	gtkstyle? ( x11-libs/gtk+:2[aqua=] )
	mng? ( >=media-libs/libmng-1.0.9 )
	nas? ( >=media-libs/nas-1.5 )
	tiff? ( media-libs/tiff:0 )
"
DEPEND="${RDEPEND}
	!aqua? (
		x11-proto/inputproto
		x11-proto/xextproto
		xinerama? ( x11-proto/xineramaproto )
		xv? ( x11-proto/videoproto )
	)
"
PDEPEND="qt3support? ( ~x11-libs/qt-qt3support-${PV}[aqua=,debug=] )"

PATCHES=(
	"${FILESDIR}/${PN}-4.7.3-cups.patch"
)

pkg_setup() {
	# this belongs to pkg_pretend, we have to upgrade to EAPI 4 :)
	# was planning to use a dep, but to reproduce this you have to
	# clean-emerge qt-gui[gtkstyle] while having cairo[qt4] installed.
	# no need to restrict normal first time users for that :)
	if use gtkstyle && ! has_version x11-libs/qt-gui && has_version x11-libs/cairo[qt4]; then
		echo
		eerror "When building qt-gui[gtkstyle] from scratch with cairo present,"
		eerror "cairo must have the qt4 use flag disabled, otherwise the gtk"
		eerror "style cannot be built."
		ewarn
		eerror "You have the following options:"
		eerror "  - rebuild cairo with -qt4 USE"
		eerror "  - build qt-gui with -gtkstyle USE"
		ewarn
		eerror "After you successfully install qt-gui, you'll be able to"
		eerror "re-enable the disabled use flag and/or reinstall cairo."
		ewarn
		echo
		die "can't build ${PN} with USE=gtkstyle if cairo has 'qt4' USE flag enabled"
	fi

	QT4_TARGET_DIRECTORIES="
		src/gui
		src/scripttools
		tools/designer
		tools/linguist/linguist
		src/plugins/imageformats/gif
		src/plugins/imageformats/ico
		src/plugins/imageformats/jpeg
		src/plugins/inputmethods"

	QT4_EXTRACT_DIRECTORIES="
		include
		src
		tools"

	use accessibility && QT4_TARGET_DIRECTORIES="${QT4_TARGET_DIRECTORIES} src/plugins/accessible/widgets"
	use dbus && QT4_TARGET_DIRECTORIES="${QT4_TARGET_DIRECTORIES} tools/qdbus/qdbusviewer"
	use mng && QT4_TARGET_DIRECTORIES="${QT4_TARGET_DIRECTORIES} src/plugins/imageformats/mng"
	use tiff && QT4_TARGET_DIRECTORIES="${QT4_TARGET_DIRECTORIES} src/plugins/imageformats/tiff"
	use trace && QT4_TARGET_DIRECTORIES="${QT4_TARGET_DIRECTORIES}	src/plugins/graphicssystems/trace"

	# mac version does not contain qtconfig?
	[[ ${CHOST} == *-darwin* ]] || QT4_TARGET_DIRECTORIES+=" tools/qtconfig"

	QT4_EXTRACT_DIRECTORIES="${QT4_TARGET_DIRECTORIES} ${QT4_EXTRACT_DIRECTORIES}"

	qt4-build_pkg_setup
}

src_prepare() {
	qt4-build_src_prepare

	# Add -xvideo to the list of accepted configure options
	sed -i -e 's:|-xinerama|:&-xvideo|:' configure

	# Don't build plugins this go around, because they depend on qt3support lib
	sed -i -e 's:CONFIG(shared:# &:g' tools/designer/src/src.pro
}

src_configure() {
	export PATH="${S}/bin:${PATH}"
	export LD_LIBRARY_PATH="${S}/lib:${LD_LIBRARY_PATH}"

	myconf="$(qt_use accessibility)
		$(qt_use cups)
		$(use gif || echo -no-gif)
		$(qt_use glib)
		$(qt_use mng libmng system)
		$(qt_use nas nas-sound system)
		$(qt_use nis)
		$(qt_use tiff libtiff system)
		$(qt_use dbus qdbus)
		$(qt_use dbus)
		$(qt_use egl)
		$(qt_use qt3support)
		$(qt_use gtkstyle)
		$(qt_use xinerama)
		$(qt_use xv xvideo)"

	myconf+="
		-system-libpng -system-libjpeg -system-zlib
		-no-sql-mysql -no-sql-psql -no-sql-ibase -no-sql-sqlite -no-sql-sqlite2 -no-sql-odbc
		-sm -xshape -xsync -xcursor -xfixes -xrandr -xrender -mitshm -xinput -xkb
		-fontconfig -no-svg -no-webkit -no-phonon -no-opengl"

	[[ ${CHOST} == *86*-apple-darwin* ]] && myconf+=" -no-ssse3" #367045

	qt4-build_src_configure

	if use gtkstyle; then
		einfo "patching the Makefile to fix qgtkstyle compilation"
		sed "s:-I/usr/include/qt4 ::" -i src/gui/Makefile ||
			die "sed failed"
	fi
	sed -i -e "s:-I/usr/include/qt4/QtGui ::" src/gui/Makefile || die "sed failed"
}

src_install() {
	QCONFIG_ADD="
		mitshm tablet x11sm xcursor xfixes xinput xkb xrandr xrender xshape xsync
		fontconfig gif png system-png jpeg system-jpeg
		$(usev accessibility)
		$(usev cups)
		$(use mng && echo system-mng)
		$(usev nas)
		$(usev nis)
		$(use tiff && echo system-tiff)
		$(usev xinerama)
		$(use xv && echo xvideo)"
	QCONFIG_REMOVE="no-gif no-jpeg no-png"
	QCONFIG_DEFINE="$(use accessibility && echo QT_ACCESSIBILITY)
			$(use cups && echo QT_CUPS)
			$(use egl && echo QT_EGL)
			QT_FONTCONFIG
			$(use gtkstyle && echo QT_STYLE_GTK)
			QT_IMAGEFORMAT_JPEG QT_IMAGEFORMAT_PNG QT_MITSHM
			$(use mng && echo QT_IMAGEFORMAT_MNG)
			$(use nas && echo QT_NAS)
			$(use nis && echo QT_NIS)
			$(use tiff && echo QT_IMAGEFORMAT_TIFF)
			QT_SESSIONMANAGER QT_SHAPE QT_TABLET QT_XCURSOR QT_XFIXES
			$(use xinerama && echo QT_XINERAMA)
			QT_XINPUT QT_XKB QT_XRANDR QT_XRENDER QT_XSYNC
			$(use xv && echo QT_XVIDEO)"

	qt4-build_src_install

	# qt-creator
	# some qt-creator headers are located
	# under /usr/include/qt4/QtDesigner/private.
	# those headers are just includes of the headers
	# which are located under tools/designer/src/lib/*
	# So instead of installing both, we create the private folder
	# and drop tools/designer/src/lib/* headers in it.
	if use aqua && [[ ${CHOST##*-darwin} -ge 9 ]]; then
		insinto "${QTLIBDIR#${EPREFIX}}"/QtDesigner.framework/Headers/private/
	else
		insinto "${QTHEADERDIR#${EPREFIX}}"/QtDesigner/private/
	fi
	doins "${S}"/tools/designer/src/lib/shared/*
	doins "${S}"/tools/designer/src/lib/sdk/*

	# install private headers
	if use aqua && [[ ${CHOST##*-darwin} -ge 9 ]]; then
		insinto "${QTLIBDIR#${EPREFIX}}"/QtGui.framework/Headers/private/
	else
		insinto "${QTHEADERDIR#${EPREFIX}}"/QtGui/private
	fi
	find "${S}"/src/gui -type f -name '*_p.h' -exec doins {} +

	if use aqua && [[ ${CHOST##*-darwin} -ge 9 ]]; then
		# rerun to get links to headers right
		fix_includes
	fi

	# touch the available graphics systems
	dodir /usr/share/qt4/graphicssystems
	echo "default" > "${ED}"/usr/share/qt4/graphicssystems/raster || die
	touch "${ED}"/usr/share/qt4/graphicssystems/native || die

	doicon tools/designer/src/designer/images/designer.png
	newicon tools/linguist/linguist/images/icons/linguist-128-32.png linguist.png
	newicon tools/qtconfig/images/appicon.png qtconfig.png
	use dbus && newicon tools/qdbus/qdbusviewer/images/qdbusviewer-128.png qdbusviewer.png
	make_desktop_entry designer Designer designer 'Qt;Development;GUIDesigner'
	make_desktop_entry linguist Linguist linguist 'Qt;Development;Translation'
	make_desktop_entry qtconfig 'Qt Configuration Tool' qtconfig 'Qt;Settings;DesktopSettings'
}

pkg_postinst() {
	qt4-build_pkg_postinst

	# raster is the default graphicssystem, set it on first install
	eselect qtgraphicssystem set raster --use-old

	if use gtkstyle; then
		# see bug 388551
		elog "For Qt's GTK style to work, you need to either export"
		elog "the following variable into your environment:"
		elog '  GTK2_RC_FILES="$HOME/.gtkrc-2.0"'
		elog "or alternatively install gnome-base/libgnomeui"
	fi
}
