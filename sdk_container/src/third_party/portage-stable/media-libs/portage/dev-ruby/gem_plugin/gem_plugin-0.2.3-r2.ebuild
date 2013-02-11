# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/gem_plugin/gem_plugin-0.2.3-r2.ebuild,v 1.5 2013/01/15 05:11:51 zerochaos Exp $

EAPI="2"
USE_RUBY="ruby18 ruby19 jruby"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_TASK_TEST=""

RUBY_FAKEGEM_EXTRADOC="CHANGELOG README"

RUBY_FAKEGEM_EXTRAINSTALL="resources"

inherit ruby-fakegem

DESCRIPTION="A plugin system based only on rubygems that uses dependencies only."
# Hosted by mongrel's rubyforge
HOMEPAGE="http://mongrel.rubyforge.org/"

LICENSE="mongrel"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~x86-solaris"
IUSE=""

each_fakegem_test() {
	${RUBY} -Ilib test/test_plugins.rb || die "tests failed"
}
