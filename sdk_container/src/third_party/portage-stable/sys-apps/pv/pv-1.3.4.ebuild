# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/pv/pv-1.3.4.ebuild,v 1.8 2012/08/26 17:34:41 armin76 Exp $

EAPI="4"

inherit toolchain-funcs

DESCRIPTION="Pipe Viewer: a tool for monitoring the progress of data through a pipe"
HOMEPAGE="http://www.ivarch.com/programs/pv.shtml"
SRC_URI="http://www.ivarch.com/programs/sources/${P}.tar.gz"

LICENSE="Artistic-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ~mips ppc ppc64 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc64-solaris ~x86-solaris"

IUSE="nls"
PV_LINGUAS="de fr pl pt"
for lingua in ${PV_LINGUAS}; do
	IUSE+=" linguas_${lingua}"
done

DOCS=( README doc/NEWS doc/TODO )

src_configure() {
	local lingua
	for lingua in ${PV_LINGUAS}; do
		if ! use linguas_${lingua}; then
			sed -i configure -e "/ALL_LINGUAS=/s:${lingua}::g" || die
		fi
	done
	econf $(use_enable nls)
}

src_compile() {
	emake LD="$(tc-getLD)"
}
