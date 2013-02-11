# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/pyrit/pyrit-0.4.0.ebuild,v 1.1 2012/03/29 16:46:45 maksbotan Exp $

EAPI=4

PYTHON_DEPEND="2:2.5"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="3.*"

inherit distutils eutils

DESCRIPTION="GPU-accelerated attack against WPA-PSK authentication"
HOMEPAGE="http://code.google.com/p/pyrit/"
SRC_URI="http://pyrit.googlecode.com/files/${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="cuda opencl test"

DEPEND="dev-libs/openssl
	net-libs/libpcap
	test? ( >=net-analyzer/scapy-2 )"
RDEPEND=">=net-analyzer/scapy-2
	opencl? ( net-wireless/cpyrit-opencl )
	cuda? ( net-wireless/cpyrit-cuda )"

src_test() {
	cd test
	testing() {
		PYTHONPATH=$(ls -d "${S}"/build-${PYTHON_ABI}/lib*) $(PYTHON) test_pyrit.py
	}
	python_execute_function testing
}
