# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/webrat/webrat-0.7.3.ebuild,v 1.4 2012/08/19 08:14:21 graaff Exp $

EAPI=2

USE_RUBY="ruby18"

RUBY_FAKEGEM_TASK_DOC=""

RUBY_FAKEGEM_TASK_TEST="spec"
# These tests currently fail: rack and sinatra only work with old sinatra versions. mechanize needs a live network connection.
#RUBY_FAKEGEM_TASK_TEST="spec:integration:rack spec:integration:sinatra spec:integration:mechanize"

RUBY_FAKEGEM_EXTRADOC="README.rdoc History.txt"

RUBY_FAKEGEM_EXTRAINSTALL="vendor"

inherit ruby-fakegem

DESCRIPTION="Ruby acceptance testing for web applications"
HOMEPAGE="http://github.com/brynary/webrat/"
LICENSE="MIT"

KEYWORDS="~amd64 ~x86 ~x86-macos"
SLOT="0"
IUSE=""

ruby_add_rdepend ">=dev-ruby/nokogiri-1.2.0
	>=dev-ruby/rack-1.0
	>=dev-ruby/rack-test-0.5.3"

ruby_add_bdepend "test? ( dev-ruby/rspec:0 dev-ruby/merb-core dev-ruby/mechanize )"

all_ruby_prepare() {
	# Remove tests for which we don't have dependencies yet.
	rm -rf spec/*/selenium rm spec/public/save_and_open_spec.rb || die

	# Remove tests that don't work with Rails 3 installed.
	rm -rf spec/private/rails || die

	# Contains pending spec that is actually fixed, causing failure.
	rm spec/public/click_link_spec.rb || die
}
