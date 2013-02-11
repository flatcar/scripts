# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/fusefs/fusefs-0.6.0-r1.ebuild,v 1.5 2012/05/01 18:24:19 armin76 Exp $

EAPI=2
USE_RUBY="ruby18"

inherit ruby-ng

IUSE=""
DESCRIPTION="Define file systems right in Ruby"
HOMEPAGE="http://rubyforge.org/projects/fusefs/"
SRC_URI="http://rubyforge.org/frs/download.php/7830/${P}.tar.gz"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ppc64 x86"

DEPEND="${DEPEND} >=sys-fs/fuse-2.3"

each_ruby_configure() {
	${RUBY} setup.rb config --prefix=/usr || die
	${RUBY} setup.rb setup || die
}

each_ruby_install() {
	${RUBY} setup.rb config --prefix="${D}" || die
	${RUBY} setup.rb install || die
}

all_ruby_install() {
	dodoc API.txt Changes.txt README.txt TODO || die

	insinto /usr/share/doc/${PF}
	doins -r sample || die
}
