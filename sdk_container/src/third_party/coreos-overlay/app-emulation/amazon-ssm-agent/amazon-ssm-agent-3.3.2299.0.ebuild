# Distributed under the terms of the GNU General Public License v2

EAPI=7

COREOS_GO_PACKAGE="${GITHUB_URI}"

inherit coreos-go-depend golang-vcs-snapshot systemd

EGO_PN="github.com/aws/${PN}"
DESCRIPTION="AWS Systems Manager Agent"
HOMEPAGE="https://github.com/aws/amazon-ssm-agent"
LICENSE="Apache-2.0"
SRC_URI="https://${EGO_PN}/archive/${PV}.tar.gz -> ${P}.tar.gz ${EGO_VENDOR_URI}"
SLOT="0"
KEYWORDS="amd64 arm64"

S="${WORKDIR}/${PN}-${PV}/src/${EGO_PN}"

src_prepare() {
	default
	ln -s ${PWD}/vendor/src/* ${PWD}/vendor/
}

src_compile() {
	go_export

	# set agent release version
	BRAZIL_PACKAGE_VERSION=${PV} ${EGO} run ./agent/version/versiongenerator/version-gen.go
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
