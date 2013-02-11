# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-bz2/ruby-bz2-0.2.2-r1.ebuild,v 1.2 2012/09/16 07:57:37 graaff Exp $

EAPI=4

# ruby19 → configuration failures; jruby → compiled extension.
USE_RUBY="ruby18 ree18"

inherit ruby-ng

MY_P="${P/ruby-}"

DESCRIPTION="Ruby interface to libbz2"
HOMEPAGE="http://moulon.inra.fr/ruby/bz2.html"
SRC_URI="ftp://moulon.inra.fr/pub/ruby/${MY_P}.tar.gz"

LICENSE="Ruby"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~x86-fbsd"
IUSE="doc"

RUBY_S="${MY_P}"

RDEPEND="app-arch/bzip2"
DEPEND="${RDEPEND}"

each_ruby_configure() {
	${RUBY} extconf.rb || die "extconf failed"
}

each_ruby_compile() {
	emake || die "emake failed"

	if use doc; then
		emake rdoc || die "rdoc failed"
	fi
}

each_ruby_test() {
	emake test || die "tests failed"
}

each_ruby_install() {
	doruby bz2.so

	dodoc README.en || die
	dohtml bz2.html || die

	if use doc; then
		pushd docs &>/dev/null
		docinto api
		dohtml -r doc || die
		popd &>/dev/null
	fi
}
