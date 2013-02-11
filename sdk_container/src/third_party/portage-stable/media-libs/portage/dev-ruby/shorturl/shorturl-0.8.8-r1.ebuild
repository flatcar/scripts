# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/shorturl/shorturl-0.8.8-r1.ebuild,v 1.2 2012/05/01 18:24:14 armin76 Exp $

EAPI=2

USE_RUBY="ruby18 ruby19 jruby"

RUBY_FAKEGEM_TASK_TEST=""
RUBY_FAKEGEM_TASK_DOC=""

RUBY_FAKEGEM_EXTRADOC="ChangeLog README TODO"

inherit ruby-fakegem eutils

DESCRIPTION="A very simple library to use URL shortening services such as TinyURL or RubyURL."
HOMEPAGE="http://shorturl.rubyforge.org/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86 ~x86-fbsd ~x86-macos"
IUSE=""

all_ruby_prepare() {
	epatch "${FILESDIR}"/${PN}-0.8.7+ruby-1.9.patch
}

each_ruby_test() {
	${RUBY} -Ilib test/ts_all.rb || die "tests failed"
}

all_ruby_install() {
	all_fakegem_install

	pushd doc &>/dev/null
	dohtml -r . || die
	popd &>/dev/null
}
