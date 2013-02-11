# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rake-remote_task/rake-remote_task-2.0.6.ebuild,v 1.1 2012/01/28 08:30:45 graaff Exp $

EAPI=4
USE_RUBY="ruby18 ruby19 ree18"

RUBY_FAKEGEM_TASK_DOC="docs"
RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="History.txt README.txt"

inherit ruby-fakegem

DESCRIPTION="Vlad the Deployer's sexy brainchild is rake-remote_task, extending
Rake with remote task goodness."
HOMEPAGE="http://rubyhitsquad.com/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

ruby_add_bdepend ">=dev-ruby/hoe-2.9.2 test? ( dev-ruby/minitest )"
ruby_add_rdepend ">=dev-ruby/open4-1.0"

all_ruby_prepare() {
	sed -i -e '/isolate/ s:^:#:' Rakefile
}
