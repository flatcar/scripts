# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/xmpp4r/xmpp4r-0.5-r1.ebuild,v 1.3 2011/01/26 10:44:18 fauli Exp $

EAPI="2"
USE_RUBY="ruby18"

RUBY_FAKEGEM_EXTRADOC="README.rdoc README_ruby19.txt CHANGELOG"

inherit ruby-fakegem

DESCRIPTION="An XMPP library for Ruby"
HOMEPAGE="http://home.gna.org/xmpp4r/"

LICENSE="Ruby"
SLOT="0"
KEYWORDS="amd64 ~ppc ~ppc64 x86"
IUSE="examples"

# Tests fail, reported upstream: http://github.com/ln/xmpp4r/issues/issue/6
RESTRICT="test"

all_ruby_install() {
	all_fakegem_install

	if use examples; then
		insinto /usr/share/doc/${PF}
		doins -r data/doc/xmpp4r/examples
	fi
}
