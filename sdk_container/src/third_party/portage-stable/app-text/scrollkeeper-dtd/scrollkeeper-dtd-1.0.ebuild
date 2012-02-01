# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-text/scrollkeeper-dtd/scrollkeeper-dtd-1.0.ebuild,v 1.2 2009/02/18 23:53:36 eva Exp $

DTD_FILE="scrollkeeper-omf.dtd"

DESCRIPTION="DTD from the Scrollkeeper package"
HOMEPAGE="http://scrollkeeper.sourceforge.net/"
SRC_URI="http://scrollkeeper.sourceforge.net/dtds/scrollkeeper-omf-1.0/${DTD_FILE}"

LICENSE="FDL-1.1"
SLOT="1.0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k mips ppc ppc64 s390 sh sparc ~sparc-fbsd x86 ~x86-fbsd"
IUSE=""

RDEPEND=">=dev-libs/libxml2-2.4.19"
DEPEND="${RDEPEND}
	!<app-text/scrollkeeper-9999-r1"

src_unpack() { :; }

src_compile() { :; }

src_install() {
	insinto "/usr/share/xml/scrollkeeper/dtds"
	doins "${DISTDIR}/${DTD_FILE}"
}

pkg_postinst() {
	einfo "Installing catalog..."

	# Install regular DOCTYPE catalog entry
	"${ROOT}"/usr/bin/xmlcatalog --noout --add "public" \
		"-//OMF//DTD Scrollkeeper OMF Variant V1.0//EN" \
		"`echo "${ROOT}/usr/share/xml/scrollkeeper/dtds/${DTD_FILE}" | sed -e "s://:/:g"`" \
		"${ROOT}"/etc/xml/catalog

	# Install catalog entry for calls like: xmllint --dtdvalid URL ...
	"${ROOT}"/usr/bin/xmlcatalog --noout --add "system" \
		"${SRC_URI}" \
		"`echo "${ROOT}/usr/share/xml/scrollkeeper/dtds/${DTD_FILE}" | sed -e "s://:/:g"`" \
		"${ROOT}"/etc/xml/catalog
}

pkg_postrm() {
	# Remove all sk-dtd from the cache
	einfo "Cleaning catalog..."

	"${ROOT}"/usr/bin/xmlcatalog --noout --del \
		"`echo "${ROOT}/usr/share/xml/scrollkeeper/dtds/${DTD_FILE}" | sed -e "s://:/:g"`" \
		"${ROOT}"/etc/xml/catalog
}
