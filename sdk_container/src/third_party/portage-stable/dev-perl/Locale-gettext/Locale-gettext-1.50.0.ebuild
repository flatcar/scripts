# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-perl/Locale-gettext/Locale-gettext-1.50.0.ebuild,v 1.3 2012/03/24 15:41:10 grobian Exp $

EAPI=4

MY_PN=gettext
MODULE_AUTHOR=PVANDRY
MODULE_VERSION=1.05
inherit perl-module

DESCRIPTION="A Perl module for accessing the GNU locale utilities"

SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd ~amd64-linux ~ia64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE=""

DEPEND="sys-devel/gettext"
RDEPEND="${DEPEND}"

PATCHES=( "${FILESDIR}"/compatibility-with-POSIX-module.diff )

# Disabling the tests - not ready for prime time - mcummings
#SRC_TEST="do"
