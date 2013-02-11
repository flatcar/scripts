# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/bsearch/bsearch-1.5.0.ebuild,v 1.9 2013/01/04 20:37:28 ago Exp $

EAPI=4

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="doc/*"

USE_RUBY="ruby18 ruby19 ree18 jruby"

inherit ruby-fakegem
DESCRIPTION="A binary search library for Ruby"
HOMEPAGE="http://0xcc.net/ruby-bsearch/"

LICENSE="Ruby"
SLOT="0"
KEYWORDS="alpha amd64 ~arm hppa ia64 ~mips ppc ppc64 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos"
IUSE=""

all_ruby_prepare() {
	sed -i 's/ruby/\$\{RUBY\}/' test/test.sh || die
}

each_ruby_test() {
	pushd test
	RUBY=${RUBY} sh test.sh || die
	popd
}
