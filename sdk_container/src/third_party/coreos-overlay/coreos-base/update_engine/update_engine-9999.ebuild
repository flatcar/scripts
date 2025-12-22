# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

TMPFILES_OPTIONAL=1
inherit autotools flag-o-matic toolchain-funcs systemd tmpfiles

DESCRIPTION="Update daemon for Flatcar Container Linux"
HOMEPAGE="https://github.com/flatcar/update_engine"

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/flatcar/update_engine.git"
	inherit git-r3
else
	EGIT_VERSION="3a44be455f7c6978e99f9e3d4f01401d80301c40" # main
	SRC_URI="https://github.com/flatcar/update_engine/archive/${EGIT_VERSION}.tar.gz -> ${PN}-${EGIT_VERSION}.tar.gz"
	S="${WORKDIR}/${PN}-${EGIT_VERSION}"
	KEYWORDS="amd64 arm64"
fi

LICENSE="BSD"
SLOT="0"
IUSE="cros_host +debug delta_generator"

RDEPEND="
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
	sys-fs/e2fsprogs
"
DEPEND="
	${RDEPEND}
	dev-cpp/gtest
"
BDEPEND="
	dev-util/glib-utils
	virtual/pkgconfig
"

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
		$(use_enable debug)
		$(use_enable delta_generator)
	)

	if tc-is-cross-compiler; then
		# Override glib-genmarshal path
		myconf+=(GLIB_GENMARSHAL="$("$(tc-getBUILD_PKG_CONFIG)" --variable=glib_genmarshal glib-2.0)")
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

	dosym bin/flatcar-postinst /usr/postinst

	systemd_dounit systemd/update-engine.service
	systemd_dounit systemd/update-engine-stub.service
	systemd_dounit systemd/update-engine-stub.timer

	systemd_enable_service multi-user.target update-engine.service
	systemd_enable_service multi-user.target update-engine-stub.timer

	insinto /usr/share/dbus-1/system.d
	doins com.coreos.update1.conf

	insinto /usr/share/update_engine
	doins src/update_engine/update_metadata.proto
	exeinto /usr/share/update_engine
	doexe decode_payload

	# Install rule to remove old UpdateEngine.conf from /etc
	dotmpfiles "${FILESDIR}"/update-engine.conf
}
