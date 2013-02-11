# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/oniguruma/oniguruma-1.1.0-r2.ebuild,v 1.1 2010/06/05 10:59:26 graaff Exp $

EAPI="2"
USE_RUBY="ruby18"

RUBY_FAKEGEM_TASK_DOC="docs"
RUBY_FAKEGEM_DOCDIR="doc"

RUBY_FAKEGEM_EXTRADOC="History.txt README.txt Syntax.txt"

inherit ruby-fakegem

DESCRIPTION="Ruby bindings to the Oniguruma"
HOMEPAGE="http://oniguruma.rubyforge.org/"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~x86-solaris"
IUSE=""

DEPEND="${DEPEND} dev-libs/oniguruma"
RDEPEND="${RDEPEND} dev-libs/oniguruma"

RUBY_PATCHES=( "${P}-unmonkey.patch" )

ruby_add_bdepend "
	doc? ( dev-ruby/hoe )
	test? (
		dev-ruby/hoe
		virtual/ruby-test-unit
	)"

each_ruby_configure() {
	pushd ext >& /dev/null
	${RUBY} extconf.rb
	popd >& /dev/null
}

each_ruby_compile() {
	pushd ext >& /dev/null
	emake || die "Compilation failed."
	popd >& /dev/null
	mv ext/oregexp.so lib || die "Unable to move oregexp.so"
}

each_ruby_install() {
	each_fakegem_install
}
