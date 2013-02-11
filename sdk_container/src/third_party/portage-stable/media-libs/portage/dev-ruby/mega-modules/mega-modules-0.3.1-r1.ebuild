# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/mega-modules/mega-modules-0.3.1-r1.ebuild,v 1.2 2012/05/01 18:24:11 armin76 Exp $

EAPI=2
USE_RUBY="ruby18"

RUBY_FAKEGEM_NAME="mega"

# Tasks require reap which we don't have packaged yet.
RUBY_FAKEGEM_TASK_TEST=""
RUBY_FAKEGEM_TASK_DOC=""

RUBY_FAKEGEM_EXTRADOC="ChangeLog README TODO"

inherit ruby-fakegem

DESCRIPTION="Ruby's Massive Class Collection"
HOMEPAGE="http://mega.rubyforge.org/"

LICENSE="Ruby"
SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""

ruby_add_rdepend "dev-ruby/nano-methods"
