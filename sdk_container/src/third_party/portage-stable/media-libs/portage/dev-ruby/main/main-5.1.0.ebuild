# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/main/main-5.1.0.ebuild,v 1.1 2012/10/05 10:20:38 graaff Exp $

EAPI=4
USE_RUBY="ruby18"

RUBY_FAKEGEM_TASK_DOC=""

RUBY_FAKEGEM_EXTRADOC="README TODO"

inherit ruby-fakegem

DESCRIPTION="A class factory and dsl for generating command line programs real quick."
HOMEPAGE="http://rubyforge.org/projects/codeforpeople"

LICENSE="Ruby"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc test"

ruby_add_rdepend ">=dev-ruby/chronic-0.6.2
	>=dev-ruby/fattr-2.2.0
	>=dev-ruby/arrayfields-4.7.4
	>=dev-ruby/map-5.1.0"

all_ruby_install() {
	all_fakegem_install

	if use doc; then
		insinto /usr/share/doc/${PF}
		doins -r samples
	fi
}
