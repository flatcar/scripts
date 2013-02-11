# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/fxruby/fxruby-1.6.20-r1.ebuild,v 1.11 2012/07/01 18:31:42 armin76 Exp $

EAPI=2
USE_RUBY="ruby18"

RUBY_FAKEGEM_NAME="fxruby"

RUBY_FAKEGEM_TASK_DOC="docs"

RUBY_FAKEGEM_EXTRADOC="History.txt index.html README README.txt TODO"

inherit multilib ruby-fakegem toolchain-funcs

DESCRIPTION="Ruby language binding to the FOX GUI toolkit"
HOMEPAGE="http://www.fxruby.org/"

LICENSE="LGPL-2.1"
SLOT="1.6"
KEYWORDS="amd64 hppa ppc ppc64 x86 ~x86-fbsd"
IUSE="examples doc"

DEPEND="x11-libs/fox:1.6
	>=x11-libs/fxscintilla-1.62-r1"
RDEPEND="${RDEPEND}"

# Tests fail with a memory corruption error. Restrict the tests for
# now. We did not run tests with older versions so we assume this is
# not a regression for now.
RESTRICT="test"
#ruby_add_bdepend "test? ( dev-ruby/ruby-opengl )"

ruby_add_bdepend "dev-ruby/hoe"

all_ruby_prepare() {
	sed -i -e '/\[:compile\]/d' Rakefile || die
	sed -i -e 's:libs, "fxscintilla":libs, "fxscintilla-1.6":g' \
		 ext/fox16/extconf.rb || die "sed error"
	einfo "Avoid -O0 builds"
	sed -i -e 's:-O0 -I:-I:' \
		ext/fox16/extconf.rb || die "Can't fix forced -O0"

	# Use our own metadata since the distributed version doesn't work
	# with recent rubygems, bug 396541
	rm ../metadata || die

	# Avoid a dependency on rake-compiler.
	sed -i -e '/extensiontask/ s:^:#:' -e '/Rake::ExtensionTask/,$ s:^:#:' Rakefile || die
}

each_ruby_configure() {
	${RUBY} -Cext/fox16 extconf.rb || die
}

each_ruby_compile() {
	CXX=$(tc-getCXX) emake -Cext/fox16 || die
	cp ext/fox16/fox16$(get_modname) lib/ || die
}

all_ruby_install() {
	all_fakegem_install

	if use examples; then
		for dir in sample samples example examples; do
			if [ -d ${dir} ] ; then
				dodir /usr/share/doc/${PF}
				cp -pPR ${dir} "${D}"/usr/share/doc/${PF} || die "cp failed"
			fi
		done
	fi
}
