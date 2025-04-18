# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_P="guest-oslogin-${PV}"
DESCRIPTION="Components to support Google Cloud OS Login. This contains bits that belong in USR"
HOMEPAGE="https://github.com/GoogleCloudPlatform/guest-oslogin"
SRC_URI="https://github.com/GoogleCloudPlatform/guest-oslogin/archive/${PV}.tar.gz -> ${MY_P}.tar.gz"
S="${WORKDIR}/${MY_P}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64"
IUSE="systemd"

inherit pam systemd toolchain-funcs

DEPEND="
	net-misc/curl[ssl]
	dev-libs/json-c
	sys-libs/pam
"

RDEPEND="
	${DEPEND}
	systemd? ( sys-apps/systemd )
	!systemd? ( virtual/cron )
"

BDEPEND="
	virtual/pkgconfig
"

PATCHES=(
	"${FILESDIR}"/${PN}-var-lib.patch
	"${FILESDIR}"/${PN}-pkg-config.patch
)

my_emake() {
	emake \
		VERSION="${PV}" \
		PKG_CONFIG="$(tc-getPKG_CONFIG)" \
		"${@}"
}

src_compile() {
	my_emake \
		CC="$(tc-getCC)" \
		CXX="$(tc-getCXX)"
}

src_install() {
	my_emake \
		DESTDIR="${D}" \
		PREFIX="${EPREFIX}/usr" \
		BINDIR="\$(PREFIX)/bin" \
		CRONDIR="${EPREFIX}/etc/cron.d" \
		LIBDIR="\$(PREFIX)/$(get_libdir)" \
		MANDIR="\$(PREFIX)/share/man" \
		PAMDIR="$(getpam_mod_dir)" \
		PRESETDIR="$(systemd_get_systempresetdir)" \
		SYSTEMDDIR="$(systemd_get_systemunitdir)" \
		INSTALL_CRON=$(usex !systemd 1 '') \
		install

	# Flatcar doesn't need this script.
	rm "${ED}"/usr/bin/google_oslogin_control || die

	# man pages need fixing up for Gentoo QA but Flatcar drops them anyway.
	rm -r "${ED}"/usr/share/man || die

	# config files the base Ignition config will create links to
	insinto /usr/share/google-oslogin
	doins "${FILESDIR}/sshd_config"
	doins "${FILESDIR}/60-flatcar-google-oslogin.conf"
	doins "${FILESDIR}/nsswitch.conf"
	doins "${FILESDIR}/pam_sshd"
	doins "${FILESDIR}/oslogin-sudoers"
	doins "${FILESDIR}/group.conf"
}
