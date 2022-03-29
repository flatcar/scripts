# Copyright 2017-2018 CoreOS, Inc.
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: coreos-cargo.eclass
# @MAINTAINER:
# team-os@coreos.com
# @AUTHOR:
# David Michael <david.michael@coreos.com>
# @BLURB: cargo cross-compilation support for CoreOS/ChromeOS targets

if [[ -z ${_COREOS_CARGO_ECLASS} ]]; then
_COREOS_CARGO_ECLASS=1

# XXX: Don't require host dependencies to also be in the sysroot.
CATEGORY=dev-util PN=cargo inherit cargo
inherit toolchain-funcs

EXPORT_FUNCTIONS src_unpack

# @FUNCTION: coreos-cargo_src_unpack
# @DESCRIPTION:
# This amends the src_unpack from cargo.eclass to add support for Rust
# cross-compiling to the ChromeOS targets.  It maps the host triplet to
# one built into rustc and uses the board root as its sysroot.
coreos-cargo_src_unpack() {
	debug-print-function ${FUNCNAME} "$@"
	cargo_src_unpack "$@"

	[[ ${CBUILD:-${CHOST}} != ${CHOST} ]] || return 0

	# Map the SDK host triplet to one that is built into rustc.
	function rust_builtin_target() case "$1" in
		aarch64-*-linux-gnu) echo aarch64-unknown-linux-gnu ;;
		x86_64-*-linux-gnu) echo x86_64-unknown-linux-gnu ;;
		*) die "Unknown host triplet: $1" ;;
	esac

	# Set the gcc-rs flags for cross-compiling.
	export TARGET_CFLAGS="${CFLAGS}"
	export TARGET_CXXFLAGS="${CXXFLAGS}"

	# Wrap ar for gcc-rs to work around rust-lang/cargo#4456.
	export TARGET_AR="${T}/rustproof-ar"
	cat <<- EOF > "${TARGET_AR}" && chmod 0755 "${TARGET_AR}"
	#!/bin/sh
	unset LD_LIBRARY_PATH
	exec $(tc-getAR) "\$@"
	EOF

	# Wrap gcc for gcc-rs to work around rust-lang/cargo#4456.
	export TARGET_CC="${T}/rustproof-cc"
	cat <<- EOF > "${TARGET_CC}" && chmod 0755 "${TARGET_CC}"
	#!/bin/sh
	unset LD_LIBRARY_PATH
	exec $(tc-getCC) "\$@"
	EOF

	# Wrap g++ for gcc-rs to work around rust-lang/cargo#4456.
	export TARGET_CXX="${T}/rustproof-cxx"
	cat <<- EOF > "${TARGET_CXX}" && chmod 0755 "${TARGET_CXX}"
	#!/bin/sh
	unset LD_LIBRARY_PATH
	exec $(tc-getCXX) "\$@"
	EOF

	# Create a compiler wrapper that uses a sysroot for cross-compiling.
	export RUSTC_WRAPPER="${T}/wrustc"
	cat <<- 'EOF' > "${RUSTC_WRAPPER}" && chmod 0755 "${RUSTC_WRAPPER}"
	#!/bin/bash -e
	rustc=${1:?Missing rustc command}
	shift
	xflags=()
	# rustlib is part of host rustc now, so no: [ "x$*" = "x${*#--target}" ] || xflags=( --sysroot="${ROOT:-/}usr" )
	exec "${rustc}" "${xflags[@]}" "$@"
	EOF

	# Compile for the built-in target, using the SDK cross-tools.
	export RUST_TARGET=$(rust_builtin_target "${CHOST}")
	local -a config_lines
	local build_amended=0
	local target_rust_target_amended=0
	local REPLY
	readonly b_header='[build]'
	readonly t_header="[target.${RUST_TARGET}]"
	readonly target_line="target = \"${RUST_TARGET}\""
	readonly ar_line="ar = \"${TARGET_AR}\""
	readonly linker_line="linker = \"${TARGET_CC}\""
	while read -r; do
		config_lines+=("${REPLY}")
		case "${REPLY}" in
			"${b_header}")
				config_lines+=("${target_line}")
				build_amended=1
				;;
			"${t_header}")
				config_lines+=("${ar_line}")
				config_lines+=("${linker_line}")
				target_rust_target_amended=1
				;;
		esac
	done <"${ECARGO_HOME}/config"
	if [[ "${build_amended}" -eq 0 ]]; then
	    config_lines+=('' "${b_header}" "${target_line}")
	fi
	if [[ "${target_rust_target_amended}" -eq 0 ]]; then
	    config_lines+=('' "${t_header}" "${ar_line}" "${linker_line}")
	fi
	printf '%s\n' "${config_lines[@]}" >"${ECARGO_HOME}/config"
}

fi
