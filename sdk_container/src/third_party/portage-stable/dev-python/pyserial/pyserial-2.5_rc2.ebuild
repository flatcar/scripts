# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/pyserial/pyserial-2.5_rc2.ebuild,v 1.5 2010/02/13 16:36:58 armin76 Exp $

EAPI="2"
SUPPORT_PYTHON_ABIS="1"

inherit distutils

MY_P="${PN}-${PV/_/-}"

DESCRIPTION="Python Serial Port Extension"
HOMEPAGE="http://pyserial.sourceforge.net/ http://pyserial.wiki.sourceforge.net/pySerial http://pypi.python.org/pypi/pyserial"
SRC_URI="http://pypi.python.org/packages/source/${PN:0:1}/${PN}/${MY_P}.tar.gz"

LICENSE="PYTHON"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd"
IUSE=""

DEPEND=""
RDEPEND=""

DOCS="CHANGES.txt"
PYTHON_MODNAME="serial"

S="${WORKDIR}/${MY_P}"
