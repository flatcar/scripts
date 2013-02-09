# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/phonon/phonon-4.6.0-r1.ebuild,v 1.17 2012/12/30 16:30:09 armin76 Exp $

EAPI=4

if [[ ${PV} != *9999* ]]; then
	SRC_URI="mirror://kde/stable/phonon/${PV}/src/${P}.tar.xz"
	KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 sparc x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos"
else
	SCM_ECLASS="git-2"
	EGIT_REPO_URI="git://anongit.kde.org/${PN}"
	KEYWORDS=""
fi

inherit cmake-utils ${SCM_ECLASS}

DESCRIPTION="KDE multimedia API"
HOMEPAGE="https://projects.kde.org/projects/kdesupport/phonon"

LICENSE="LGPL-2.1"
SLOT="0"
IUSE="aqua debug +gstreamer pulseaudio vlc zeitgeist"

COMMON_DEPEND="
	!!x11-libs/qt-phonon:4
	>=x11-libs/qt-core-4.6.0:4
	>=x11-libs/qt-dbus-4.6.0:4
	>=x11-libs/qt-gui-4.6.0:4
	>=x11-libs/qt-test-4.6.0:4
	pulseaudio? (
		dev-libs/glib:2
		>=media-sound/pulseaudio-0.9.21[glib]
	)
	zeitgeist? ( dev-libs/libqzeitgeist )
"
# directshow? ( media-sound/phonon-directshow )
# mmf? ( media-sound/phonon-mmf )
# mplayer? ( media-sound/phonon-mplayer )
# waveout? ( media-sound/phonon-waveout )
PDEPEND="
	aqua? ( media-libs/phonon-qt7 )
	gstreamer? ( media-libs/phonon-gstreamer )
	vlc? ( >=media-libs/phonon-vlc-0.3.2 )
"
RDEPEND="${COMMON_DEPEND}"
DEPEND="${COMMON_DEPEND}
	>=dev-util/automoc-0.9.87
	virtual/pkgconfig
"

REQUIRED_USE="|| ( aqua gstreamer vlc )"

PATCHES=(
	"${FILESDIR}/${PN}-4.5.1-qmakeworkaround.patch"
	"${FILESDIR}/${PN}-4.6.0-rpath.patch"
)

src_configure() {
	local mycmakeargs=(
		$(cmake-utils_use_with pulseaudio GLIB2)
		$(cmake-utils_use_with pulseaudio PulseAudio)
	)
	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install
	# fixup broken cmake system library installs
	if [[ ${CHOST} == *-darwin* ]] ; then
		local lib
		for lib in "${EPREFIX}"/usr/lib/libphonon{.4,experimental.4.6.0}.dylib ; do
			install_name_tool -id "${lib}" "${D}${lib}"
		done
		for lib in /usr/lib/libphononexperimental.4.dylib \
			/usr/lib/qt4/plugins/designer/libphononwidgets.bundle ;
		do
			install_name_tool -change \
				"lib/libphonon.4.dylib" \
				"${EPREFIX}/usr/lib/libphonon.4.dylib" \
				${ED}${lib}
		done
	fi
}
