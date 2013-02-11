# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rye/rye-0.9.7.ebuild,v 1.1 2012/09/21 05:51:41 graaff Exp $

EAPI=4

USE_RUBY="ruby18 ruby19"

RUBY_FAKEGEM_TASK_TEST=""

RUBY_FAKEGEM_TASK_DOC="rdoc"
RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="CHANGES.txt README.rdoc"

RUBY_FAKEGEM_BINWRAP=""

inherit ruby-fakegem

DESCRIPTION="Safely run SSH commands on a bunch of machines at the same time"
HOMEPAGE="http://solutious.com/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

ruby_add_rdepend "
	>=dev-ruby/net-scp-1.0.2
	>=dev-ruby/net-ssh-2.0.13
	>=dev-ruby/highline-1.5.1
	>=dev-ruby/sysinfo-0.7.3
	dev-ruby/annoy
	dev-ruby/storable
	virtual/ruby-ssl"

#ruby_add_bdepend "test? ( dev-ruby/tryouts:2 )"

# Tests require local login to the system, which means either root or
# portage users should have ssh access. This is definitely a no-go
RESTRICT=test

# Tests are not in the released gem, but since we don't run them we
# don't need the whole sources as it is.

#SRC_URI="http://github.com/delano/${PN}/tarball/v${PV} -> ${PN}-git-${PV}.tgz"
#S="${WORKDIR}/delano-${PN}-*"

each_ruby_test() {
	${RUBY} -S try || die "tests failed"
}
