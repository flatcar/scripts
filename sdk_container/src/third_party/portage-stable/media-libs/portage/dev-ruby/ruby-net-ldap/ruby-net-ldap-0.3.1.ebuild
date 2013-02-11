# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-net-ldap/ruby-net-ldap-0.3.1.ebuild,v 1.1 2012/04/21 06:51:33 graaff Exp $

EAPI=4
# jruby: triggers casting errors in java itself.
USE_RUBY="ruby18 ruby19 ree18"

RUBY_FAKEGEM_TASK_TEST="test spec"
RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="Contributors.rdoc History.rdoc README.rdoc"

RUBY_FAKEGEM_NAME="net-ldap"

inherit ruby-fakegem

DESCRIPTION="Pure ruby LDAP client implementation."
HOMEPAGE="http://net-ldap.rubyforge.org/"
LICENSE="MIT"

KEYWORDS="~amd64 ~x86"
SLOT="0"
IUSE="test"

ruby_add_bdepend "test? ( dev-ruby/metaid dev-ruby/rspec:2 dev-ruby/flexmock )"
