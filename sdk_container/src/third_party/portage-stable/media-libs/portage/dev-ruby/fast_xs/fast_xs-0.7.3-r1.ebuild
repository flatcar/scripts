# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/fast_xs/fast_xs-0.7.3-r1.ebuild,v 1.2 2012/08/11 12:22:40 hollow Exp $

EAPI=4

USE_RUBY="ruby18 ruby19 ree18"

RUBY_FAKEGEM_TASK_DOC="docs"
RUBY_FAKEGEM_DOCDIR="doc"

inherit ruby-fakegem

DESCRIPTION="fast_xs text escaping library ruby bindings."
HOMEPAGE="http://fast-xs.rubyforge.org/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

ruby_add_bdepend "doc? ( >=dev-ruby/hoe-2.3.2 )"
ruby_add_bdepend "test? ( >=dev-ruby/hoe-2.3.2 virtual/ruby-test-unit )"

each_ruby_configure() {
	${RUBY} -Cext/fast_xs extconf.rb || die "extconf.rb failed"
	${RUBY} -Cext/fast_xs_extra extconf.rb || die "extconf.rb failed"
}

each_ruby_compile() {
	emake -Cext/fast_xs CFLAGS="${CFLAGS} -fPIC" archflag="${LDFLAGS}" || die "make extension failed"
	cp ext/fast_xs/fast_xs$(get_modname) lib/ || die
	emake -Cext/fast_xs_extra CFLAGS="${CFLAGS} -fPIC" archflag="${LDFLAGS}" || die "make extension failed"
	cp ext/fast_xs_extra/fast_xs_extra$(get_modname) lib/ || die
}
