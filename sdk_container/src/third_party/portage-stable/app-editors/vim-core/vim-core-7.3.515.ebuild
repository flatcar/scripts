# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-editors/vim-core/vim-core-7.3.515.ebuild,v 1.1 2012/05/02 18:37:26 lack Exp $

EAPI=3
VIM_VERSION="7.3"
inherit vim

VIM_CORE_GENTOO_PATCHES="vim-core-${VIM_VERSION}-gentoo-patches-r1.tar.bz2"
VIM_ORG_PATCHES="vim-patches-${PV}.patch.bz2"
VIMRC_FILE_SUFFIX="-r4"

SRC_URI="ftp://ftp.vim.org/pub/vim/unix/vim-${VIM_VERSION}.tar.bz2
	http://dev.gentoo.org/~lack/vim/${VIM_CORE_GENTOO_PATCHES}
	http://dev.gentoo.org/~lack/vim/${VIM_ORG_PATCHES}"

S="${WORKDIR}/vim${VIM_VERSION/.}"
DESCRIPTION="vim and gvim shared files"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~ppc-aix ~amd64-fbsd ~sparc-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~hppa-hpux ~ia64-hpux ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""
