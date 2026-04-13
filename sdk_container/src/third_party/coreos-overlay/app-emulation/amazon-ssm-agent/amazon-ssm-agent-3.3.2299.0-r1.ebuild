# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-env go-module sysroot systemd

DESCRIPTION="AWS Systems Manager Agent"
HOMEPAGE="https://github.com/aws/amazon-ssm-agent"
SRC_URI="https://github.com/aws/amazon-ssm-agent/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 arm64"

src_prepare() {
	default
	# Drop clearing of GOARCH and GOOS - it causes go run to
	# create a binary for CBUILD, but then go run also invokes the
	# binary using qemu-CHOST, because we use -exec flag when
	# cross-compiling
	sed -i -e 's/GOARCH= GOOS= go run/go run/' makefile || die
}

src_compile() {
	# build all the tools
	if [[ "${ARCH}" == "arm64" ]]; then
		emake build-arm64
	else
		emake build-linux
	fi
}

src_install() {
	# Folder is like bin/linux_amd64/
	dobin bin/*/*
	insinto "/usr/share/amazon/ssm"
	newins seelog_unix.xml seelog.xml.template
	doins amazon-ssm-agent.json.template

	systemd_dounit packaging/linux/amazon-ssm-agent.service
}
