# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/emul-linux-x86.eclass,v 1.5 2010/02/22 20:52:52 pacho Exp $

#
# Original Author: Mike Doty <kingtaco@gentoo.org>
# Adapted from emul-libs.eclass
# Purpose: Providing a template for the app-emulation/emul-linux-* packages
#

EXPORT_FUNCTIONS src_unpack src_install

SRC_URI="mirror://gentoo/${PN}-${PV}.tar.bz2"

DESCRIPTION="Provides precompiled 32bit libraries"
#HOMEPAGE="http://amd64.gentoo.org/emul/content.xml"
HOMEPAGE="http://dev.gentoo.org/~pacho/emul.html"

RESTRICT="strip"
S=${WORKDIR}

SLOT="0"
IUSE=""

DEPEND=">=sys-apps/findutils-4.2.26"
RDEPEND=""

emul-linux-x86_src_unpack() {
	unpack ${A}
	cd "${S}"

	ALLOWED=${ALLOWED:-^${S}/etc/env.d}
	find "${S}" ! -type d ! -name '*.so*' | egrep -v "${ALLOWED}" | xargs -d $'\n' rm -f || die 'failed to remove everything but *.so*'
}

emul-linux-x86_src_install() {
	for dir in etc/env.d etc/revdep-rebuild ; do
		if [[ -d "${S}"/${dir} ]] ; then
			for f in "${S}"/${dir}/* ; do
				mv -f "$f"{,-emul}
			done
		fi
	done

	# remove void directories
	find "${S}" -depth -type d -print0 | xargs -0 rmdir 2&>/dev/null

	cp -pPR "${S}"/* "${D}"/ || die "copying files failed!"
}
