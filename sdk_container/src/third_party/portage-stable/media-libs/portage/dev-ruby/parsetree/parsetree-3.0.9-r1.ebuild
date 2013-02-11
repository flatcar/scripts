# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/parsetree/parsetree-3.0.9-r1.ebuild,v 1.3 2013/01/15 06:07:04 zerochaos Exp $

EAPI=4

USE_RUBY="ruby18 ree18"

RUBY_FAKEGEM_NAME="ParseTree"

RUBY_FAKEGEM_TASK_DOC="docs"
RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="README.txt History.txt"

RUBY_FAKEGEM_GEMSPEC=${RUBY_FAKEGEM_NAME}.gemspec

inherit multilib ruby-fakegem

DESCRIPTION="ParseTree extracts the parse tree for a Class or method and returns it as a s-expression."
HOMEPAGE="http://www.zenspider.com/ZSS/Products/ParseTree/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~x64-solaris ~x86-solaris"
IUSE=""

ruby_add_rdepend '
	>=dev-ruby/RubyInline-3.10.0
	>=dev-ruby/sexp_processor-3.0.0'
ruby_add_bdepend "
	test? (
		dev-ruby/hoe
		dev-ruby/hoe-seattlerb
		dev-ruby/minitest
		dev-ruby/ruby2ruby
	)
	doc? (
		dev-ruby/hoe
		dev-ruby/hoe-seattlerb
	)"

all_ruby_prepare() {
	# Fix USE=doc by removing the path that triggers running the tests
	# and thus building the extensions in the wrong way.
	sed -i -e '/require_paths/d' Rakefile || die
}

each_ruby_prepare() {
	# RubyInline employs a very stupid caching strategy solely based on
	# the public signatures of methods. Never mind bugs within the C
	# code... We add a dynamic method name to the parsetree interface
	# just so that we can guarantee compilation. Fixes #329497.
	epatch "${FILESDIR}/${PN}-3.0.6-timestamp.patch"
	sed -i -e "s/TIMESTAMP/$(date +%s)/" lib/parse_tree.rb || die

	# Generate a gemspec file that we can manipulate more easily, and
	# match RubyInline dependency to our versioning.
	ruby_fakegem_metadata_gemspec ../metadata ${RUBY_FAKEGEM_GEMSPEC}
	sed -i -e 's/~> 3.9.0/>= 3.9.0/' ${RUBY_FAKEGEM_GEMSPEC} || die
}

src_compile() {
	chmod 0755 "${HOME}" || die "Failed to fix permissions on home"
	ruby-ng_src_compile
}

each_ruby_compile() {
	# The ruby extension uses RubyInline to use C code within Ruby;
	# since it causes us no little pain, we'll do our best here to
	# prebuild the extensions.

	INLINEDIR="${PWD}" ${RUBY} -Ilib -rparse_tree -e '' || die "Unable to load ${PN}"

	mkdir lib/inline
	cp .ruby_inline/*/*$(get_modname) lib/inline/ || die
}

src_test() {
	chmod 0755 "${HOME}" || die "Failed to fix permissions on home"
	ruby-ng_src_test
}

pkg_postinst() {
	elog "${CATEGORY}/${PN} uses the RubyInline library to build its parser."
	elog "RubyInline builds loadable extensions at runtime in your home"
	elog "directory if they are not supplied by the gems."
	elog ""
	elog "We are currently providing you with pre-built extensions for"
	elog "the Ruby implementations you're using. Unfortunately these are"
	elog "different from version to version, so you might have to"
	elog "rebuild ${CATEGORY}/${PN} after each update to dev-lang/ruby or"
	elog "dev-lang/ruby-enterprise."
}
