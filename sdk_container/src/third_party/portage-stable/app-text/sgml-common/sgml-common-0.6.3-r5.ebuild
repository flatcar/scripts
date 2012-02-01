# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-text/sgml-common/sgml-common-0.6.3-r5.ebuild,v 1.19 2009/07/19 11:18:02 ssuominen Exp $

inherit autotools eutils

DESCRIPTION="Base ISO character entities and utilities for SGML"
HOMEPAGE="http://www.iso.ch/cate/3524030.html"
SRC_URI="mirror://kde/devel/docbook/SOURCES/${P}.tgz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc ~sparc-fbsd x86 ~x86-fbsd"
IUSE=""

RDEPEND=""
DEPEND=""

src_unpack() {
	unpack ${A}

	# We use a hacked version of install-catalog that supports the ROOT
	# variable, and puts quotes around the CATALOG files.
	cp "${FILESDIR}/${P}-install-catalog.in" "${S}/bin/install-catalog.in"
	cd "${S}"

	epatch "${FILESDIR}"/${P}-configure.in.patch
	epatch "${FILESDIR}"/${P}-man_MANS.patch

	eautoreconf
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
}

pkg_postinst() {
	local installer="${ROOT}usr/bin/install-catalog"
	if [ ! -x "${installer}" ]; then
		eerror "install-catalog not found! Something went wrong!"
		die
	fi

	einfo "Installing Catalogs..."
	$installer --add \
		/etc/sgml/sgml-ent.cat \
		/usr/share/sgml/sgml-iso-entities-8879.1986/catalog
	$installer --add \
		/etc/sgml/sgml-docbook.cat \
		/etc/sgml/sgml-ent.cat

	local file
	for file in `find "${ROOT}etc/sgml/" -name "*.cat"` "${ROOT}etc/sgml/catalog"
	do
		einfo "Fixing ${file}"
		awk '/"$/ { print $1 " " $2 }
			! /"$/ { print $1 " \"" $2 "\"" }' ${file} > ${file}.new
		mv ${file}.new ${file}
	done
}

pkg_prerm() {
	cp "${ROOT}usr/bin/install-catalog" "${T}"
}

pkg_postrm() {
	if [ ! -x  "${T}/install-catalog" ]; then
		return
	fi

	einfo "Removing Catalogs..."
	if [ -e "${ROOT}etc/sgml/sgml-ent.cat" ]; then
		"${T}"/install-catalog --remove \
			/etc/sgml/sgml-ent.cat \
			/usr/share/sgml/sgml-iso-entities-8879.1986/catalog
	fi

	if [ -e "${ROOT}etc/sgml/sgml-docbook.cat" ]; then
		"${T}"/install-catalog --remove \
			/etc/sgml/sgml-docbook.cat \
			/etc/sgml/sgml-ent.cat
	fi
}
