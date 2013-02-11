# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/hexoid/hexoid-0.2.2.ebuild,v 1.4 2011/05/22 06:12:12 graaff Exp $

EAPI=2

# None of the three actually has working tests, but they should all work
USE_RUBY="ruby18 ruby19 jruby ree18"

RUBY_FAKEGEM_TASK_TEST=""

RUBY_FAKEGEM_TASK_DOC="rdoc"
RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="CHANGES.txt README.rdoc"

RUBY_FAKEGEM_BINWRAP=""

inherit ruby-fakegem

DESCRIPTION="Generate Ruby style object ids"
HOMEPAGE="http://solutious.com/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RESTRICT=test

#ruby_add_bdepend "test? ( dev-ruby/tryouts:0 )"

#SRC_URI="http://github.com/delano/${PN}/tarball/v${PV} -> ${PN}-git-${PV}.tgz"
#S="${WORKDIR}/delano-${PN}-*"

each_ruby_test() {
	${RUBY} -S sergeant || die "tests failed"
}
