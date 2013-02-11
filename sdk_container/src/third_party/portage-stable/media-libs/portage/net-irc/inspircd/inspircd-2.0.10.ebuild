# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-irc/inspircd/inspircd-2.0.10.ebuild,v 1.2 2013/01/08 19:41:58 nimiux Exp $

EAPI=4

inherit eutils multilib toolchain-funcs

DESCRIPTION="Inspire IRCd - The Stable, High-Performance Modular IRCd"
HOMEPAGE="http://inspircd.github.com/"
SRC_URI="http://www.github.com/inspircd/inspircd/archive/v${PV}.tar.gz ->
${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="geoip gnutls ipv6 ldap mysql postgres sqlite ssl"

RDEPEND="
	dev-lang/perl
	ssl? ( dev-libs/openssl )
	geoip? ( dev-libs/geoip )
	gnutls? ( net-libs/gnutls dev-libs/libgcrypt )
	ldap? ( net-nds/openldap )
	mysql? ( virtual/mysql )
	postgres? ( dev-db/postgresql-server )
	sqlite? ( >=dev-db/sqlite-3.0 )"
DEPEND="${RDEPEND}"

pkg_setup() {
	enewgroup ${PN}
	enewuser ${PN} -1 -1 -1 ${PN}
}

src_prepare() {
	# Patch the inspircd launcher with the inspircd user
	sed -i -e "s/@UID@/${PN}/" "${S}/make/template/${PN}" || die

	epatch "${FILESDIR}/${PF}-fix-path-builds.patch"
}

src_configure() {
	local extras=""
	local essl="--enable-openssl"
	local egnutls="--enable-gnutls"
	local dipv6="--disable-ipv6"

	use geoip && extras="${extras}m_geoip.cpp,"
	use gnutls && extras="${extras}m_ssl_gnutls.cpp,"
	use ldap && extras="${extras}m_ldapauth.cpp,"
	use mysql && extras="${extras}m_mysql.cpp,"
	use postgres && extras="${extras}m_pgsql.cpp,"
	use sqlite && extras="${extras}m_sqlite3.cpp,"
	use ssl && extras="${extras}m_ssl_openssl.cpp,"

	if [ -n "${extras}" ]; then
		econf --disable-interactive --enable-extras=${extras}
	fi

	use !ssl && essl=""
	use !gnutls && egnutls=""
	use ipv6 && dipv6=""

	econf \
		--with-cc="$(tc-getCXX)" \
		--disable-interactive \
		--prefix="/usr/$(get_libdir)/${PN}" \
		--config-dir="/etc/${PN}" \
		--data-dir="/var/lib/${PN}/data" \
		--log-dir="/var/log/${PN}" \
		--binary-dir="/usr/bin" \
		--module-dir="/usr/$(get_libdir)/${PN}/modules" \
		${essl} ${egnutls} ${dipv6}
}

src_compile() {
	emake V=1 LDFLAGS="${LDFLAGS}" CXXFLAGS="${CXXFLAGS}"
}

src_install() {
	emake INSTUID=${PN} \
		BINPATH="${D}/usr/bin" \
		BASE="${D}/usr/$(get_libdir)/${PN}/inspircd.launcher" \
		MODPATH="${D}/usr/$(get_libdir)/${PN}/modules/" \
		CONPATH="${D}/etc/${PN}" install

	insinto "/usr/include/${PN}"
	doins include/*

	diropts -o"${PN}" -g"${PN}"
	dodir "/var/lib/${PN}/data"

	newinitd "${FILESDIR}/${PF}-init" "${PN}"
	keepdir "/var/log/${PN}"/
}

pkg_postinst() {
	elog "Before starting ${PN} the first time, you should create"
	elog "the /etc/${PN}/${PN}.conf file."
	elog "You can find example configuration files under /etc/${PN}"
	elog "Read the ${PN}.conf.example file carefully before "
	elog "(re)starting the service."
	elog
}
