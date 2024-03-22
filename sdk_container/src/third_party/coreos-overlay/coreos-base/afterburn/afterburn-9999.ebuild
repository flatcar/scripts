# Copyright (c) 2017 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CROS_WORKON_PROJECT="coreos/afterburn"
CROS_WORKON_LOCALNAME="afterburn"
CROS_WORKON_REPO="https://github.com"

if [[ ${PV} == 9999 ]]; then
	KEYWORDS="~amd64 ~arm64"
else
	CROS_WORKON_COMMIT="0fdf617edee3050828d404e6074e1c227d5b10bb" # v5.5.1
	KEYWORDS="amd64 arm64"
fi

# https://github.com/gentoo/cargo-ebuild
CRATES="
	addr2line-0.21.0
	adler-1.0.2
	adler32-1.2.0
	aho-corasick-1.1.2
	anstyle-1.0.4
	anyhow-1.0.79
	arc-swap-1.6.0
	assert-json-diff-2.0.2
	async-broadcast-0.5.1
	async-channel-2.1.1
	async-executor-1.8.0
	async-fs-1.6.0
	async-io-1.13.0
	async-io-2.2.2
	async-lock-2.8.0
	async-lock-3.3.0
	async-process-1.8.1
	async-recursion-1.0.5
	async-signal-0.2.5
	async-task-4.7.0
	async-trait-0.1.77
	atomic-waker-1.1.2
	atty-0.2.14
	autocfg-1.1.0
	backtrace-0.3.69
	base64-0.13.1
	base64-0.21.7
	bitflags-1.3.2
	bitflags-2.4.1
	block-buffer-0.10.4
	blocking-1.5.1
	bumpalo-3.14.0
	byteorder-1.5.0
	bytes-1.5.0
	cc-1.0.83
	cfg-if-1.0.0
	charset-0.1.3
	clap-4.4.16
	clap_builder-4.4.16
	clap_derive-4.4.7
	clap_lex-0.6.0
	colored-2.1.0
	concurrent-queue-2.4.0
	core-foundation-0.9.4
	core-foundation-sys-0.8.6
	cpufeatures-0.2.12
	crc32fast-1.3.2
	crossbeam-channel-0.5.11
	crossbeam-utils-0.8.19
	crypto-common-0.1.6
	data-encoding-2.5.0
	deranged-0.3.11
	derivative-2.2.0
	digest-0.10.7
	dirs-next-2.0.0
	dirs-sys-next-0.1.2
	encoding_rs-0.8.33
	enumflags2-0.7.8
	enumflags2_derive-0.7.8
	equivalent-1.0.1
	errno-0.3.8
	event-listener-2.5.3
	event-listener-3.1.0
	event-listener-4.0.3
	event-listener-strategy-0.4.0
	fastrand-1.9.0
	fastrand-2.0.1
	fnv-1.0.7
	foreign-types-0.3.2
	foreign-types-shared-0.1.1
	form_urlencoded-1.2.1
	futures-0.3.30
	futures-channel-0.3.30
	futures-core-0.3.30
	futures-executor-0.3.30
	futures-io-0.3.30
	futures-lite-1.13.0
	futures-lite-2.2.0
	futures-macro-0.3.30
	futures-sink-0.3.30
	futures-task-0.3.30
	futures-util-0.3.30
	generic-array-0.14.7
	getrandom-0.2.12
	gimli-0.28.1
	h2-0.3.23
	hashbrown-0.14.3
	heck-0.4.1
	hermit-abi-0.1.19
	hermit-abi-0.3.3
	hex-0.4.3
	hmac-0.12.1
	hostname-0.3.1
	http-0.2.11
	http-body-0.4.6
	httparse-1.8.0
	httpdate-1.0.3
	hyper-0.14.28
	hyper-tls-0.5.0
	idna-0.5.0
	indexmap-2.1.0
	instant-0.1.12
	io-lifetimes-1.0.11
	ipnet-2.9.0
	ipnetwork-0.20.0
	itoa-1.0.10
	js-sys-0.3.66
	lazy_static-1.4.0
	libc-0.2.152
	libflate-1.4.0
	libflate_lz77-1.2.0
	libredox-0.0.1
	libsystemd-0.7.0
	linux-raw-sys-0.3.8
	linux-raw-sys-0.4.12
	lock_api-0.4.11
	log-0.4.20
	mailparse-0.14.0
	maplit-1.0.2
	match_cfg-0.1.0
	md-5-0.10.6
	memchr-2.7.1
	memoffset-0.7.1
	memoffset-0.9.0
	mime-0.3.17
	minimal-lexical-0.2.1
	miniz_oxide-0.7.1
	mio-0.8.10
	mockito-1.2.0
	native-tls-0.2.11
	nix-0.26.4
	nix-0.27.1
	no-std-net-0.6.0
	nom-7.1.3
	num_cpus-1.16.0
	num_threads-0.1.6
	object-0.32.2
	once_cell-1.19.0
	openssh-keys-0.6.2
	openssl-0.10.62
	openssl-macros-0.1.1
	openssl-probe-0.1.5
	openssl-sys-0.9.98
	ordered-stream-0.2.0
	parking-2.2.0
	parking_lot-0.12.1
	parking_lot_core-0.9.9
	percent-encoding-2.3.1
	pin-project-lite-0.2.13
	pin-utils-0.1.0
	piper-0.2.1
	pkg-config-0.3.28
	pnet_base-0.34.0
	pnet_datalink-0.34.0
	pnet_sys-0.34.0
	polling-2.8.0
	polling-3.3.1
	powerfmt-0.2.0
	ppv-lite86-0.2.17
	proc-macro-crate-1.3.1
	proc-macro2-1.0.76
	quote-1.0.35
	quoted_printable-0.4.8
	rand-0.8.5
	rand_chacha-0.3.1
	rand_core-0.6.4
	redox_syscall-0.4.1
	redox_users-0.4.4
	regex-1.10.2
	regex-automata-0.4.3
	regex-syntax-0.8.2
	reqwest-0.11.23
	rle-decode-fast-1.0.3
	rustc-demangle-0.1.23
	rustix-0.37.27
	rustix-0.38.28
	rustversion-1.0.14
	ryu-1.0.16
	schannel-0.1.23
	scopeguard-1.2.0
	security-framework-2.9.2
	security-framework-sys-2.9.1
	serde-1.0.195
	serde-xml-rs-0.6.0
	serde_derive-1.0.195
	serde_json-1.0.111
	serde_repr-0.1.18
	serde_urlencoded-0.7.1
	serde_yaml-0.9.30
	sha1-0.10.6
	sha2-0.10.8
	signal-hook-registry-1.4.1
	similar-2.4.0
	slab-0.4.9
	slog-2.7.0
	slog-async-2.8.0
	slog-scope-4.4.0
	slog-term-2.9.0
	smallvec-1.11.2
	socket2-0.4.10
	socket2-0.5.5
	static_assertions-1.1.0
	strsim-0.10.0
	subtle-2.5.0
	syn-1.0.109
	syn-2.0.48
	system-configuration-0.5.1
	system-configuration-sys-0.5.0
	take_mut-0.2.2
	tempfile-3.9.0
	term-0.7.0
	terminal_size-0.3.0
	thiserror-1.0.56
	thiserror-impl-1.0.56
	thread_local-1.1.7
	time-0.3.31
	time-core-0.1.2
	time-macros-0.2.16
	tinyvec-1.6.0
	tinyvec_macros-0.1.1
	tokio-1.35.1
	tokio-macros-2.2.0
	tokio-native-tls-0.3.1
	tokio-util-0.7.10
	toml_datetime-0.6.5
	toml_edit-0.19.15
	tower-service-0.3.2
	tracing-0.1.40
	tracing-attributes-0.1.27
	tracing-core-0.1.32
	try-lock-0.2.5
	typenum-1.17.0
	uds_windows-1.1.0
	unicode-bidi-0.3.14
	unicode-ident-1.0.12
	unicode-normalization-0.1.22
	unsafe-libyaml-0.2.10
	url-2.5.0
	uuid-1.6.1
	uzers-0.11.3
	vcpkg-0.2.15
	version_check-0.9.4
	vmw_backdoor-0.2.4
	waker-fn-1.1.1
	want-0.3.1
	wasi-0.11.0+wasi-snapshot-preview1
	wasm-bindgen-0.2.89
	wasm-bindgen-backend-0.2.89
	wasm-bindgen-futures-0.4.39
	wasm-bindgen-macro-0.2.89
	wasm-bindgen-macro-support-0.2.89
	wasm-bindgen-shared-0.2.89
	web-sys-0.3.66
	winapi-0.3.9
	winapi-i686-pc-windows-gnu-0.4.0
	winapi-x86_64-pc-windows-gnu-0.4.0
	windows-sys-0.48.0
	windows-sys-0.52.0
	windows-targets-0.48.5
	windows-targets-0.52.0
	windows_aarch64_gnullvm-0.48.5
	windows_aarch64_gnullvm-0.52.0
	windows_aarch64_msvc-0.48.5
	windows_aarch64_msvc-0.52.0
	windows_i686_gnu-0.48.5
	windows_i686_gnu-0.52.0
	windows_i686_msvc-0.48.5
	windows_i686_msvc-0.52.0
	windows_x86_64_gnu-0.48.5
	windows_x86_64_gnu-0.52.0
	windows_x86_64_gnullvm-0.48.5
	windows_x86_64_gnullvm-0.52.0
	windows_x86_64_msvc-0.48.5
	windows_x86_64_msvc-0.52.0
	winnow-0.5.34
	winreg-0.50.0
	xdg-home-1.0.0
	xml-rs-0.8.19
	zbus-3.14.1
	zbus_macros-3.14.1
	zbus_names-2.6.0
	zvariant-3.15.0
	zvariant_derive-3.15.0
	zvariant_utils-1.0.1
