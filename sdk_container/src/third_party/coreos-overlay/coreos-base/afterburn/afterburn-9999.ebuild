# Copyright (c) 2017 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

EGIT_REPO_URI="https://github.com/coreos/afterburn.git"

if [[ ${PV} == 9999 ]]; then
	KEYWORDS="~amd64 ~arm64"
	CRATES=""
else
	EGIT_COMMIT="0283c57f47b81871bf04e3c899344f8e73501744" # v5.7.0
	KEYWORDS="amd64 arm64"

	CRATES="
		addr2line@0.24.1
		adler2@2.0.0
		adler32@1.2.0
		ahash@0.8.11
		aho-corasick@1.1.3
		allocator-api2@0.2.18
		anstyle@1.0.8
		anyhow@1.0.89
		arc-swap@1.7.1
		assert-json-diff@2.0.2
		async-broadcast@0.7.1
		async-channel@2.3.1
		async-executor@1.13.1
		async-fs@2.1.2
		async-io@2.3.4
		async-lock@3.4.0
		async-process@2.3.0
		async-recursion@1.1.1
		async-signal@0.2.10
		async-task@4.7.1
		async-trait@0.1.82
		atomic-waker@1.1.2
		autocfg@1.3.0
		backtrace@0.3.74
		base64@0.21.7
		base64@0.22.1
		bitflags@2.6.0
		block-buffer@0.10.4
		blocking@1.6.1
		bumpalo@3.16.0
		byteorder@1.5.0
		bytes@1.7.2
		cc@1.1.21
		cfg-if@1.0.0
		cfg_aliases@0.2.1
		charset@0.1.5
		clap@4.5.17
		clap_builder@4.5.17
		clap_derive@4.5.13
		clap_lex@0.7.2
		colored@2.1.0
		concurrent-queue@2.5.0
		core-foundation@0.9.4
		core-foundation-sys@0.8.7
		core2@0.4.0
		cpufeatures@0.2.14
		crc32fast@1.4.2
		crossbeam-channel@0.5.13
		crossbeam-utils@0.8.20
		crypto-common@0.1.6
		dary_heap@0.3.6
		data-encoding@2.6.0
		deranged@0.3.11
		digest@0.10.7
		dirs-next@2.0.0
		dirs-sys-next@0.1.2
		encoding_rs@0.8.34
		endi@1.1.0
		enumflags2@0.7.10
		enumflags2_derive@0.7.10
		equivalent@1.0.1
		errno@0.3.9
		event-listener@5.3.1
		event-listener-strategy@0.5.2
		fastrand@2.1.1
		fnv@1.0.7
		foreign-types@0.3.2
		foreign-types-shared@0.1.1
		form_urlencoded@1.2.1
		futures-channel@0.3.30
		futures-core@0.3.30
		futures-io@0.3.30
		futures-lite@2.3.0
		futures-sink@0.3.30
		futures-task@0.3.30
		futures-util@0.3.30
		generic-array@0.14.7
		getrandom@0.2.15
		gimli@0.31.0
		h2@0.4.6
		hashbrown@0.14.5
		heck@0.5.0
		hermit-abi@0.3.9
		hermit-abi@0.4.0
		hex@0.4.3
		hmac@0.12.1
		hostname@0.4.0
		http@1.1.0
		http-body@1.0.1
		http-body-util@0.1.2
		httparse@1.9.4
		httpdate@1.0.3
		hyper@1.4.1
		hyper-rustls@0.27.3
		hyper-tls@0.6.0
		hyper-util@0.1.8
		idna@0.5.0
		indexmap@2.5.0
		ipnet@2.10.0
		ipnetwork@0.20.0
		is-terminal@0.4.13
		itoa@1.0.11
		js-sys@0.3.70
		lazy_static@1.5.0
		libc@0.2.158
		libflate@2.1.0
		libflate_lz77@2.1.0
		libredox@0.1.3
		libsystemd@0.7.0
		linux-raw-sys@0.4.14
		lock_api@0.4.12
		log@0.4.22
		mailparse@0.15.0
		maplit@1.0.2
		md-5@0.10.6
		memchr@2.7.4
		memoffset@0.9.1
		mime@0.3.17
		minimal-lexical@0.2.1
		miniz_oxide@0.8.0
		mio@1.0.2
		mockito@1.5.0
		native-tls@0.2.12
		nix@0.27.1
		nix@0.29.0
		no-std-net@0.6.0
		nom@7.1.3
		num-conv@0.1.0
		object@0.36.4
		once_cell@1.19.0
		openssh-keys@0.6.4
		openssl@0.10.70
		openssl-macros@0.1.1
		openssl-probe@0.1.5
		openssl-sys@0.9.105
		ordered-stream@0.2.0
		parking@2.2.1
		parking_lot@0.12.3
		parking_lot_core@0.9.10
		percent-encoding@2.3.1
		pin-project@1.1.5
		pin-project-internal@1.1.5
		pin-project-lite@0.2.14
		pin-utils@0.1.0
		piper@0.2.4
		pkg-config@0.3.30
		pnet_base@0.35.0
		pnet_datalink@0.35.0
		pnet_sys@0.35.0
		polling@3.7.3
		powerfmt@0.2.0
		ppv-lite86@0.2.20
		proc-macro-crate@3.2.0
		proc-macro2@1.0.86
		quote@1.0.37
		quoted_printable@0.5.1
		rand@0.8.5
		rand_chacha@0.3.1
		rand_core@0.6.4
		redox_syscall@0.5.4
		redox_users@0.4.6
		regex@1.10.6
		regex-automata@0.4.7
		regex-syntax@0.8.4
		reqwest@0.12.7
		ring@0.17.8
		rle-decode-fast@1.0.3
		rustc-demangle@0.1.24
		rustix@0.38.37
		rustls@0.23.13
		rustls-pemfile@2.1.3
		rustls-pki-types@1.8.0
		rustls-webpki@0.102.8
		rustversion@1.0.17
		ryu@1.0.18
		schannel@0.1.24
		scopeguard@1.2.0
		security-framework@2.11.1
		security-framework-sys@2.11.1
		serde@1.0.210
		serde-xml-rs@0.6.0
		serde_derive@1.0.210
		serde_json@1.0.128
		serde_repr@0.1.19
		serde_urlencoded@0.7.1
		serde_yaml@0.9.34+deprecated
		sha1@0.10.6
		sha2@0.10.8
		shlex@1.3.0
		signal-hook-registry@1.4.2
		similar@2.6.0
		slab@0.4.9
		slog@2.7.0
		slog-async@2.8.0
		slog-scope@4.4.0
		slog-term@2.9.1
		smallvec@1.13.2
		socket2@0.5.7
		spin@0.9.8
		static_assertions@1.1.0
		strsim@0.11.1
		subtle@2.6.1
		syn@2.0.77
		sync_wrapper@1.0.1
		system-configuration@0.6.1
		system-configuration-sys@0.6.0
		take_mut@0.2.2
		tempfile@3.12.0
		term@0.7.0
		terminal_size@0.3.0
		thiserror@1.0.63
		thiserror-impl@1.0.63
		thread_local@1.1.8
		time@0.3.36
		time-core@0.1.2
		time-macros@0.2.18
		tinyvec@1.8.0
		tinyvec_macros@0.1.1
		tokio@1.40.0
		tokio-native-tls@0.3.1
		tokio-rustls@0.26.0
		tokio-util@0.7.12
		toml_datetime@0.6.8
		toml_edit@0.22.21
		tower@0.4.13
		tower-layer@0.3.3
		tower-service@0.3.3
		tracing@0.1.40
		tracing-attributes@0.1.27
		tracing-core@0.1.32
		try-lock@0.2.5
		typenum@1.17.0
		uds_windows@1.1.0
		unicode-bidi@0.3.15
		unicode-ident@1.0.13
		unicode-normalization@0.1.24
		unsafe-libyaml@0.2.11
		untrusted@0.9.0
		url@2.5.2
		uuid@1.10.0
		uzers@0.12.1
		vcpkg@0.2.15
		version_check@0.9.5
		vmw_backdoor@0.2.4
		want@0.3.1
		wasi@0.11.0+wasi-snapshot-preview1
		wasm-bindgen@0.2.93
		wasm-bindgen-backend@0.2.93
		wasm-bindgen-futures@0.4.43
		wasm-bindgen-macro@0.2.93
		wasm-bindgen-macro-support@0.2.93
		wasm-bindgen-shared@0.2.93
		web-sys@0.3.70
		winapi@0.3.9
		winapi-i686-pc-windows-gnu@0.4.0
		winapi-x86_64-pc-windows-gnu@0.4.0
		windows@0.52.0
		windows-core@0.52.0
		windows-registry@0.2.0
		windows-result@0.2.0
		windows-strings@0.1.0
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
		winnow@0.6.18
		xdg-home@1.3.0
		xml-rs@0.8.22
		zbus@4.4.0
		zbus_macros@4.4.0
		zbus_names@3.0.0
		zerocopy@0.7.35
		zerocopy-derive@0.7.35
		zeroize@1.8.1
		zvariant@4.2.0
		zvariant_derive@4.2.0
		zvariant_utils@2.1.0
"

fi

inherit cargo git-r3 systemd

DESCRIPTION="A tool for collecting instance metadata from various providers"
HOMEPAGE="https://github.com/coreos/afterburn"
SRC_URI="${CARGO_CRATE_URIS}"

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
	"${FILESDIR}"/0003-Cargo-reduce-binary-size-for-release-profile.patch
	"${FILESDIR}"/0004-build-deps-bump-openssl-from-0.10.66-to-0.10.70.patch
)

src_unpack() {
	git-r3_src_unpack

	if [[ ${PV} == 9999 ]]; then
		cargo_live_src_unpack
	else
		cargo_src_unpack
	fi
}

src_compile() {
	cargo_src_compile --features cl-legacy
}

src_install() {
	cargo_src_install --features cl-legacy
	mv "${D}/usr/bin/afterburn" "${D}/usr/bin/coreos-metadata"

	systemd_dounit "${FILESDIR}/coreos-metadata.service"
	systemd_dounit "${FILESDIR}/coreos-metadata-sshkeys@.service"
}

src_test() {
	cargo_src_test --features cl-legacy
}
