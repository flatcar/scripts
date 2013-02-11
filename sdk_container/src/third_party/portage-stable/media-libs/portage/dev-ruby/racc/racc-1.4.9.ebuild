# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/racc/racc-1.4.9.ebuild,v 1.2 2013/01/28 15:15:18 aballier Exp $

EAPI=4

USE_RUBY="ruby18 ruby19 jruby"

RUBY_FAKEGEM_TASK_DOC="docs"
RUBY_FAKEGEM_EXTRADOC="README.rdoc README.ja.rdoc TODO ChangeLog"

inherit multilib ruby-fakegem

DESCRIPTION="A LALR(1) parser generator for Ruby"
HOMEPAGE="http://www.loveruby.net/en/racc.html"

LICENSE="LGPL-2.1"
SLOT="0"

KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="doc test"

ruby_add_bdepend "dev-ruby/rake
	doc? ( dev-ruby/hoe )
	test? ( dev-ruby/hoe )"

all_ruby_prepare() {
	sed -i -e 's|/tmp/out|${TMPDIR:-/tmp}/out|' test/helper.rb || die "tests fix failed"

	# Avoid depending on rake-compiler since we don't use it to compile
	# the extension.
	sed -i -e '/rake-compiler/ s:^:#:' -e '/extensiontask/ s:^:#:' Rakefile
	sed -i -e '/ExtensionTask/,/^  end/ s:^:#:' Rakefile

	# Avoid isolation since dependencies are not properly declared.
	sed -i -e 's/, :isolate//' Rakefile || die
}

each_ruby_prepare() {
	case ${RUBY} in
		*jruby)
			;;
		*ruby18)
			sed -i -e '/test_norule_y/,/end/ s:^:#:' \
				-e '/test_unterm_y/,/end/ s:^:#:' test/test_racc_command.rb || die
			${RUBY} -Cext/racc extconf.rb || die
			;;
		*)
			${RUBY} -Cext/racc extconf.rb || die
			;;
	esac
}

each_ruby_compile() {
	case ${RUBY} in
		*jruby)
			einfo "Under JRuby, racc cannot use the shared object parser, so instead"
			einfo "you have to rely on the pure Ruby implementation."
			;;
		*)
			emake -Cext/racc
			# Copy over the file here so that we don't have to do
			# special ruby install for JRuby and the other
			# implementations.
			cp -l ext/racc/cparse$(get_modname) lib/racc/cparse$(get_modname) || die
			;;
	esac
}

each_ruby_test() {
	case ${RUBY} in
		*jruby)
			ewarn "Using JRuby 1.5.2 the tests are currently badly broken,"
			ewarn "so they are disabled until a new racc or a new JRuby is"
			ewarn "released."
			;;
		*)
			each_fakegem_test
			;;
	esac
}

all_ruby_install() {
	all_fakegem_install

	dodoc -r rdoc

	docinto examples
	dodoc -r sample
}
