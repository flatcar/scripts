# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/flickr/flickr-1.0.2-r5.ebuild,v 1.1 2013/02/02 16:16:53 flameeyes Exp $

EAPI=5
USE_RUBY="ruby18 ruby19 jruby"

RUBY_FAKEGEM_RECIPE_TEST="none"
RUBY_FAKEGEM_RECIPE_DOC="none"

inherit ruby-fakegem

DESCRIPTION="An insanely easy interface to the Flickr photo-sharing service."
HOMEPAGE="http://rubyforge.org/projects/flickr/"
SRC_URI="mirror://gentoo/${P}-gentoo.tar.bz2"

S="${WORKDIR}/${P}-gentoo"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

ruby_add_rdepend "dev-ruby/xml-simple"

all_ruby_prepare() {
	cd "${S}"/lib
	epatch "${FILESDIR}/${P}-fix.patch"
	epatch "${FILESDIR}/${P}-typo.patch"
}
