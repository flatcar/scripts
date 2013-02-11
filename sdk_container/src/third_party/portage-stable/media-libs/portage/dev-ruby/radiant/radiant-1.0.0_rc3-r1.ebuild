# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/radiant/radiant-1.0.0_rc3-r1.ebuild,v 1.2 2012/08/16 03:55:50 flameeyes Exp $

EAPI="2"
USE_RUBY="ruby18"

RUBY_FAKEGEM_VERSION=${PV/_/.}

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_TASK_TEST="spec cucumber"
RUBY_FAKEGEM_EXTRADOC="CHANGELOG.md CONTRIBUTORS.md README.md"

# All these files are needed because the generator expect to install them.
RUBY_FAKEGEM_EXTRAINSTALL="CHANGELOG.md CONTRIBUTORS.md INSTALL.md LICENSE.md README.md Gemfile Gemfile.lock Rakefile app config db log public script vendor"

inherit ruby-fakegem

DESCRIPTION="A no-fluff, open source content management system"
HOMEPAGE="http://radiantcms.org/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

# Testing depends on a working database and a bundled version of Rails 2.3.8
# Needs more work later.
RESTRICT="test"

#ruby_add_bdepend "test? ( dev-db/sqlite3-ruby  dev-ruby/rspec dev-util/cucumber )"

ruby_add_rdepend ">=dev-ruby/redcloth-4.0.0
	>=dev-ruby/rack-1.1.0
	>=dev-ruby/rails-2.3.14:2.3
	>=dev-ruby/highline-1.5.1
	>=dev-ruby/radius-0.5.1
	=dev-ruby/will_paginate-2.3*
	dev-ruby/rack-cache
	>=dev-ruby/sqlite3-1.3.4
	dev-ruby/bundler
	>=dev-ruby/activesupport-2.3.14-r1:2.3"

# Remove code from vendor that we support as an external dependency.
all_ruby_prepare() {
	rm -rf vendor/{highline,radius,rails,redcloth} Gemfile.lock

	epatch "${FILESDIR}"/${P}-deps.patch
}

each_ruby_compile() {
	# we force a lock here so that it actually works without trying to
	# write in /usr as user.
	bundle install --local || die
}

each_ruby_test() {
	cp config/database.sqlite.yml config/database.yml || die "Unable to provide database.yml for testing."
	${RUBY} -S rake db:migrate
	each_fakegem_test
	rm config/database.yml || die "Unable to remove testing database.yml."
}
