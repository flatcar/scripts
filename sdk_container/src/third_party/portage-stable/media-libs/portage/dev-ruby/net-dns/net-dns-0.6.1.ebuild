# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/net-dns/net-dns-0.6.1.ebuild,v 1.2 2010/01/24 14:08:45 graaff Exp $

EAPI=2

USE_RUBY="ruby18 ruby19 jruby"

RUBY_FAKEGEM_DOCDIR="rdoc"
RUBY_FAKEGEM_EXTRADOC="AUTHORS.rdoc CHANGELOG.rdoc README.rdoc THANKS.rdoc"

RUBY_FAKEGEM_EXTRAINSTALL="VERSION.yml"

inherit ruby-fakegem

DESCRIPTION="DNS resolver in pure Ruby"
HOMEPAGE="http://net-dns.rubyforge.org/"

LICENSE="Ruby"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

all_ruby_prepare() {
	# on MRI 1.9 without this it'll fail to find the YAML module.
	sed -i -e '1i require "yaml"' Rakefile || die
}

all_ruby_install() {
	all_fakegem_install

	docinto examples
	dodoc demo/* || die
}
