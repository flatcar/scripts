# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/gsutil/gsutil-2011.21.11-r1.ebuild,v 1.1 2011/12/13 19:55:27 vapier Exp $

EAPI="3"

inherit versionator eutils python multilib

MY_P=$(version_format_string '${PN}_$3-$2-$1')

DESCRIPTION="command line tool for interacting with cloud storage services"
HOMEPAGE="http://code.google.com/p/gsutil/"
SRC_URI="http://${PN}.googlecode.com/files/${MY_P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="examples"

DEPEND=""
RDEPEND="${DEPEND}
	>=dev-python/boto-2.1.1"

S=${WORKDIR}/${PN}

src_prepare() {
	# use system boto
	rm -rf boto
	epatch "${FILESDIR}"/${PN}-system-boto.patch

	# use the custom internal path to avoid polluting python system
	sed -i \
		-e "/^gsutil_bin_dir =/s:=.*:= '/usr/$(get_libdir)/${PN}';sys.path.insert(0, gsutil_bin_dir);:" \
		gsutil || die

	# trim some cruft
	find gslib third_party -name README -delete
}

src_install() {
	dobin gsutil || die

	insinto /usr/$(get_libdir)/${PN}
	doins -r gslib oauth2_plugin third_party VERSION || die

	dodoc README
	if use examples ; then
		insinto /usr/share/doc/${PF}/examples
		doins -r cloud{auth,reader}
	fi
}

pkg_postinst() {
	python_mod_optimize /usr/$(get_libdir)/${PN}
}

pkg_postrm() {
	python_mod_cleanup /usr/$(get_libdir)/${PN}
}
