# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="Components to support Google Cloud OS Login. This contains bits that belong in USR"
HOMEPAGE="https://github.com/GoogleCloudPlatform/guest-oslogin"
SRC_URI="https://github.com/GoogleCloudPlatform/guest-oslogin/archive/${PV}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

inherit pam toolchain-funcs

DEPEND="
	net-misc/curl[ssl]
	dev-libs/json-c
	sys-libs/pam
"

RDEPEND="${DEPEND}"

S=${WORKDIR}/guest-oslogin-${PV}/

src_prepare() {
	eapply -p2 "$FILESDIR/0001-pam_module-use-var-lib-instead-of-var.patch"
	default
}

src_compile() {
	emake CC="$(tc-getCC)" CXX="$(tc-getCXX)" \
            VERSION=${PV} \
            JSON_INCLUDE_PATH="${SYSROOT%/}/usr/include/json-c"
}

src_install() {
	dolib.so src/libnss_cache_oslogin-${PV}.so
	dolib.so src/libnss_oslogin-${PV}.so

	exeinto /usr/libexec
	doexe src/google_authorized_keys
	doexe src/google_oslogin_nss_cache

	dopammod src/pam_oslogin_admin.so
	dopammod src/pam_oslogin_login.so

	# config files the base Ignition config will create links to
	insinto /usr/share/google-oslogin
	doins "${FILESDIR}/sshd_config"
	doins "${FILESDIR}/nsswitch.conf"
	doins "${FILESDIR}/pam_sshd"
	doins "${FILESDIR}/oslogin-sudoers"
	doins "${FILESDIR}/group.conf"
}
