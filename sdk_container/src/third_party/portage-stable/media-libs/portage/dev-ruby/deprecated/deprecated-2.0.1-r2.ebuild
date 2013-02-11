# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/deprecated/deprecated-2.0.1-r2.ebuild,v 1.6 2012/07/22 16:05:28 nixnut Exp $

EAPI="2"

USE_RUBY="ruby18 ruby19 jruby"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_TASK_TEST=""

inherit ruby-fakegem

DESCRIPTION="A Ruby library for handling deprecated code"
HOMEPAGE="http://rubyforge.org/projects/deprecated"
SRC_URI="mirror://rubyforge/deprecated/${P}.tar.gz"

LICENSE="BSD"
SLOT="2"
KEYWORDS="amd64 ppc x86"
IUSE="test"

each_ruby_test() {
	${RUBY} -Ilib:. test/deprecated.rb || die "test failed"
}
