# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/gst-plugins-bad.eclass,v 1.24 2009/11/09 02:43:05 leio Exp $

#
# Original Author: Saleem Abdulrasool <compnerd@gentoo.org>
# Based on the work of foser <foser@gentoo.org> and zaheerm <zaheerm@gentoo.org>
# Purpose: This elcass is designed to help package external gst-plugins per
# plugin rather than in a single package.
#

# This list is current to gst-plugins-bad-0.10.4 except for:
#   gst_v4l2 - moved to gst-plugins-bad-0.10.5 (not in >=gst-plugins-bad-0.10.4)
#              But it must stay in this list until all <gst-plugins-bad-0.10.4
#              are removed
# drac at gentoo.org:
# This list is current to gst-plugins-bad-0.10.5 except for:
#   Not present in 0.10.5 - wavpack
# This list is current for gst-plugins-bad-0.10.14 and is only getting entries
# added to it, and never removed for longer backwards compatibility.
my_gst_plugins_bad="alsa amrwb apexsink assrender bz2 cdaudio celt dc1394 dirac
directfb divx dts dvb dvdnav faac faad fbdev gme gsm gst_v4l2 ivorbis jack jp2k
kate ladspa libmms lv2 metadata mimic modplug mpeg2enc mplex musepack
musicbrainz mythtv nas neon ofa opengl oss4 quicktime schro sdl sdltest sndfile
soundtouch soup spc swfdec theoradec timidity twolame vcd vdpau wavpack wildmidi
x x264 xvid"

#qtdemux spped tta

inherit eutils gst-plugins10

MY_PN="gst-plugins-bad"
MY_P=${MY_PN}-${PV}

SRC_URI="http://gstreamer.freedesktop.org/src/gst-plugins-bad/${MY_P}.tar.bz2"
if [ ${PV} == "0.10.14" ]; then
	SRC_URI="${SRC_URI} http://dev.gentoo.org/~leio/distfiles/gst-plugins-bad-0.10.14-kate-configure-fix.patch.bz2"
fi

# added to remove circular deps
# 6/2/2006 - zaheerm
if [ "${PN}" != "${MY_PN}" ]; then
RDEPEND="=media-libs/gstreamer-0.10*
		=media-libs/gst-plugins-base-0.10*
		>=dev-libs/glib-2.6
		>=dev-libs/liboil-0.3"
DEPEND="${RDEPEND}
		sys-apps/sed
		dev-util/pkgconfig
		sys-devel/gettext"
RESTRICT=test
fi
S=${WORKDIR}/${MY_P}

gst-plugins-bad_src_unpack() {
#	local makefiles

	unpack ${A}

	# Link with the syswide installed gst-libs if needed
	gst-plugins10_find_plugin_dir
	sed -e "s:\$(top_builddir)/gst-libs/gst/interfaces/libgstphotography:${ROOT}/usr/$(get_libdir)/libgstphotography:" \
		-e "s:\$(top_builddir)/gst-libs/gst/signalprocessor/libgstsignalprocessor:${ROOT}/usr/$(get_libdir)/libgstsignalprocessor:" \
		-e "s:\$(top_builddir)/gst-libs/gst/video/libgstbasevideo:${ROOT}/usr/$(get_libdir)/libgstbasevideo:" \
		-i Makefile.in

	# 0.10.14 configure errors when --disable-kate is passed:
	# configure: error: conditional "USE_TIGER" was never defined.
	# Fix it - this has to stay until any 0.10.14 split or main is in tree:
	if [ ${PV} == "0.10.14" ]; then
		cd ${S}
		epatch "${WORKDIR}/gst-plugins-bad-0.10.14-kate-configure-fix.patch"
	fi

	# Remove generation of any other Makefiles except the plugin's Makefile
#	if [[ -d "${S}/sys/${GST_PLUGINS_BUILD_DIR}" ]] ; then
#		makefiles="Makefile sys/Makefile sys/${GST_PLUGINS_BUILD_DIR}/Makefile"
#	elif [[ -d "${S}/ext/${GST_PLUGINS_BUILD_DIR}" ]] ; then
#		makefiles="Makefile ext/Makefile ext/${GST_PLUGINS_BUILD_DIR}/Makefile"
#	fi

#	sed -e "s:ac_config_files=.*:ac_config_files='${makefiles}':" \
#		-i ${S}/configure
}

gst-plugins-bad_src_configure() {
	local plugin gst_conf

	einfo "Configuring to build ${GST_PLUGINS_BUILD} plugin(s) ..."

	for plugin in ${GST_PLUGINS_BUILD} ; do
		my_gst_plugins_bad="${my_gst_plugins_bad/${plugin}/}"
	done

	for plugin in ${my_gst_plugins_bad} ; do
		gst_conf="${gst_conf} --disable-${plugin}"
	done

	for plugin in ${GST_PLUGINS_BUILD} ; do
		gst_conf="${gst_conf} --enable-${plugin}"
	done

	cd ${S}
	econf ${@} --with-package-name="Gentoo GStreamer Ebuild" --with-package-origin="http://www.gentoo.org" ${gst_conf} || die "configure failed"
}

gst-plugins-bad_src_compile() {
	gst-plugins-bad_src_configure ${@}

	gst-plugins10_find_plugin_dir
	emake || die "compile failure"
}

gst-plugins-bad_src_install() {
	gst-plugins10_find_plugin_dir
	einstall || die "install failed"

	[[ -e README ]] && dodoc README
}

EXPORT_FUNCTIONS src_unpack src_compile src_install
