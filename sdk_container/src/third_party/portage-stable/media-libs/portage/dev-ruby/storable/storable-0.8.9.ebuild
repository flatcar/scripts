# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/storable/storable-0.8.9.ebuild,v 1.1 2011/05/22 06:10:03 graaff Exp $

EAPI=2

# jruby → yajl-ruby won't work, as it's compiled extension
USE_RUBY="ruby18 ruby19"

RUBY_FAKEGEM_TASK_TEST=""

RUBY_FAKEGEM_TASK_DOC="rdoc"
RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="CHANGES.txt README.rdoc"

inherit ruby-fakegem

DESCRIPTION="Marshal Ruby classes into and out of multiple formats"
HOMEPAGE="http://solutious.com/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

SRC_URI="http://github.com/delano/${PN}/tarball/v${PV} -> ${PN}-git-${PV}.tgz"
S="${WORKDIR}/delano-${PN}-*"

# technically, it could work without either; on the other hand, it
# would break a bit of stuff.
#ruby_add_rdepend "|| ( dev-ruby/json dev-ruby/yajl-ruby )"

# Somehow it infinite-recurse if JSON is used, see issue #1, so use
# yajl directly.
ruby_add_rdepend dev-ruby/yajl-ruby

ruby_add_bdepend "test? ( dev-ruby/tryouts:2 )"

all_ruby_prepare() {
	mv bin examples || die
}

each_ruby_test() {
	${RUBY} -S try || die "tests failed"
}

all_ruby_install() {
	all_fakegem_install

	docinto examples
	dodoc examples/* || die
}
