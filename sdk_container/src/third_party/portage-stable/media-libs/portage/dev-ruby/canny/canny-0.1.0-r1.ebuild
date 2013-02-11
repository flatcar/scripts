# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/canny/canny-0.1.0-r1.ebuild,v 1.6 2012/05/01 18:24:20 armin76 Exp $

EAPI=2
USE_RUBY="ruby18"

inherit ruby-ng

IUSE=""

DESCRIPTION="Canny is a template library for Ruby."
HOMEPAGE="http://canny.sourceforge.net/"
SRC_URI="mirror://sourceforge/canny/${P}.tar.gz"

KEYWORDS="~amd64 ~ppc ppc64 x86 ~x86-fbsd"
LICENSE="LGPL-2.1"
SLOT="0"

each_ruby_configure() {
	ruby setup.rb config || die "setup.rb config failed"
	ruby setup.rb setup || die "setup.rb setup failed"
}

each_ruby_install() {
	ruby setup.rb config --prefix="${D}/usr" || die "setup.rb config failed"
	ruby setup.rb install || die "setup.rb install failed"
}

all_ruby_install() {
	dodoc ChangeLog README* example.rb templates/*
}
