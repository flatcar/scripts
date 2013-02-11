# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/hpricot/hpricot-0.8.4.ebuild,v 1.5 2012/10/28 18:14:59 armin76 Exp $

EAPI=2

USE_RUBY="ruby18 ree18 jruby"

RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="CHANGELOG README.md"

inherit ruby-fakegem eutils

DESCRIPTION="A fast and liberal HTML parser for Ruby."
HOMEPAGE="http://wiki.github.com/hpricot/hpricot"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha amd64 ~ia64 ~ppc ~ppc64 ~sparc x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~x86-solaris"
IUSE=""

# Probably needs the same jdk as JRuby but I'm not sure how to express
# that just yet.
DEPEND="${DEPEND}
	dev-util/ragel
	ruby_targets_jruby? ( >=virtual/jdk-1.5 )"

ruby_add_bdepend "dev-ruby/rake
	dev-ruby/rake-compiler
	test? ( virtual/ruby-test-unit )"

each_ruby_compile() {
	case $(basename ${RUBY}) in
		jruby)
			${RUBY} -S rake compile_java || die "rake compile failed"
			;;
		*)
			${RUBY} -S rake compile || die "rake compile failed"
			;;
	esac
}
