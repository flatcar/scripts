# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/qt-assistant/qt-assistant-4.8.4.ebuild,v 1.9 2012/12/29 08:44:59 ago Exp $

EAPI=4

inherit eutils qt4-build

DESCRIPTION="The Help module and Assistant application for the Qt toolkit"
SRC_URI+="
	compat? (
		ftp://ftp.qt.nokia.com/qt/source/${PN}-qassistantclient-library-compat-src-4.6.3.tar.gz
		http://dev.gentoo.org/~pesa/distfiles/${PN}-compat-headers-4.7.tar.gz
	)"

SLOT="4"
if [[ ${QT4_BUILD_TYPE} == live ]]; then
	KEYWORDS=""
else
	KEYWORDS="alpha amd64 arm ia64 ppc ppc64 sparc x86 ~ppc-macos ~x64-macos"
fi
IUSE="compat doc +glib qt3support trace webkit"

DEPEND="
	~x11-libs/qt-gui-${PV}[aqua=,debug=,glib=,qt3support=,trace?]
	~x11-libs/qt-sql-${PV}[aqua=,debug=,qt3support=,sqlite]
	webkit? ( ~x11-libs/qt-webkit-${PV}[aqua=,debug=] )
"
RDEPEND="${DEPEND}"

PATCHES=(
	"${FILESDIR}/${PN}-4.8.2+gcc-4.7.patch"
)

pkg_setup() {
	# Pixeltool isn't really assistant related, but it relies on
	# the assistant libraries.
	QT4_TARGET_DIRECTORIES="
		tools/assistant
		tools/pixeltool
		tools/qdoc3"
	QT4_EXTRACT_DIRECTORIES="
		tools
		demos
		examples
		src
		include
		doc"

	use trace && QT4_TARGET_DIRECTORIES+=" tools/qttracereplay"

	QT4_EXTRACT_DIRECTORIES="${QT4_TARGET_DIRECTORIES}
		${QT4_EXTRACT_DIRECTORIES}"

	qt4-build_pkg_setup
}

src_unpack() {
	qt4-build_src_unpack

	# compat version
	# http://labs.qt.nokia.com/2010/06/22/qt-assistant-compat-version-available-as-extra-source-package/
	if use compat; then
		unpack ${PN}-qassistantclient-library-compat-src-4.6.3.tar.gz \
			${PN}-compat-headers-4.7.tar.gz
		mv "${WORKDIR}"/${PN}-qassistantclient-library-compat-version-4.6.3 \
			"${S}"/tools/assistant/compat || die
		mv "${WORKDIR}"/QtAssistant "${S}"/include/ || die
	fi
}

src_prepare() {
	qt4-build_src_prepare

	use compat && epatch "${FILESDIR}"/${PN}-4.7-fix-compat.patch

	# bug 401173
	use webkit || epatch "${FILESDIR}"/disable-webkit.patch

	# bug 348034
	sed -i -e '/^sub-qdoc3\.depends/d' doc/doc.pri || die
}

src_configure() {
	myconf+="
		-no-xkb -no-fontconfig -no-xrandr
		-no-xfixes -no-xcursor -no-xinerama -no-xshape -no-sm -no-opengl
		-no-nas-sound -no-dbus -iconv -no-cups -no-nis -no-gif -no-libpng
		-no-libmng -no-libjpeg -no-openssl -system-zlib -no-phonon
		-no-xmlpatterns -no-freetype -no-libtiff -no-accessibility
		-no-fontconfig -no-multimedia -no-svg
		$(qt_use qt3support) $(qt_use webkit)"
	use glib || myconf+=" -no-glib"

	qt4-build_src_configure
}

src_compile() {
	# help libQtHelp find freshly built libQtCLucene (bug #289811)
	export LD_LIBRARY_PATH="${S}/lib:${QTLIBDIR}"
	export DYLD_LIBRARY_PATH="${S}/lib:${S}/lib/QtHelp.framework"

	qt4-build_src_compile

	# ugly hack to build docs
	qmake "LIBS+=-L${QTLIBDIR}" "CONFIG+=nostrip" projects.pro || die

	if use doc; then
		emake docs
	elif [[ ${QT4_BUILD_TYPE} == release ]]; then
		# live ebuild cannot build qch_docs, it will build them through emake docs
		emake qch_docs
	fi
}

src_install() {
	qt4-build_src_install

	emake INSTALL_ROOT="${D}" install_qchdocs
	# do not compress .qch files
	docompress -x "${QTDOCDIR}"/qch

	if use doc; then
		emake INSTALL_ROOT="${D}" install_htmldocs
	fi

	doicon tools/assistant/tools/assistant/images/assistant.png
	make_desktop_entry assistant Assistant assistant 'Qt;Development'

	if use compat; then
		insinto /usr/share/qt4/mkspecs/features
		doins tools/assistant/compat/features/assistant.prf
	fi
}
