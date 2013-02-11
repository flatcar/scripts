# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/cgikit/cgikit-1.2.1-r1.ebuild,v 1.7 2012/07/01 18:31:42 armin76 Exp $

EAPI=2
USE_RUBY="ruby18"

inherit ruby-ng

DESCRIPTION="CGIKit is a web application framework written in Ruby. The architecture is similar to WebObjects"
HOMEPAGE="http://www.spice-of-life.net/cgikit/index_en.html"
SRC_URI="http://www.spice-of-life.net/cgikit/archive/${P}.tar.gz"
LICENSE="Ruby"
SLOT="0"
KEYWORDS="~amd64 ppc ppc64 x86 ~x86-fbsd"
IUSE="examples"

all_ruby_prepare() {
	grep -rl --null '#!/usr/local/bin/ruby' "${S}" | xargs -0 \
		sed -i -e 's:#!/usr/local/bin/ruby:#!/usr/bin/ruby:'
}

each_ruby_compile() {
	${RUBY} install.rb config || die
}

each_ruby_install() {
	${RUBY} install.rb install --prefix="${D}" || die
}

all_ruby_install() {
	dodoc CHANGES CHANGES.ja README README.ja

	insinto /usr/share/doc/${PF}
	doins -r docs
	doins -r examples
}
