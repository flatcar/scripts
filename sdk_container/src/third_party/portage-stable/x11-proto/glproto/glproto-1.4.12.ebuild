# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-proto/glproto/glproto-1.4.12.ebuild,v 1.9 2011/02/14 14:34:03 xarthisius Exp $

EAPI=3
inherit xorg-2

OPENGL_DIR="xorg-x11"

DESCRIPTION="X.Org GL protocol headers"

KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd ~x64-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
LICENSE="SGI-B-2.0"
IUSE=""

RDEPEND="app-admin/eselect-opengl"
DEPEND=""

src_install() {
	xorg-2_src_install
	dynamic_libgl_install
}

pkg_postinst() {
	xorg-2_pkg_postinst
	switch_opengl_implem
}

dynamic_libgl_install() {
	# next section is to setup the dynamic libGL stuff
	ebegin "Moving GL files for dynamic switching"
		dodir /usr/$(get_libdir)/opengl/${OPENGL_DIR}/include
		local x=""
		# glext.h added for #54984
		for x in "${ED}"/usr/include/GL/{glxtokens.h,glxmd.h,glxproto.h}; do
			if [[ -f ${x} || -L ${x} ]]; then
				mv -f "${x}" "${ED}"/usr/$(get_libdir)/opengl/${OPENGL_DIR}/include
			fi
		done
	eend 0
}

switch_opengl_implem() {
	# Switch to the xorg implementation.
	# Use new opengl-update that will not reset user selected
	# OpenGL interface ...
	echo
	eselect opengl set --use-old ${OPENGL_DIR}
}
