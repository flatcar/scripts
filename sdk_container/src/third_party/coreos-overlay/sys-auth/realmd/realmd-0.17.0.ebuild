# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools systemd

DESCRIPTION="DBus service for configuring kerberos and other online identities"
HOMEPAGE="http://cgit.freedesktop.org/realmd/realmd/"
SRC_URI="https://gitlab.freedesktop.org/realmd/realmd/-/archive/${PV}/${P}.tar.gz"

LICENSE="LGPL-2+"
SLOT="0"
KEYWORDS="amd64 x86 arm64"
IUSE="systemd"

DEPEND="sys-auth/polkit
	sys-devel/gettext
	dev-libs/glib:2
	net-nds/openldap
	virtual/krb5
	systemd? ( sys-apps/systemd )"
RDEPEND="${DEPEND}"

# The daemon is installed to a private dir under /usr/lib, similar to systemd.
QA_MULTILIB_PATHS="usr/lib/realmd/realmd"

PATCHES=(
	"${FILESDIR}/${PN}-0.17.0-use-target-arch-pkg-config-to-fix-cross-compilation.patch"
	"${FILESDIR}/${PN}-0.17.0-put-d-bus-policy-files-in-usr-share.patch"
)

src_prepare() {
	default

	eautoreconf
}

src_configure() {
	local myconf=(
		$(use_with systemd systemd-journal)
		--with-systemd-unit-dir=$(systemd_get_systemunitdir)
		--with-distro=defaults
		--disable-doc
	)
	econf "${myconf[@]}"
}

src_install() {
	systemd_dotmpfilesd "${FILESDIR}/tmpfiles.d/${PN}.conf"
	default
}
