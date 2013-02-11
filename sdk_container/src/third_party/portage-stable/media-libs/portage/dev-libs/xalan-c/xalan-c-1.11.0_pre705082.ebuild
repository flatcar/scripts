# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/xalan-c/xalan-c-1.11.0_pre705082.ebuild,v 1.4 2011/12/18 17:26:24 armin76 Exp $

inherit toolchain-funcs eutils flag-o-matic multilib

DESCRIPTION="XSLT processor for transforming XML into HTML, text, or other XML types"
HOMEPAGE="http://xml.apache.org/xalan-c/"
SRC_URI="mirror://gentoo/Xalan-C_r${PV#*_pre}-src.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 ~ppc x86"
IUSE="doc"

RDEPEND=">=dev-libs/xerces-c-2.7.0"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )"

S="${WORKDIR}"/xml-xalan/c

src_unpack() {
	unpack ${A}
	cd "${S}"

	sed -i \
		-e 's/\(debugflag\)="-O.\? /\1="/' \
		-e 's/^\(CXXFLAGS\)="$compileroptions/\1="${\1}/' \
		-e 's/^\(CFLAGS\)="$compileroptions/\1="${\1}/' \
		runConfigure || die "sed failed"

}

src_compile() {
	export XALANCROOT=${S}
	export XERCESCROOT="/usr/include/xercesc"
	append-ldflags -pthread

	./runConfigure -p linux -c "$(tc-getCC)" -x "$(tc-getCXX)" -P /usr -C --libdir=/usr/$(get_libdir) || die "configure failed"
	emake -j1 || die "emake failed"

	if use doc ; then
		mkdir build
		cd "${S}/xdocs"
		doxygen DoxyfileXalan
	fi
}

src_install() {
	export XALANCROOT=${S}
	emake DESTDIR="${D}" install || die "emake install failed"

	dodoc README version.incl
	dohtml readme.html
	if use doc ; then
		dodir /usr/share/doc/${PF}
		cp -r "${S}/samples" "${D}/usr/share/doc/${PF}"
		find "${D}/usr/share/doc/${PF}" -type d -name CVS -exec rm -rf '{}' \; >& /dev/null
		dohtml -r build/docs/apiDocs
	fi
}
