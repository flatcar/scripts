# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-taglib/ruby-taglib-1.1-r1.ebuild,v 1.1 2010/07/11 09:04:51 graaff Exp $

EAPI=2
USE_RUBY="ruby18"

inherit ruby-ng

DESCRIPTION="Ruby bindings for the taglib, allowing to access MP3, OGG, and FLAC tags"
HOMEPAGE="http://www.hakubi.us/ruby-taglib/"
SRC_URI="http://www.hakubi.us/ruby-taglib/${P}.tar.bz2"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE=""

RDEPEND="${RDEPEND} media-libs/taglib"

each_ruby_install() {
	${RUBY} setup.rb config --prefix="${D}"/usr || die
	${RUBY} setup.rb install || die
}

all_ruby_install() {
	dodoc README
}
