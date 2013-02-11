# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/actionmailer/actionmailer-2.3.16.ebuild,v 1.5 2013/01/31 17:47:18 ago Exp $

EAPI=2
USE_RUBY="ruby18 ree18 jruby"

RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="CHANGELOG README"

inherit ruby-fakegem

DESCRIPTION="Framework for designing email-service layers"
HOMEPAGE="http://rubyforge.org/projects/actionmailer/"

LICENSE="MIT"
SLOT="2.3"
KEYWORDS="amd64 ppc ppc64 x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~x64-solaris ~x86-solaris"
IUSE=""

RUBY_PATCHES=( "${PN}-2.3.10-rails3.patch" )

ruby_add_rdepend "~dev-ruby/actionpack-${PV}
	>=dev-ruby/text-format-0.6.3
	>=dev-ruby/tmail-1.2.3"
ruby_add_bdepend "test? (
	>=dev-ruby/mocha-0.9.5
	virtual/ruby-test-unit
)"

all_ruby_prepare() {
	# Custom template not found in package
	sed -i -e '/horo/d' Rakefile || die
}
