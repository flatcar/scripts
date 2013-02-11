# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-svg/ruby-svg-1.0.3-r2.ebuild,v 1.5 2012/05/01 18:24:28 armin76 Exp $

EAPI=2
USE_RUBY="ruby18"

inherit ruby-ng

DESCRIPTION="Ruby SVG Generator"
HOMEPAGE="http://ruby-svg.sourceforge.jp/"
SRC_URI="http://downloads.sourceforge.jp/ruby-svg/2288/${P}.tar.gz"
LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 ppc x86"
IUSE="doc examples"

ruby_add_bdepend "doc? ( dev-ruby/rdtool )"

each_ruby_configure() {
	${RUBY} install.rb config --prefix=/usr || die
}

each_ruby_compile() {
	${RUBY} install.rb setup || die
}

each_ruby_install() {
	${RUBY} install.rb config --prefix="${D}"/usr || die
	${RUBY} install.rb install || die
}

all_ruby_install() {
	if use doc ; then
		rd2 README.en.rd > README.en.html
		rd2 README.ja.rd > README.ja.html

		dohtml *.html || die
	fi

	if use examples ; then
		insinto /usr/share/doc/${PF}/examples
		doins sample/*
	fi
}
