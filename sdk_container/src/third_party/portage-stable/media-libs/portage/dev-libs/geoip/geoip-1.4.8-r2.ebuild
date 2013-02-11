# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/geoip/geoip-1.4.8-r2.ebuild,v 1.9 2013/01/29 11:36:25 ago Exp $

EAPI=4
inherit autotools

MY_P=${P/geoip/GeoIP}

DESCRIPTION="easily lookup countries by IP addresses, even when Reverse DNS entries don't exist"
HOMEPAGE="http://www.maxmind.com/app/ip-location"
SRC_URI="
	http://www.maxmind.com/download/geoip/api/c/${MY_P}.tar.gz
	http://geolite.maxmind.com/download/geoip/database/asnum/GeoIPASNum.dat.gz
	ipv6? ( http://geolite.maxmind.com/download/geoip/database/GeoIPv6.dat.gz
		http://geolite.maxmind.com/download/geoip/database/GeoLiteCityv6-beta/GeoLiteCityv6.dat.gz )
"

# GPL-2 for md5.c - part of libGeoIPUpdate, MaxMind for GeoLite Country db
LICENSE="LGPL-2.1 GPL-2 MaxMind2"
SLOT="0"
KEYWORDS="~alpha amd64 arm hppa ia64 ppc ppc64 ~s390 ~sh ~sparc x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~ia64-linux ~x86-linux ~x86-macos"
IUSE="ipv6 perl-geoipupdate static-libs"

DEPEND="sys-libs/zlib"
RDEPEND="
	${DEPEND}
	perl-geoipupdate? (
		dev-perl/PerlIO-gzip
		dev-perl/libwww-perl
	)
"

S=${WORKDIR}/${MY_P}

src_prepare() {
	sed -e "s:usr local share GeoIP:usr share GeoIP:" \
		-e "s:usr local etc:etc:" \
		-i apps/geoipupdate-pureperl.pl || die
	sed -e 's|yahoo.com|98.139.183.24|g' \
		-i test/country_test_name.txt test/region_test.txt || die

	eautoreconf
}

src_configure() {
	econf $(use_enable static-libs static)
}

src_install() {
	default
	use perl-geoipupdate && dobin apps/geoipupdate-pureperl.pl
	dodoc AUTHORS ChangeLog README TODO conf/GeoIP.conf.default
	rm "${ED}/etc/GeoIP.conf.default"
	if ! use static-libs; then
		rm -f "${ED}"/usr/lib*/lib*.la
	fi

	insinto /usr/share/GeoIP
	doins "${WORKDIR}/GeoIPASNum.dat"

	if use ipv6; then
		doins "${WORKDIR}/GeoIPv6.dat"
		doins "${WORKDIR}/GeoLiteCityv6.dat"
	fi

	newsbin "${FILESDIR}/geoipupdate-r2.sh" geoipupdate.sh
}
