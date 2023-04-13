# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_PROJECT="flatcar/update_engine"
CROS_WORKON_REPO="https://github.com"

if [[ "${PV}" == 9999 ]]; then
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
else
	CROS_WORKON_COMMIT="858f3a502d88f031aca88d590bfb2b922f0dfc8a" # flatcar-master
	KEYWORDS="amd64 arm64"
fi

inherit autotools flag-o-matic toolchain-funcs cros-workon systemd

DESCRIPTION="CoreOS OS Update Engine"
HOMEPAGE="https://github.com/coreos/update_engine"
SRC_URI=""

LICENSE="BSD"
SLOT="0"
IUSE="cros-debug cros_host -delta_generator symlink-usr"

RDEPEND="!coreos-base/coreos-installer
	app-arch/bzip2
	coreos-base/coreos-au-key
	dev-cpp/gflags
	dev-cpp/glog[gflags]
	dev-libs/dbus-glib
	dev-libs/glib
	dev-libs/libxml2
	dev-libs/openssl
	dev-libs/protobuf:=
	dev-util/bsdiff
	net-misc/curl
	>=sys-apps/seismograph-2.2.0
	sys-fs/e2fsprogs"
BDEPEND="dev-util/glib-utils"
DEPEND="dev-cpp/gtest
	${BDEPEND}
	${RDEPEND}"

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	# Disable PIE when building for the SDK, this works around a bug that
	# breaks using delta_generator from the update.zip bundle.
	# https://code.google.com/p/chromium/issues/detail?id=394508
	# https://code.google.com/p/chromium/issues/detail?id=394241
	if use cros_host; then
		append-flags -no-pie
		append-ldflags -no-pie
	fi

	# Work around new gdbus-codegen output.
	append-flags -Wno-unused-function

	local myconf=(
		$(use_enable cros-debug debug)
		$(use_enable delta_generator)
	)

	econf "${myconf[@]}"
}

src_test() {
	if use cros_host; then
		default
	else
		ewarn "Skipping tests on cross-compiled target platform..."
	fi
}

src_install() {
	default

	if use symlink-usr; then
		dosym sbin/flatcar-postinst /usr/postinst
	else
		dosym usr/sbin/flatcar-postinst /postinst
	fi

	systemd_dounit systemd/update-engine.service
	systemd_dounit systemd/update-engine-stub.service
	systemd_dounit systemd/update-engine-stub.timer

	systemd_enable_service multi-user.target update-engine.service
	systemd_enable_service multi-user.target update-engine-stub.timer

	insinto /usr/share/dbus-1/system.d
	doins com.coreos.update1.conf

	# Install rule to remove old UpdateEngine.conf from /etc
	systemd_dotmpfilesd "${FILESDIR}"/update-engine.conf
}
