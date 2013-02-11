# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/tryouts/tryouts-2.1.1.ebuild,v 1.1 2012/06/10 06:04:09 graaff Exp $

EAPI=2

USE_RUBY="ruby18 ruby19 jruby"

RUBY_FAKEGEM_TASK_TEST=""

RUBY_FAKEGEM_TASK_DOC="rdoc"
RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="CHANGES.txt README.rdoc"

inherit ruby-fakegem eutils

DESCRIPTION="High-level testing library (DSL) for Ruby codes and command-line applications"
HOMEPAGE="http://solutious.com/"

LICENSE="MIT"
SLOT="2"
KEYWORDS="~amd64 ~x86"
IUSE=""

ruby_add_bdepend "test? ( dev-ruby/hexoid )"

each_ruby_test() {
	${RUBY} -Ilib bin/try || die "Tests failed"
}
