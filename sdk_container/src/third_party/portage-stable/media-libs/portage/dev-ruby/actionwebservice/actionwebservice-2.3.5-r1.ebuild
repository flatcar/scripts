# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/actionwebservice/actionwebservice-2.3.5-r1.ebuild,v 1.2 2012/08/16 03:49:45 flameeyes Exp $

EAPI=4
USE_RUBY="ruby18"

MY_OWNER="panztel"

RUBY_FAKEGEM_NAME="${MY_OWNER}-${PN}"

RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="CHANGELOG README TODO"

RUBY_FAKEGEM_EXTRAINSTALL="generators"

inherit ruby-fakegem

DESCRIPTION="Simple Support for Web Services APIs for Rails"
HOMEPAGE="http://github.com/${MY_OWNER}/${PN}"

LICENSE="MIT"
SLOT="2.3"
KEYWORDS="~amd64 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~x86-solaris"
IUSE=""

ruby_add_rdepend ">=dev-ruby/actionpack-2.3.5:2.3
	>=dev-ruby/activerecord-2.3.5:2.3"

# it uses activerecord when running tests, but they don't work so
# ignore them for now.
#ruby_add_bdepend test 'dev-ruby/sqlite3'
RESTRICT=test

all_ruby_prepare() {
	# fix dependencies so that instead of requiring _exactly_ versions
	# 2.3.5 of Rails gems, it requires the 2.3 slot as we do above.
	sed -i -e 's:"=":"~>":' \
		../metadata || die
}

all_ruby_install() {
	all_fakegem_install

	pushd examples
	insinto /usr/share/doc/${PF}/examples
	doins -r *
	popd
}
