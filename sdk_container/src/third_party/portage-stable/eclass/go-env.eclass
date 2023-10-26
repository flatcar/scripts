# Copyright 2023 Flatcar Maintainers
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: go-env.eclass
# @MAINTAINER:
# Flatcar Maintainers <infra@flatcar.org>
# @AUTHOR:
# Flatcar Maintainers <infra@flatcar.org>
# @SUPPORTED_EAPIS: 7 8
# @BLURB: Helper eclass for setting the Go compile environment. Required for cross-compiling.
# @DESCRIPTION:
# This eclass includes a helper function for setting the compile environment for Go ebuilds.
# Intended to be called by other Go eclasses in an early build stage, e.g. src_unpack.

if [[ -z ${_GO_ENV_ECLASS} ]]; then
_GO_ENV_ECLASS=1

inherit toolchain-funcs

# Set up basic compile environment: CC, CXX, and GOARCH.
# Required for cross-compiling with crossdev.
# If not set, host defaults will be used and the resulting binaries are host arch.
# (e.g. "emerge-aarch64-cross-linux-gnu foo" run on x86_64 will emerge "foo" for x86_64
#  instead of aarch64)
go-env_set_compile_environment() {
	_arch() {
		local arch=$(tc-arch "${CHOST}}")
		case "${arch}" in
			x86)	echo "386" ;;
			x64-*)	echo "amd64" ;;
			ppc64)  if [[ "$(tc-endian "${${CHOST}}")" = "big" ]] then
						echo "ppc64"
					else
						echo "ppc64le"
					fi ;;
			*)	echo "${arch}" ;;
		esac
	}

	CC="$(tc-getCC)"
	CXX="$(tc-getCXX)"
	# Needs explicit export to arrive in go environment.
	export GOARCH="$(_arch)"
}

fi
