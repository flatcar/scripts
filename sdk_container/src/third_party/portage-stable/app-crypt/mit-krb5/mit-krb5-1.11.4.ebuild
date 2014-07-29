# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-crypt/mit-krb5/mit-krb5-1.11.4.ebuild,v 1.12 2014/07/14 18:51:41 tgall Exp $

EAPI=5

PYTHON_COMPAT=( python{2_6,2_7} )
inherit eutils flag-o-matic python-any-r1 versionator

MY_P="${P/mit-}"
P_DIR=$(get_version_component_range 1-2)
DESCRIPTION="MIT Kerberos V"
HOMEPAGE="http://web.mit.edu/kerberos/www/"
SRC_URI="http://web.mit.edu/kerberos/dist/krb5/${P_DIR}/${MY_P}-signed.tar"

LICENSE="openafs-krb5-a BSD MIT OPENLDAP BSD-2 HPND BSD-4 ISC RSA CC-BY-SA-3.0 || ( BSD-2 GPL-2+ )"
SLOT="0"
KEYWORDS="alpha amd64 arm arm64 hppa ia64 ~mips ppc ppc64 ~s390 ~sh sparc x86"
IUSE="doc +keyutils openldap +pkinit selinux +threads test xinetd"

RDEPEND="!!app-crypt/heimdal
	>=sys-libs/e2fsprogs-libs-1.41.0
	|| ( dev-libs/libverto[libev] dev-libs/libverto[libevent] dev-libs/libverto[tevent] )
	keyutils? ( sys-apps/keyutils )
	openldap? ( net-nds/openldap )
	pkinit? ( dev-libs/openssl )
	selinux? ( sec-policy/selinux-kerberos )
	xinetd? ( sys-apps/xinetd )"
DEPEND="${RDEPEND}
	${PYTHON_DEPS}
	virtual/yacc
	doc? ( virtual/latex-base )
	test? ( ${PYTHON_DEPS}
			dev-lang/tcl
			dev-util/dejagnu )"

S=${WORKDIR}/${MY_P}/src

src_unpack() {
	unpack ${A}
	unpack ./"${MY_P}".tar.gz
}

src_prepare() {
	epatch "${FILESDIR}/${PN}-1.11_uninitialized.patch"
	epatch "${FILESDIR}/${PN}_krb5-config_LDFLAGS.patch"

	# tcl-8.6 compatibility
	sed -i -e 's/interp->result/Tcl_GetStringResult(interp)/' \
		kadmin/testing/util/tcl_kadm5.c || die
}

src_configure() {
	append-cppflags "-I${EPREFIX}/usr/include/et"
	# QA
	append-flags -fno-strict-aliasing
	append-flags -fno-strict-overflow

	use keyutils || export ac_cv_header_keyutils_h=no
	econf \
		$(use_with openldap ldap) \
		"$(use_with test tcl "${EPREFIX}/usr")" \
		$(use_enable pkinit) \
		$(use_enable threads thread-support) \
		--without-hesiod \
		--enable-shared \
		--with-system-et \
		--with-system-ss \
		--enable-dns-for-realm \
		--enable-kdc-lookaside-cache \
		--with-system-verto \
		--disable-rpath
}

src_compile() {
	emake -j1
}

src_test() {
	emake -j1 check
}

src_install() {
	emake \
		DESTDIR="${D}" \
		EXAMPLEDIR="${EPREFIX}/usr/share/doc/${PF}/examples" \
		install

	# default database dir
	keepdir /var/lib/krb5kdc

	cd ..
	dodoc README

	if use doc; then
		dohtml -r doc/html/*
		docinto pdf
		dodoc doc/pdf/*.pdf
	fi

	newinitd "${FILESDIR}"/mit-krb5kadmind.initd-r1 mit-krb5kadmind
	newinitd "${FILESDIR}"/mit-krb5kdc.initd-r1 mit-krb5kdc
	newinitd "${FILESDIR}"/mit-krb5kpropd.initd-r1 mit-krb5kpropd

	insinto /etc
	newins "${ED}/usr/share/doc/${PF}/examples/krb5.conf" krb5.conf.example
	insinto /var/lib/krb5kdc
	newins "${ED}/usr/share/doc/${PF}/examples/kdc.conf" kdc.conf.example

	if use openldap ; then
		insinto /etc/openldap/schema
		doins "${S}/plugins/kdb/ldap/libkdb_ldap/kerberos.schema"
	fi

	if use xinetd ; then
		insinto /etc/xinetd.d
		newins "${FILESDIR}/kpropd.xinetd" kpropd
	fi
}

pkg_preinst() {
	if has_version "<${CATEGORY}/${PN}-1.8.0" ; then
		elog "MIT split the Kerberos applications from the base Kerberos"
		elog "distribution.  Kerberized versions of telnet, rlogin, rsh, rcp,"
		elog "ftp clients and telnet, ftp deamons now live in"
		elog "\"app-crypt/mit-krb5-appl\" package."
	fi
}
