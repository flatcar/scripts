# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/async_sinatra/async_sinatra-1.0.0.ebuild,v 1.1 2012/12/14 16:08:57 graaff Exp $

EAPI=5
USE_RUBY="ruby18 ree18 ruby19"

RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="CHANGELOG.rdoc README.rdoc"
RUBY_FAKEGEM_TASK_DOC="docs"

inherit ruby-fakegem

DESCRIPTION="Asynchronous response API for Sinatra and Thin"
HOMEPAGE="http://libraggi.rubyforge.org/async_sinatra"
SRC_URI="https://github.com/raggi/async_sinatra/archive/v${PV}.tar.gz -> ${P}-git.tgz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"

RUBY_PATCHES=( "${FILESDIR}/${P}-extended-sinatra.patch" )

ruby_add_bdepend "test? (
	>=dev-ruby/hoe-2.9.1
	>=dev-ruby/minitest-2.5.1
	>=dev-ruby/rubyforge-2.0.4
	>=dev-ruby/eventmachine-0.12.11
	)"
ruby_add_bdepend "doc? ( >=dev-ruby/hoe-2.9.1 )"

ruby_add_rdepend ">=dev-ruby/sinatra-1.3.2
	>=dev-ruby/rack-1.4.1"

all_ruby_prepare() {
	# Remove development dependencies that we don't have from the gemspec
	sed -i -e '/\(hoe-doofus\|hoe-seattlerb\|hoe-git\|hoe-gemspec2\)/d' async_sinatra.gemspec || die
}

all_ruby_install() {
	all_fakegem_install

	insinto /usr/share/doc/${PF}/
	doins -r examples || die "Failed to install examples"
}
