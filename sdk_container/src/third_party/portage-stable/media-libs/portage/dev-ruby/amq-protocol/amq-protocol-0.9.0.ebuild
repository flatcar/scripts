# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/amq-protocol/amq-protocol-0.9.0.ebuild,v 1.1 2012/05/09 17:53:43 graaff Exp $

EAPI=4
USE_RUBY="ruby18 ruby19 ree18 jruby"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="README.textile"

RUBY_FAKEGEM_TASK_TEST=""

inherit versionator ruby-fakegem

DESCRIPTION="An AMQP 0.9.1 serialization library for Ruby."
HOMEPAGE="http://github.com/ruby-amqp/amq-protocol"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"

ruby_add_bdepend "test? ( dev-ruby/rspec:2 )"

all_ruby_prepare() {
	rm Gemfile || die
	sed -i -e '/bundler/d' spec/spec_helper.rb || die
}

each_ruby_test() {
	${RUBY} -S rspec spec || die
}
