# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/caesars/caesars-0.7.4.ebuild,v 1.2 2010/09/09 18:04:44 flameeyes Exp $

EAPI=2

USE_RUBY="ruby18 ruby19"

RUBY_FAKEGEM_TASK_TEST=""

RUBY_FAKEGEM_TASK_DOC="rdoc"
RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="CHANGES.txt README.rdoc"

RUBY_FAKEGEM_BINWRAP=""

inherit ruby-fakegem

DESCRIPTION="Rapid DSL prototyping in Ruby."
HOMEPAGE="http://solutious.com/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

#ruby_add_bdepend test dev-ruby/tryouts

# Tests currenty fail for all implementations
# http://github.com/delano/gibbler/issues/issue/1
RESTRICT=test

# Tests are not in the released gem, but since we don't run them we
# don't need the whole sources as it is.

#SRC_URI="http://github.com/delano/${PN}/tarball/${P} -> ${PN}-git-${PV}.tgz"
#S="${WORKDIR}/delano-${PN}-3629f49"

each_ruby_test() {
	${RUBY} -S sergeant || die "tests failed"
}
