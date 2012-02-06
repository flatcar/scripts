# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/mta/mta-0.ebuild,v 1.6 2011/12/08 19:49:59 grobian Exp $

EAPI=3

DESCRIPTION="Virtual for Message Transfer Agents"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~sparc-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""

DEPEND=""

# mail-mta/citadel is from sunrise
RDEPEND="|| (	>=mail-mta/ssmtp-2.64-r2[mta]
				<mail-mta/ssmtp-2.64-r2
				mail-mta/courier
				mail-mta/esmtp
				mail-mta/exim
				mail-mta/mini-qmail
				>=mail-mta/msmtp-1.4.19-r1[mta]
				<mail-mta/msmtp-1.4.19-r1
				mail-mta/nbsmtp
				mail-mta/netqmail
				mail-mta/nullmailer
				mail-mta/postfix
				mail-mta/qmail-ldap
				mail-mta/sendmail
				mail-mta/citadel[-postfix] )"
