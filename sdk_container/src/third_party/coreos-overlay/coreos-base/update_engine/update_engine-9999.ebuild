# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_PROJECT="flatcar/update_engine"
CROS_WORKON_REPO="https://github.com"

if [[ "${PV}" == 9999 ]]; then
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
else
	CROS_WORKON_COMMIT="c6f566d47d8949632f7f43871eb8d5c625af3209" # flatcar-master
	KEYWORDS="amd64 arm64"
fi

TMPFILES_OPTIONAL=1
inherit autotools flag-o-matic toolchain-funcs cros-workon systemd tmpfiles

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
	dev-libs/libsodium
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

	if tc-is-cross-compiler; then
		# Override glib-genmarshal path
		local build_pkg_config="$(tc-getBUILD_PROG PKG_CONFIG pkg-config)"
		myconf+=(GLIB_GENMARSHAL="$("${build_pkg_config}" --variable=glib_genmarshal glib-2.0)")
	fi

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
	dotmpfiles "${FILESDIR}"/update-engine.conf
}
