# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/moneta/moneta-0.6.0-r1.ebuild,v 1.4 2012/08/11 08:51:35 hollow Exp $

EAPI="4"
USE_RUBY="ruby18 ruby19 ree18"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_TASK_TEST="none"

RUBY_FAKEGEM_EXTRADOC="README TODO"

inherit ruby-fakegem

GITHUB_USER="wycats"

DESCRIPTION="A unified interface to key/value stores"
HOMEPAGE="http://github.com/wycats/moneta"
SRC_URI="http://github.com/${GITHUB_USER}/moneta/tarball/${PV} -> ${P}.tgz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RUBY_S="${GITHUB_USER}-${PN}-*"

RUBY_PATCHES=( "${P}-optional-memcache.patch" )

ruby_add_bdepend "test? ( dev-ruby/rspec:0 )"

all_ruby_prepare() {
	# Remove non-optional memcache spec because we cannot guarantee that
	# a memcache will be running to test against, bug 332919
	rm spec/moneta_memcache_spec.rb || die
}

each_ruby_test() {
	${RUBY} -S spec spec || die
}
