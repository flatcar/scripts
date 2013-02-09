# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/jpeg/jpeg-0.ebuild,v 1.9 2012/05/21 14:41:53 ssuominen Exp $

EAPI=4

DESCRIPTION="A virtual for the JPEG implementation"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~sparc-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="static-libs"

RDEPEND="|| (
		>=media-libs/libjpeg-turbo-1.2.0:0[static-libs?]
		>=media-libs/jpeg-8d:0[static-libs?]
		)"
DEPEND=""
