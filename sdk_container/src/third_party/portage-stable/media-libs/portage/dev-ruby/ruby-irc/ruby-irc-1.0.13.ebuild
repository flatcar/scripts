# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-irc/ruby-irc-1.0.13.ebuild,v 1.1 2010/06/04 05:47:45 graaff Exp $

EAPI=2
USE_RUBY="ruby18"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_TASK_TEST=""
RUBY_FAKEGEM_EXTRADOC="README"

inherit ruby-fakegem

MY_PN="Ruby-IRC"
MY_P="${MY_PN}-${PV}"
DESCRIPTION="Ruby-IRC is a framework for connecting and comunicating with IRC servers."
HOMEPAGE="http://rubyforge.org/projects/ruby-irc"
SRC_URI="mirror://rubygems/${MY_P}.gem"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~ppc64 ~x86"
IUSE=""

all_ruby_prepare() {
	rm lib/*~ || die "Unable to remove backup files."
}
