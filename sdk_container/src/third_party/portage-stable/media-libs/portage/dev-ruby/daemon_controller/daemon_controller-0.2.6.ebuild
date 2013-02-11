# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/daemon_controller/daemon_controller-0.2.6.ebuild,v 1.6 2012/05/21 10:02:23 phajdan.jr Exp $

EAPI=2
USE_RUBY="ruby18 ree18"

RUBY_FAKEGEM_TASK_TEST=""

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="README.markdown"

inherit ruby-fakegem

DESCRIPTION="A library for starting and stopping specific daemons programmatically in a robust manner."
HOMEPAGE="http://github.com/FooBarWidget/daemon_controller"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="test"

ruby_add_bdepend "test? ( dev-ruby/rspec:0 ) "

each_ruby_test() {
	${RUBY} -S spec spec || die "Tests failed."
}
