# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-tcpwrap/ruby-tcpwrap-0.6-r1.ebuild,v 1.5 2012/08/16 12:46:25 johu Exp $

EAPI="2"
USE_RUBY="ruby18 ruby19 ree18"

inherit ruby-ng

DESCRIPTION="A TCP wrappers library for Ruby"
HOMEPAGE="http://raa.ruby-lang.org/list.rhtml?name=ruby-tcpwrap"
SRC_URI="http://shugo.net/archive/ruby-tcpwrap/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 ~hppa ~mips ~ppc x86"
IUSE=""

DEPEND="net-libs/libident
	sys-apps/tcp-wrappers"
RDEPEND="${DEPEND}"

S="${WORKDIR}/${PN}"

RUBY_PATCHES=( "${P}-ruby19.patch" )

each_ruby_configure() {
	${RUBY} extconf.rb || die "extconf.rb failed"
}

each_ruby_compile() {
	# We have injected --no-undefined in Ruby as a safety precaution
	# against broken ebuilds, but the Ruby-Gnome bindings
	# unfortunately rely on the lazy load of other extensions; see bug
	# #320545.
	find . -name Makefile -print0 | xargs -0 \
		sed -i -e 's:-Wl,--no-undefined ::' || die "--no-undefined removal failed"

	emake || die "emake failed"
}

each_ruby_install() {
	emake DESTDIR="${D}" install || die "make install failed"
}

all_ruby_install() {
	dodoc README* || die
	dohtml doc/* || die

	docinto sample
	dodoc sample/* || die
}
