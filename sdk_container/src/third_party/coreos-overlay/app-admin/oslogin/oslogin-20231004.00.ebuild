# Copyright 2018 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

EAPI=7

# Flatcar: remove eutils add toolchain-funcs
inherit pam flag-o-matic toolchain-funcs

DESCRIPTION="Google Compute Engine OS Login libraries, applications and configurations."
HOMEPAGE="https://github.com/GoogleCloudPlatform/guest-oslogin"

# Release tag of compute-image-packages.
SRC_URI="https://github.com/GoogleCloudPlatform/guest-oslogin/archive/${PV}.tar.gz -> oslogin-${PV}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="*"

DEPEND="
	net-misc/curl
	dev-libs/json-c
	sys-libs/pam
"
RDEPEND="${DEPEND}
	>=app-admin/google-guest-agent-20231016.00
"

S="${WORKDIR}/guest-oslogin-${PV}"

PATCHES=(
	"${FILESDIR}/oslogin-20231004.00-fix-build.patch"
)

src_compile() {
	# Flatcar: export compile env
	tc-export CC CXX
	emake JSON_INCLUDE_PATH="${SYSROOT}/usr/include/json-c" VERSION="${PV}"
}

src_install() {
	emake DESTDIR="${D}/" LIBDIR="$(get_libdir)" VERSION="${PV}" \
		PAMDIR="$(getpam_mod_dir)" install
	dosym libnss_oslogin-"${PV}".so \
		"$(get_libdir)"/libnss_oslogin.so.2
}
