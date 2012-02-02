# Copyright 1999-2004 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/gst-plugins-good.eclass,v 1.18 2009/05/16 22:08:09 tester Exp $

# Author : foser <foser@gentoo.org>, zaheerm <zaheerm@gentoo.org>

# gst-plugins-good eclass
#
# eclass to make external gst-plugins emergable on a per-plugin basis
# to solve the problem with gst-plugins generating far too much unneeded deps
#
# 3rd party applications using gstreamer now should depend on a set of plugins as
# defined in the source, obtain recommended plugins to use from
# Gentoo developers responsible for gstreamer <gnome@gentoo.org>, the application developer
# or the gstreamer team.

inherit eutils gst-plugins10


###
# variable declarations
###

MY_PN=gst-plugins-good
MY_P=${MY_PN}-${PV}
# All relevant configure options for gst-plugins
# need a better way to extract these
# gst-plugins-base 0.9

# This list is current to gst-plugins-good-0.10.6
my_gst_plugins_good="gconf gconftool oss aalib aalibtest cairo cdio esd esdtest
flac jpeg ladspa libcaca libdv libpng dv1394 shout2 shout2test speex annodex hal
x taglib gdk_pixbuf gst_v4l2 sunaudio xshm xvideo zlib wavpack soup pulse bz2"

#SRC_URI="mirror://gnome/sources/gst-plugins/${PV_MAJ_MIN}/${MY_P}.tar.bz2"
SRC_URI="http://gstreamer.freedesktop.org/src/gst-plugins-good/${MY_P}.tar.bz2"

S=${WORKDIR}/${MY_P}
# added to remove circular deps
# 6/2/2006 - zaheerm
if [ "${PN}" != "${MY_PN}" ]; then
RDEPEND="=media-libs/gst-plugins-base-0.10*"
DEPEND="${RDEPEND}
	>=sys-apps/sed-4
	dev-util/pkgconfig"
RESTRICT=test
fi

###
# public functions
###

gst-plugins-good_src_configure() {

	# disable any external plugin besides the plugin we want
	local plugin gst_conf

	einfo "Configuring to build ${GST_PLUGINS_BUILD} plugin(s) ..."

	for plugin in ${GST_PLUGINS_BUILD}; do
		my_gst_plugins_good=${my_gst_plugins_good/${plugin}/}
	done
	for plugin in ${my_gst_plugins_good}; do
		gst_conf="${gst_conf} --disable-${plugin} "
	done
	for plugin in ${GST_PLUGINS_BUILD}; do
		gst_conf="${gst_conf} --enable-${plugin} "
	done

	cd ${S}
	econf ${@} --with-package-name="Gentoo GStreamer Ebuild" --with-package-origin="http://www.gentoo.org" ${gst_conf} || die "./configure failure"

}

###
# public inheritable functions
###

gst-plugins-good_src_unpack() {

#	local makefiles

	unpack ${A}

	# Link with the syswide installed gst-libs if needed
#	gst-plugins10_find_plugin_dir
#	cd ${S}

	# Remove generation of any other Makefiles except the plugin's Makefile
#	if [ -d "${S}/sys/${GST_PLUGINS_BUILD_DIR}" ]; then
#		makefiles="Makefile sys/Makefile sys/${GST_PLUGINS_BUILD_DIR}/Makefile"
#	elif [ -d "${S}/ext/${GST_PLUGINS_BUILD_DIR}" ]; then
#		makefiles="Makefile ext/Makefile ext/${GST_PLUGINS_BUILD_DIR}/Makefile"
#	fi
#	sed -e "s:ac_config_files=.*:ac_config_files='${makefiles}':" \
#		-i ${S}/configure

}

gst-plugins-good_src_compile() {

	gst-plugins-good_src_configure ${@}

	gst-plugins10_find_plugin_dir
	emake || die "compile failure"

}

gst-plugins-good_src_install() {

	gst-plugins10_find_plugin_dir
	einstall || die

	[[ -e README ]] && dodoc README
}

EXPORT_FUNCTIONS src_unpack src_compile src_install
