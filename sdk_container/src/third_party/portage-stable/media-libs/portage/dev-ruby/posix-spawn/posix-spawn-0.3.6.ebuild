# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/posix-spawn/posix-spawn-0.3.6.ebuild,v 1.2 2011/12/04 11:08:36 graaff Exp $

EAPI=2

# jruby → should be supported but does not work with "rake compile"
USE_RUBY="ruby18 ruby19 ree18"
KEYWORDS="~amd64"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="README.md TODO HACKING"

inherit ruby-fakegem

DESCRIPTION="The posix-spawn library aims to implement a subset of the Ruby 1.9 Process::spawn"
HOMEPAGE="https://github.com/rtomayko/posix-spawn/"

LICENSE="MIT LGPL-2.1"
SLOT="0"
IUSE="test"

each_ruby_configure() {
	${RUBY} -Cext extconf.rb || die
}

each_ruby_compile() {
	emake -Cext
	cp ext/*$(get_modname) lib/ || die
}

each_ruby_test() {
	${RUBY} -Ilib -S testrb test || die
}
