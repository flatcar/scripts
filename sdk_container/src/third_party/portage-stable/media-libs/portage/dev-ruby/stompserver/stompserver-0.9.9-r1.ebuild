# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/stompserver/stompserver-0.9.9-r1.ebuild,v 1.2 2012/09/23 08:41:13 graaff Exp $

EAPI=4
# ruby19 → test failures.
USE_RUBY="ruby18"

RUBY_FAKEGEM_TASK_DOC="docs"
RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="History.txt README.txt"
RUBY_FAKEGEM_EXTRAINSTALL="client config"

inherit ruby-fakegem

DESCRIPTION="Stomp messaging server with FIFO queues, queue monitoring, and basic authentication."
HOMEPAGE="http://stompserver.rubyforge.org"

LICENSE="Ruby"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

ruby_add_bdepend "doc? ( dev-ruby/hoe )"
ruby_add_bdepend "test? ( dev-ruby/hoe )"

ruby_add_rdepend "dev-ruby/daemons
	dev-ruby/eventmachine"

all_ruby_install() {
	all_fakegem_install

	doinitd "${FILESDIR}"/stompserver
}
