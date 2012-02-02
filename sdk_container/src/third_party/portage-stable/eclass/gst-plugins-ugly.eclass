# Copyright 1999-2004 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/gst-plugins-ugly.eclass,v 1.17 2009/11/16 06:04:12 leio Exp $

# Author : foser <foser@gentoo.org>

# gst-plugins-ugly eclass
#
# eclass to make external gst-plugins emergable on a per-plugin basis
# to solve the problem with gst-plugins generating far too much unneeded deps
#
# 3rd party applications using gstreamer now should depend on a set of plugins as
# defined in the source, in case of spider usage obtain recommended plugins to use from
# Gentoo developers responsible for gstreamer <gnome@gentoo.org>, the application developer
# or the gstreamer team.

inherit eutils gst-plugins10


###
# variable declarations
###

MY_PN=gst-plugins-ugly
MY_P=${MY_PN}-${PV}
# All relevant configure options for gst-plugins-ugly
# need a better way to extract these.
# Not necessary since -ugly-0.10.13: id3tag dvdnav
my_gst_plugins_ugly="a52dec amrnb amrwb cdio dvdread dvdnav lame id3tag mad
mpeg2dec sidplay twolame x264"

#SRC_URI="mirror://gnome/sources/gst-plugins/${PV_MAJ_MIN}/${MY_P}.tar.bz2"
SRC_URI="http://gstreamer.freedesktop.org/src/gst-plugins-ugly/${MY_P}.tar.bz2"

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

gst-plugins-ugly_src_configure() {

	# disable any external plugin besides the plugin we want
	local plugin gst_conf

	einfo "Configuring to build ${GST_PLUGINS_BUILD} plugin(s) ..."

	for plugin in ${GST_PLUGINS_BUILD}; do
		my_gst_plugins_ugly=${my_gst_plugins_ugly/${plugin}/}
	done
	for plugin in ${my_gst_plugins_ugly}; do
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

gst-plugins-ugly_src_unpack() {

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

gst-plugins-ugly_src_compile() {

	gst-plugins-ugly_src_configure ${@}

	gst-plugins10_find_plugin_dir
	emake || die "compile failure"

}

gst-plugins-ugly_src_install() {

	gst-plugins10_find_plugin_dir
	einstall || die

	[[ -e README ]] && dodoc README
}


EXPORT_FUNCTIONS src_unpack src_compile src_install
