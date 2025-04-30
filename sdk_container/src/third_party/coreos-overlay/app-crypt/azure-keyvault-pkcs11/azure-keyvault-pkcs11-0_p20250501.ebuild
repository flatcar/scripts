# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

COMMIT="200e1f533e65c35009cc2ec256446cff1314b68b"
DESCRIPTION="PKCS#11 module for Azure Key Vault"
HOMEPAGE="https://github.com/jepio/azure_keyvault_pkcs11"
SRC_URI="https://github.com/jepio/azure_keyvault_pkcs11/archive/${COMMIT}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN}-${COMMIT}"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# libcurl is only NEEDED because of the Azure SDK.
RDEPEND="
	dev-cpp/azure-core:=
	dev-cpp/azure-identity:=
	dev-cpp/azure-security-keyvault-certificates:=
	dev-cpp/azure-security-keyvault-keys:=
	dev-libs/json-c:=
	dev-libs/openssl:=
"
DEPEND="
	${RDEPEND}
	app-crypt/p11-kit
"
BDEPEND="
	virtual/pkgconfig
"