"

inherit coreos-cargo cros-workon systemd

DESCRIPTION="A tool for collecting instance metadata from various providers"
HOMEPAGE="https://github.com/coreos/afterburn"
SRC_URI="$(cargo_crate_uris ${CRATES})"

LICENSE="Apache-2.0"
SLOT="0"

DEPEND="dev-libs/openssl:0="

RDEPEND="
	${DEPEND}
	!coreos-base/coreos-metadata
"

PATCHES=(
	"${FILESDIR}"/0001-Revert-remove-cl-legacy-feature.patch
	"${FILESDIR}"/0002-util-cmdline-Handle-the-cmdline-flags-as-list-of-sup.patch
	"${FILESDIR}"/0003-cargo-reduce-binary-size-for-release-profile.patch
	"${FILESDIR}"/0004-providers-support-for-proxmoxve.patch
	"${FILESDIR}"/0005-proxmoxve-ignore-user-data-file-if-header-is-not-pre.patch
	"${FILESDIR}"/0006-proxmoxve-Generate-proper-network-unit-for-the-DHCP-.patch
)

src_unpack() {
	cros-workon_src_unpack "$@"
	coreos-cargo_src_unpack "$@"
}

src_prepare() {
	default

	# tell the rust-openssl bindings where the openssl library and include dirs are
	export PKG_CONFIG_ALLOW_CROSS=1
	export OPENSSL_LIB_DIR=/usr/lib64/
	export OPENSSL_INCLUDE_DIR=/usr/include/openssl/
}

src_compile() {
	cargo_src_compile --features cl-legacy "$@"
}

src_install() {
	cargo_src_install --features cl-legacy "$@"
	mv "${D}/usr/bin/afterburn" "${D}/usr/bin/coreos-metadata"

	systemd_dounit "${FILESDIR}/coreos-metadata.service"
	systemd_dounit "${FILESDIR}/coreos-metadata-sshkeys@.service"
}

src_test() {
	cargo_src_test --features cl-legacy "$@"
}
