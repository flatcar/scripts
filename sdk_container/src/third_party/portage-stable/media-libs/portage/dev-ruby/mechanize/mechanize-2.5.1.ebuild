# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/mechanize/mechanize-2.5.1.ebuild,v 1.4 2012/11/25 19:15:44 tomka Exp $

EAPI=4

# jruby → dropped since net-http-persistent does not support jruby.
USE_RUBY="ruby18 ruby19"

RUBY_FAKEGEM_TASK_DOC="redocs"
RUBY_FAKEGEM_DOCDIR="doc"

RUBY_FAKEGEM_EXTRADOC="CHANGELOG.rdoc EXAMPLES.rdoc GUIDE.rdoc README.rdoc"

inherit ruby-fakegem

DESCRIPTION="A Ruby library used for automating interaction with websites."
HOMEPAGE="http://mechanize.rubyforge.org/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~ppc64 ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~x86-solaris"
IUSE=""

ruby_add_bdepend ">=dev-ruby/hoe-2.3.3"
ruby_add_rdepend ">=dev-ruby/nokogiri-1.4.4-r1
	>=dev-ruby/net-http-digest_auth-1.1.1
	>=dev-ruby/net-http-persistent-2.5.2
	>=dev-ruby/mime-types-1.17.2
	>=dev-ruby/ntlm-http-0.1.1
	>=dev-ruby/webrobots-0.0.9
	>=dev-ruby/domain_name-0.5.1"

all_ruby_install() {
	all_fakegem_install

	docinto examples
	dodoc examples/* || die
}
