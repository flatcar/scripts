# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/multi_json/multi_json-1.3.6.ebuild,v 1.2 2013/01/16 01:13:11 zerochaos Exp $

EAPI=4

USE_RUBY="ruby18 ruby19 ree18 jruby"

RUBY_FAKEGEM_RECIPE_TEST="rspec"
RUBY_FAKEGEM_TASK_DOC="doc:rdoc"

RUBY_FAKEGEM_DOCDIR="rdoc"
RUBY_FAKEGEM_EXTRADOC="README.md"

RUBY_FAKEGEM_GEMSPEC="multi_json.gemspec"

inherit ruby-fakegem

DESCRIPTION="A gem to provide swappable JSON backends"
HOMEPAGE="http://github.com/intridea/multi_json"
LICENSE="MIT"

KEYWORDS="~amd64 ~arm ~hppa ~ppc ~ppc64 ~x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
SLOT="0"
IUSE=""

ruby_add_rdepend "|| ( >=dev-ruby/json-1.4 >=dev-ruby/yajl-ruby-0.7 =dev-ruby/activesupport-3* )"

ruby_add_bdepend "doc? ( dev-ruby/rspec:2 )"

ruby_add_bdepend "test? ( dev-ruby/json )"

USE_RUBY="${USE_RUBY/jruby/}" ruby_add_bdepend "test? ( dev-ruby/yajl-ruby )"

all_ruby_prepare() {
	sed -i -e '/[Bb]undler/d' Rakefile spec/helper.rb || die "Unable to remove bundler."
	rm Gemfile || die "Unable to remove bundler Gemfile."

	# Provide version otherwise provided by bundler.
	sed -i -e "s/#{MultiJson::VERSION}/${PV}/" Rakefile || die

	# Remove unimportant rspec options not supported by rspec 2.6.
	rm .rspec || die

	# Remove best default spec since we don't package oj yet.
	sed -i -e '/defaults to the best available gem/,/^    end/ s:^:#:' spec/multi_json_spec.rb || die
}

each_ruby_test() {
	CI=true each_fakegem_test
}
