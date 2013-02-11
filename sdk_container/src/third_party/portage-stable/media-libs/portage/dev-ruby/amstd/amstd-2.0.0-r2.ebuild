# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/amstd/amstd-2.0.0-r2.ebuild,v 1.8 2012/03/08 17:47:03 naota Exp $

EAPI=2
USE_RUBY="ruby18"

inherit ruby-ng

DESCRIPTION="Ruby utility collection by Minero Aoki"
HOMEPAGE="http://www.loveruby.net/en/amstd.html"
SRC_URI="http://www.loveruby.net/archive/amstd/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 hppa ia64 ~mips ppc ppc64 sparc x86 ~x86-fbsd"

IUSE=""

each_ruby_configure() {
	${RUBY} install.rb config --prefix=/usr || die "config failed"
	${RUBY} install.rb setup || die "setup failed"
}

each_ruby_install() {
	${RUBY} install.rb config --prefix="${D}"/usr || die "config failed"
	${RUBY} install.rb install || die "install failed"
}

all_ruby_install() {
	dodoc README.en README.ja manual.rd.ja || die
}
