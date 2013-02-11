# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/qt-demo/qt-demo-4.8.4.ebuild,v 1.5 2012/12/25 09:53:14 ago Exp $

EAPI=4

inherit qt4-build

DESCRIPTION="Demonstration module and examples for the Qt toolkit"
SLOT="4"
if [[ ${QT4_BUILD_TYPE} == live ]]; then
	KEYWORDS=""
else
	KEYWORDS="amd64 ppc ppc64 x86 ~x64-macos"
fi
IUSE="dbus declarative kde multimedia opengl openvg qt3support webkit xmlpatterns"

DEPEND="
	~x11-libs/qt-assistant-${PV}:4[aqua=,debug=]
	~x11-libs/qt-core-${PV}:4[aqua=,debug=,qt3support?]
	~x11-libs/qt-gui-${PV}:4[aqua=,debug=,qt3support?]
	~x11-libs/qt-script-${PV}:4[aqua=,debug=]
	~x11-libs/qt-sql-${PV}:4[aqua=,debug=,qt3support?]
	~x11-libs/qt-svg-${PV}:4[aqua=,debug=]
	~x11-libs/qt-test-${PV}:4[aqua=,debug=]
	dbus? ( ~x11-libs/qt-dbus-${PV}:4[aqua=,debug=] )
	declarative? ( ~x11-libs/qt-declarative-${PV}:4[aqua=,debug=,webkit?] )
	kde? ( media-libs/phonon[aqua=] )
	!kde? ( || (
		~x11-libs/qt-phonon-${PV}:4[aqua=,debug=]
		media-libs/phonon[aqua=]
	) )
	multimedia? ( ~x11-libs/qt-multimedia-${PV}:4[aqua=,debug=] )
	opengl? ( ~x11-libs/qt-opengl-${PV}:4[aqua=,debug=,qt3support?] )
	openvg? ( ~x11-libs/qt-openvg-${PV}:4[aqua=,debug=,qt3support?] )
	qt3support? ( ~x11-libs/qt-qt3support-${PV}:4[aqua=,debug=] )
	webkit? ( ~x11-libs/qt-webkit-${PV}:4[aqua=,debug=] )
	xmlpatterns? ( ~x11-libs/qt-xmlpatterns-${PV}:4[aqua=,debug=] )
"
RDEPEND="${DEPEND}"

PATCHES=(
	"${FILESDIR}/${PN}-4.6-plugandpaint.patch"
)

pkg_setup() {
	QT4_TARGET_DIRECTORIES="
		demos
		examples"
	QT4_EXTRACT_DIRECTORIES="${QT4_TARGET_DIRECTORIES}
		doc/src/images
		src
		include
		tools"

	qt4-build_pkg_setup
}

src_prepare() {
	qt4-build_src_prepare

	# Array mapping USE flags to subdirs
	local flags_subdirs_map=(
		'dbus'
		'declarative:declarative'
		'multimedia:spectrum'
		'opengl:boxes|glhypnotizer'
		'openvg'
		'webkit:browser'
		'xmlpatterns'
	)

	# Disable unwanted examples/demos
	for flag in "${flags_subdirs_map[@]}"; do
		if ! use ${flag%:*}; then
			einfo "Disabling ${flag%:*} examples"
			sed -i -e "/SUBDIRS += ${flag%:*}/d" \
				examples/examples.pro || die

			if [[ ${flag} == *:* ]]; then
				einfo "Disabling ${flag%:*} demos"
				sed -i -re "/SUBDIRS \+= demos_(${flag#*:})/d" \
					demos/demos.pro || die
			fi
		fi
	done

	if ! use qt3support; then
		einfo "Disabling qt3support examples"
		sed -i -e '/QT_CONFIG, qt3support/d' \
			examples/graphicsview/graphicsview.pro || die
	fi
}

src_configure() {
	myconf+="
		$(qt_use dbus)
		$(qt_use declarative)
		$(qt_use multimedia)
		$(qt_use opengl)
		$(qt_use openvg)
		$(qt_use qt3support)
		$(qt_use webkit)
		$(qt_use xmlpatterns)"

	qt4-build_src_configure
}

src_install() {
	insinto "${QTDOCDIR#${EPREFIX}}"/src
	doins -r doc/src/images

	qt4-build_src_install
}
