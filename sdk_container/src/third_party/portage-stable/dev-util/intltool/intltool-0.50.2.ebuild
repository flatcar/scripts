# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-util/intltool/intltool-0.50.2.ebuild,v 1.12 2013/02/21 03:01:23 zmedico Exp $

EAPI=4

DESCRIPTION="Internationalization Tool Collection"
HOMEPAGE="http://edge.launchpad.net/intltool/"
SRC_URI="http://edge.launchpad.net/intltool/trunk/${PV}/+download/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~sparc-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~x86-interix ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""

DEPEND=">=dev-lang/perl-5.8.1
	dev-perl/XML-Parser"
RDEPEND="${DEPEND}
	sys-devel/gettext"

DOCS=( AUTHORS ChangeLog NEWS README TODO doc/I18N-HOWTO )
