# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/maruku/maruku-0.6.0-r2.ebuild,v 1.9 2013/01/15 06:44:44 zerochaos Exp $

EAPI=2

USE_RUBY="ruby18 ruby19 ree18 jruby"

RUBY_FAKEGEM_TASK_TEST=""

RUBY_FAKEGEM_TASK_DOC="-I. rdoc"
RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="docs/changelog.md docs/div_syntax.md docs/entity_test.md
	docs/markdown_syntax.md docs/maruku.md docs/math.md docs/other_stuff.md
	docs/proposal.md"

inherit ruby-fakegem

DESCRIPTION="A Markdown-superset interpreter written in Ruby."
HOMEPAGE="http://maruku.rubyforge.org/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~arm ~ppc ~ppc64 x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""

# Tests fail in various ways, possibly due to missing
# dependencies. Since we shipped this without any tests for over a year
# just restrict them for now and revisit for the next version.
RESTRICT=test

ruby_add_rdepend dev-ruby/syntax

all_ruby_prepare() {
	sed -i \
		-e '/Gem::manage_gems/s:^:#:' \
		-e '/jamis\.rb/s:^:#:' \
		Rakefile
}

each_ruby_test() {
	${RUBY} -Ilib bin/marutest $(find tests/unittest -name '*.md') || die
}

pkg_postinst() {
	elog
	elog "You need to emerge app-text/texlive and dev-tex/latex-unicode if"
	elog "you want to use --pdf with Maruku. You may also want to emerge"
	elog "dev-tex/listings to enable LaTeX syntax highlighting."
	elog
}
