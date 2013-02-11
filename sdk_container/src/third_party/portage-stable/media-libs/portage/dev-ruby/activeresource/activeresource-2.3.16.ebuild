# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/activeresource/activeresource-2.3.16.ebuild,v 1.5 2013/01/31 17:46:56 ago Exp $

EAPI=2

USE_RUBY="ruby18 ree18 jruby"

RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="CHANGELOG README"

inherit ruby-fakegem

DESCRIPTION="Think Active Record for web resources.."
HOMEPAGE="http://rubyforge.org/projects/activeresource/"

LICENSE="MIT"
SLOT="2.3"
KEYWORDS="amd64 ppc ppc64 x86 -x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~x64-solaris ~x86-solaris"
IUSE=""

ruby_add_rdepend "~dev-ruby/activesupport-${PV}"
ruby_add_bdepend "
	test? (
		>=dev-ruby/mocha-0.9.5
	)"

all_ruby_prepare() {
	epatch "${FILESDIR}/${PN}-2.3.10-rails3.patch"

	# Custom template not found in package
	sed -i -e '/horo/d' Rakefile || die

	# Avoid test broken by security fixes
	sed -i -e '/test_load_yaml_array/,/^  end/ s:^:#:' test/base_test.rb || die
}
