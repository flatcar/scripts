# Copyright (c) 2023-2024 Flatcar Maintainers
# Distributed under the terms of the GNU General Public License v2

EAPI=8

EGIT_REPO_URI="https://github.com/flatcar/ue-rs.git"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	KEYWORDS="~amd64 ~arm64"
	CRATES=""
else
	EGIT_COMMIT="07fab3e44c768244ce4feacbc09e9ab5309be588" # trunk
	KEYWORDS="amd64 arm64"
	SRC_URI="https://github.com/flatcar/${PN}/archive/${EGIT_COMMIT}.tar.gz -> flatcar-${PN}-${EGIT_COMMIT}.tar.gz"
	S="${WORKDIR}/${PN}-${EGIT_COMMIT}"

	CRATES="
		addr2line@0.24.2
		adler2@2.0.0
		aho-corasick@1.1.3
		anyhow@1.0.98
		argh@0.1.13
		argh_derive@0.1.13
		argh_shared@0.1.13
		autocfg@1.4.0
		backtrace@0.3.74
		base64@0.21.7
		base64ct@1.7.3
		bitflags@1.3.2
		bitflags@2.9.0
		block-buffer@0.10.4
		bstr@1.12.0
		bumpalo@3.17.0
		byteorder@1.5.0
		bytes@1.10.1
		bzip2-sys@0.1.13+1.0.8
		bzip2@0.4.4
		cc@1.2.19
		cfg-if@1.0.0
		const-oid@0.9.6
		core-foundation-sys@0.8.7
		core-foundation@0.9.4
		cpufeatures@0.2.17
		crypto-common@0.1.6
		ct-codecs@1.1.3
		der@0.7.9
		digest@0.10.7
		displaydoc@0.2.5
		encoding_rs@0.8.35
		env_logger@0.10.2
		equivalent@1.0.2
		errno@0.3.11
		fastrand@2.3.0
		fnv@1.0.7
		foreign-types-shared@0.1.1
		foreign-types@0.3.2
		form_urlencoded@1.2.1
		futures-channel@0.3.31
		futures-core@0.3.31
		futures-io@0.3.31
		futures-sink@0.3.31
		futures-task@0.3.31
		futures-util@0.3.31
		generic-array@0.14.7
		getrandom@0.2.15
		getrandom@0.3.2
		gimli@0.31.1
		globset@0.4.16
		h2@0.3.26
		hashbrown@0.15.2
		hermit-abi@0.5.0
		http-body@0.4.6
		http@0.2.12
		httparse@1.10.1
		httpdate@1.0.3
		humantime@2.2.0
		hyper-tls@0.5.0
		hyper@0.14.32
		icu_collections@1.5.0
		icu_locid@1.5.0
		icu_locid_transform@1.5.0
		icu_locid_transform_data@1.5.1
		icu_normalizer@1.5.0
		icu_normalizer_data@1.5.1
		icu_properties@1.5.1
		icu_properties_data@1.5.1
		icu_provider@1.5.0
		icu_provider_macros@1.5.0
		idna@1.0.3
		idna_adapter@1.2.0
		indexmap@2.9.0
		ipnet@2.11.0
		is-terminal@0.4.16
		itoa@1.0.15
		jetscii@0.5.3
		js-sys@0.3.77
		lazy_static@1.5.0
		libc@0.2.172
		libm@0.2.11
		linux-raw-sys@0.9.4
		litemap@0.7.5
		log@0.4.27
		memchr@2.7.4
		mime@0.3.17
		miniz_oxide@0.8.8
		mio@1.0.3
		native-tls@0.2.14
		num-bigint-dig@0.8.4
		num-integer@0.1.46
		num-iter@0.1.45
		num-traits@0.2.19
		object@0.36.7
		once_cell@1.21.3
		openssl-macros@0.1.1
		openssl-probe@0.1.6
		openssl-sys@0.9.107
		openssl@0.10.72
		pem-rfc7468@0.7.0
		percent-encoding@2.3.1
		pin-project-lite@0.2.16
		pin-utils@0.1.0
		pkcs1@0.7.5
		pkcs8@0.10.2
		pkg-config@0.3.32
		ppv-lite86@0.2.21
		proc-macro2@1.0.94
		protobuf-support@3.7.2
		protobuf@3.7.2
		quote@1.0.40
		r-efi@5.2.0
		rand@0.8.5
		rand_chacha@0.3.1
		rand_core@0.6.4
		regex-automata@0.4.9
		regex-syntax@0.8.5
		regex@1.11.1
		reqwest@0.11.27
		rsa@0.9.8
		rust-fuzzy-search@0.1.1
		rustc-demangle@0.1.24
		rustix@1.0.5
		rustls-pemfile@1.0.4
		rustversion@1.0.20
		ryu@1.0.20
		schannel@0.1.27
		security-framework-sys@2.14.0
		security-framework@2.11.1
		serde@1.0.219
		serde_derive@1.0.219
		serde_json@1.0.140
		serde_urlencoded@0.7.1
		sha1@0.10.6
		sha2@0.10.8
		shlex@1.3.0
		signature@2.2.0
		slab@0.4.9
		smallvec@1.15.0
		socket2@0.5.9
		spin@0.9.8
		spki@0.7.3
		stable_deref_trait@1.2.0
		subtle@2.6.1
		syn@1.0.109
		syn@2.0.100
		sync_wrapper@0.1.2
		synstructure@0.13.1
		system-configuration-sys@0.5.0
		system-configuration@0.5.1
		tempfile@3.19.1
		termcolor@1.4.1
		thiserror-impl@1.0.69
		thiserror@1.0.69
		tinystr@0.7.6
		tokio-native-tls@0.3.1
		tokio-util@0.7.14
		tokio@1.44.2
		tower-service@0.3.3
		tracing-core@0.1.33
		tracing@0.1.41
		try-lock@0.2.5
		typenum@1.18.0
		unicode-ident@1.0.18
		url@2.5.4
		utf16_iter@1.0.5
		utf8_iter@1.0.4
		uuid@1.16.0
		vcpkg@0.2.15
		version_check@0.9.5
		want@0.3.1
		wasi@0.11.0+wasi-snapshot-preview1
		wasi@0.14.2+wasi-0.2.4
		wasm-bindgen-backend@0.2.100
		wasm-bindgen-futures@0.4.50
		wasm-bindgen-macro-support@0.2.100
		wasm-bindgen-macro@0.2.100
		wasm-bindgen-shared@0.2.100
		wasm-bindgen@0.2.100
		web-sys@0.3.77
		winapi-util@0.1.9
		windows-sys@0.48.0
		windows-sys@0.52.0
		windows-sys@0.59.0
		windows-targets@0.48.5
		windows-targets@0.52.6
		windows_aarch64_gnullvm@0.48.5
		windows_aarch64_gnullvm@0.52.6
		windows_aarch64_msvc@0.48.5
		windows_aarch64_msvc@0.52.6
		windows_i686_gnu@0.48.5
		windows_i686_gnu@0.52.6
		windows_i686_gnullvm@0.52.6
		windows_i686_msvc@0.48.5
		windows_i686_msvc@0.52.6
		windows_x86_64_gnu@0.48.5
		windows_x86_64_gnu@0.52.6
		windows_x86_64_gnullvm@0.48.5
		windows_x86_64_gnullvm@0.52.6
		windows_x86_64_msvc@0.48.5
		windows_x86_64_msvc@0.52.6
		winreg@0.50.0
		wit-bindgen-rt@0.39.0
		write16@1.0.0
		writeable@0.5.5
		xmlparser@0.13.6
		yoke-derive@0.7.5
		yoke@0.7.5
		zerocopy-derive@0.8.24
		zerocopy@0.8.24
		zerofrom-derive@0.1.6
		zerofrom@0.1.6
		zeroize@1.8.1
		zerovec-derive@0.10.3
		zerovec@0.10.4
	"
fi

inherit cargo

DESCRIPTION="Prototype Omaha Rust implementation"
HOMEPAGE="https://github.com/flatcar/ue-rs"
SRC_URI+=" ${CARGO_CRATE_URIS}"

LICENSE="Apache-2.0"
SLOT="0"
IUSE="test"
RESTRICT="!test? ( test )"

DEPEND="dev-libs/openssl:0="
RDEPEND="
	${DEPEND}
"

src_unpack() {
	git-r3_src_unpack

	if [[ ${PV} == 9999 ]]; then
		cargo_live_src_unpack
	else
		cargo_src_unpack
	fi
}

src_compile() {
	cargo_src_compile $(usex test '' '--bin download_sysext')
}

src_install() {
	cargo_src_install $(usex test '' '--bin download_sysext')
}
