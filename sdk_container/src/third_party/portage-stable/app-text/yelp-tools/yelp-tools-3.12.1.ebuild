# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-text/yelp-tools/yelp-tools-3.12.1.ebuild,v 1.5 2014/08/07 17:55:20 jer Exp $

EAPI="5"
GCONF_DEBUG="no"

inherit gnome2

DESCRIPTION="Collection of tools for building and converting documentation"
HOMEPAGE="http://www.gnome.org/"

LICENSE="|| ( GPL-2+ freedist ) GPL-2+" # yelp.m4 is GPL2 || freely distributable
SLOT="0"
KEYWORDS="~alpha amd64 ~arm hppa ~ia64 ~mips ppc ~ppc64 ~s390 ~sh ~sparc x86 ~amd64-fbsd ~amd64-linux ~arm-linux ~x86-linux"
IUSE=""

RDEPEND="
	>=dev-libs/libxml2-2.6.12
	>=dev-libs/libxslt-1.1.8
	dev-util/itstool
	gnome-extra/yelp-xsl
	virtual/awk
"
DEPEND="${RDEPEND}
	virtual/pkgconfig
"
