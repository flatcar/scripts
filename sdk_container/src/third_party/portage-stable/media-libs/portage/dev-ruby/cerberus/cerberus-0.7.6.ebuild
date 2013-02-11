# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/cerberus/cerberus-0.7.6.ebuild,v 1.2 2010/05/22 15:05:15 flameeyes Exp $

EAPI="2"
USE_RUBY="ruby18"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="Authors.txt Changelog.txt Readme.markdown"

inherit ruby-fakegem

DESCRIPTION="Continuous Integration tool for ruby projects"
HOMEPAGE="http://rubyforge.org/projects/cerberus"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~ppc64 ~x86"
IUSE=""

# Tests depend on rubyzip which we currently do not have packages.
RESTRICT="test"

ruby_add_rdepend ">=dev-ruby/actionmailer-1.3.3
	>=dev-ruby/activesupport-1.4.2
	>=dev-ruby/rake-0.7.3"

ruby_add_bdepend "test? ( virtual/ruby-test-unit )"

# TODO: cerberus bundles xmpp4r-0.4, twitter-0.3.1, and irc (unknown
# version). We only have newer versions available, so it's not clear
# how easy this is to unbundle.
