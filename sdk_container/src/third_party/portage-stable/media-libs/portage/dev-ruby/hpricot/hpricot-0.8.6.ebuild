# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/hpricot/hpricot-0.8.6.ebuild,v 1.2 2012/10/28 18:14:58 armin76 Exp $

EAPI=2

USE_RUBY="ruby18 ree18 ruby19 jruby"

RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="CHANGELOG README.md"

inherit ruby-fakegem eutils

DESCRIPTION="A fast and liberal HTML parser for Ruby."
HOMEPAGE="http://wiki.github.com/hpricot/hpricot"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~x86-solaris"
IUSE=""

# Probably needs the same jdk as JRuby but I'm not sure how to express
# that just yet.
DEPEND="${DEPEND}
	dev-util/ragel
	ruby_targets_jruby? ( >=virtual/jdk-1.5 )"
RDEPEND="${RDEPEND}"

ruby_add_bdepend "dev-ruby/rake
	dev-ruby/rake-compiler
	test? ( virtual/ruby-test-unit )"

# dev-ruby/fast_xs does not cover JRuby so still bundle it here for now
RUBY_TARGETS="${RUBY_TARGETS/jruby/}" \
	ruby_add_rdepend="dev-ruby/fast_xs"

all_ruby_prepare() {
	sed -i -e '/[Bb]undler/ s:^:#:' Rakefile || die

	# Fix encoding assumption of environment for Ruby 1.9.
	# https://github.com/hpricot/hpricot/issues/52
	# sed -i -e '1 iEncoding.default_external=Encoding::UTF_8 if RUBY_VERSION =~ /1.9/' test/load_files.rb || die
}

each_ruby_prepare() {
	# dev-ruby/fast_xs does not cover JRuby so still bundle it here for now
	[[ ${RUBY} == */jruby ]] && continue

	pushd .. &>/dev/null
	epatch "${FILESDIR}"/${P}-fast_xs.patch
	popd .. &>/dev/null
}

each_ruby_configure() {
	# dev-ruby/fast_xs does not cover JRuby so still bundle it here for now
	if [[ ${RUBY} == */jruby ]]; then
		${RUBY} -Cext/fast_xs extconf.rb || die "fast_xs/extconf.rb failed"
	fi

	${RUBY} -Cext/hpricot_scan extconf.rb || die "hpricot_scan/extconf.rb failed"
}

each_ruby_compile() {
	local modname=$(get_modname)

	# dev-ruby/fast_xs does not cover JRuby so still bundle it here for now
	if [[ ${RUBY} == */jruby ]]; then
		modname=".jar"
		emake -Cext/fast_xs || die "make fast_xs failed"
		cp ext/fast_xs/fast_xs.jar lib/ || die
	fi

	emake -Cext/hpricot_scan CFLAGS="${CFLAGS} -fPIC" archflag="${LDFLAGS}" || die "make hpricot_scan failed"
	cp ext/hpricot_scan/hpricot_scan${modname} lib/ || die
}
