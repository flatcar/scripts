# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/em-http-request/em-http-request-0.2.14.ebuild,v 1.9 2013/01/01 09:04:11 ago Exp $

EAPI=2

USE_RUBY="ruby18 ree18 ruby19"

RUBY_FAKEGEM_TASK_TEST="spec"

RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="Changelog.md README.md"

inherit multilib ruby-fakegem

DESCRIPTION="Asynchronous HTTP client for Ruby, based on EventMachine runtime."
HOMEPAGE="http://github.com/igrigorik/em-http-request"

LICENSE="Ruby"
SLOT="0"
KEYWORDS="amd64 ~ppc64 x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~x64-solaris ~x86-solaris"
IUSE=""

# Tests depend on em-websocket which we don't have packaged yet.
RESTRICT="test"

ruby_add_rdepend ">=dev-ruby/addressable-2.0.0 >=dev-ruby/eventmachine-0.12.9"

#ruby_add_bdepend "test? ( dev-ruby/rspec:0 )"

each_ruby_configure() {
	for dir in http11_client buffer ; do
		${RUBY} -Cext/$dir extconf.rb || die "Unable to configure $dir"
	done
}

each_ruby_compile() {
	for dir in http11_client buffer ; do
		emake -Cext/$dir || die "Unable to compile $dir"
		cp ext/$dir/*$(get_modname) lib/ || die "Unable to copy shared object from $dir"
	done
}
