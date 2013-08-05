# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/clang/clang-3.3-r100.ebuild,v 1.2 2013/07/31 21:51:47 aballier Exp $

EAPI=5

DESCRIPTION="C language family frontend for LLVM (meta-ebuild)"
HOMEPAGE="http://clang.llvm.org/"
SRC_URI=""

LICENSE="UoI-NCSA"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86 ~amd64-fbsd ~x86-fbsd ~x64-freebsd ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos"
IUSE="debug multitarget python +static-analyzer"

RDEPEND="~sys-devel/llvm-${PV}[clang(-),debug=,multitarget=,python=,static-analyzer=]"

# Please keep this package around since it's quite likely that we'll
# return to separate LLVM & clang ebuilds when the cmake build system
# is complete.
