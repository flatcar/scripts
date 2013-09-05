# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-perl/File-Slurp/File-Slurp-9999.190.0.ebuild,v 1.9 2013/09/04 07:26:35 ago Exp $

EAPI=4

MODULE_AUTHOR=URI
MODULE_VERSION=9999.19
inherit perl-module

DESCRIPTION="Efficient Reading/Writing of Complete Files"

SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~m68k ~mips ppc ~ppc64 ~s390 ~sh sparc ~x86 ~ppc-aix ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~x86-solaris"
IUSE=""

SRC_TEST="do"

mydoc="extras/slurp_article.pod"
