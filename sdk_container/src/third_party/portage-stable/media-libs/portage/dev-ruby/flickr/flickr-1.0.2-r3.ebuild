# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/flickr/flickr-1.0.2-r3.ebuild,v 1.3 2011/12/14 17:39:35 ago Exp $

EAPI=2
USE_RUBY="ruby18 jruby"

inherit ruby-fakegem

DESCRIPTION="An insanely easy interface to the Flickr photo-sharing service."
HOMEPAGE="http://rubyforge.org/projects/flickr/"
SRC_URI="mirror://gentoo/${P}-gentoo.tar.bz2"

S="${WORKDIR}/${P}-gentoo"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

# Tests fail for now, they don't seem to be designed to work just yet
RESTRICT="test"

ruby_add_rdepend dev-ruby/xml-simple

all_ruby_prepare() {
	cd "${S}"/lib
	epatch "${FILESDIR}/${P}-fix.patch"
	epatch "${FILESDIR}/${P}-typo.patch"
}

all_ruby_install() {
	if use doc; then
		dohtml -r "${S}"/doc/* || die "dohtml failed"
	fi

	dohtml "${S}"/index.html || die "dohtml failed"
}
