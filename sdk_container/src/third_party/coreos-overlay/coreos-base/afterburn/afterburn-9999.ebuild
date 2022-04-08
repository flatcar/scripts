# Copyright (c) 2017 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CROS_WORKON_PROJECT="coreos/afterburn"
CROS_WORKON_LOCALNAME="afterburn"
CROS_WORKON_REPO="https://github.com"

if [[ ${PV} == 9999 ]]; then
	KEYWORDS="~amd64 ~arm64"
else
	CROS_WORKON_COMMIT="43dc76d7c38921d8eb0dc24d3b0b18787fa8ee07" # v5.2.0
	KEYWORDS="amd64 arm64"
fi

# https://github.com/gentoo/cargo-ebuild
CRATES="
aho-corasick-0.7.18
ansi_term-0.12.1
anyhow-1.0.52
arc-swap-1.3.0
assert-json-diff-2.0.1
atty-0.2.14
autocfg-1.0.1
base64-0.10.1
base64-0.13.0
bitflags-1.3.2
block-buffer-0.10.0
block-buffer-0.9.0
bumpalo-3.7.0
byteorder-1.4.3
bytes-1.0.1
cc-1.0.68
cfg-if-1.0.0
charset-0.1.2
chrono-0.4.19
clap-2.34.0
colored-2.0.0
core-foundation-0.9.1
core-foundation-sys-0.8.2
cpufeatures-0.1.5
cpufeatures-0.2.1
crossbeam-channel-0.5.1
crossbeam-utils-0.8.5
crypto-common-0.1.1
difference-2.0.0
digest-0.10.1
digest-0.9.0
dirs-next-2.0.0
dirs-sys-next-0.1.2
encoding_rs-0.8.28
errno-0.2.7
errno-dragonfly-0.1.1
fastrand-1.6.0
fnv-1.0.7
foreign-types-0.3.2
foreign-types-shared-0.1.1
form_urlencoded-1.0.1
futures-channel-0.3.15
futures-core-0.3.15
futures-io-0.3.15
futures-sink-0.3.15
futures-task-0.3.15
futures-util-0.3.15
gcc-0.3.55
generic-array-0.14.4
getrandom-0.2.3
h2-0.3.10
hashbrown-0.11.2
hermit-abi-0.1.19
hmac-0.12.0
hostname-0.3.1
http-0.2.4
http-body-0.4.2
httparse-1.4.1
httpdate-1.0.1
hyper-0.14.11
hyper-tls-0.5.0
idna-0.2.3
indexmap-1.7.0
instant-0.1.12
ipnet-2.3.1
ipnetwork-0.18.0
itoa-0.4.7
itoa-1.0.1
js-sys-0.3.51
lazy_static-1.4.0
libc-0.2.103
libsystemd-0.5.0
linked-hash-map-0.5.4
log-0.4.14
mailparse-0.13.7
maplit-1.0.2
match_cfg-0.1.0
matches-0.1.8
md-5-0.9.1
memchr-2.4.0
memoffset-0.6.4
mime-0.3.16
minimal-lexical-0.2.1
mio-0.7.13
miow-0.3.7
mockito-0.30.0
native-tls-0.2.8
nix-0.23.1
nom-7.1.0
ntapi-0.3.6
num-integer-0.1.44
num-traits-0.2.14
num_cpus-1.13.0
once_cell-1.8.0
opaque-debug-0.3.0
openssh-keys-0.5.0
openssl-0.10.38
openssl-probe-0.1.4
openssl-sys-0.9.70
percent-encoding-2.1.0
pin-project-lite-0.2.7
pin-utils-0.1.0
pkg-config-0.3.19
pnet_base-0.28.0
pnet_datalink-0.28.0
pnet_sys-0.28.0
ppv-lite86-0.2.10
proc-macro2-1.0.27
quote-1.0.9
quoted_printable-0.4.3
rand-0.8.4
rand_chacha-0.3.1
rand_core-0.6.3
rand_hc-0.3.1
redox_syscall-0.2.9
redox_users-0.4.0
regex-1.5.4
regex-syntax-0.6.25
remove_dir_all-0.5.3
reqwest-0.11.9
rustversion-1.0.5
ryu-1.0.5
schannel-0.1.19
security-framework-2.3.1
security-framework-sys-2.3.0
serde-1.0.133
serde-xml-rs-0.5.1
serde_derive-1.0.133
serde_json-1.0.74
serde_urlencoded-0.7.0
serde_yaml-0.8.23
sha2-0.10.1
sha2-0.9.5
slab-0.4.3
slog-2.7.0
slog-async-2.7.0
slog-scope-4.4.0
slog-term-2.8.0
socket2-0.4.0
strsim-0.8.0
subtle-2.4.0
syn-1.0.73
take_mut-0.2.2
tempfile-3.3.0
term-0.7.0
textwrap-0.11.0
thiserror-1.0.26
thiserror-impl-1.0.26
thread_local-1.1.3
time-0.1.43
tinyvec-1.2.0
tinyvec_macros-0.1.0
tokio-1.15.0
tokio-native-tls-0.3.0
tokio-util-0.6.7
tower-service-0.3.1
tracing-0.1.26
tracing-core-0.1.18
try-lock-0.2.3
typenum-1.13.0
unicode-bidi-0.3.5
unicode-normalization-0.1.19
unicode-width-0.1.8
unicode-xid-0.2.2
url-2.2.2
users-0.11.0
uuid-0.8.2
vcpkg-0.2.15
vec_map-0.8.2
version_check-0.9.3
vmw_backdoor-0.2.1
want-0.3.0
wasi-0.10.2+wasi-snapshot-preview1
wasm-bindgen-0.2.74
wasm-bindgen-backend-0.2.74
wasm-bindgen-futures-0.4.24
wasm-bindgen-macro-0.2.74
wasm-bindgen-macro-support-0.2.74
wasm-bindgen-shared-0.2.74
web-sys-0.3.51
winapi-0.3.9
winapi-i686-pc-windows-gnu-0.4.0
winapi-x86_64-pc-windows-gnu-0.4.0
winreg-0.7.0
xml-rs-0.8.3
yaml-rust-0.4.5
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
	"${FILESDIR}"/0003-encode-information-for-systemd-networkd-wait-online.patch
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
