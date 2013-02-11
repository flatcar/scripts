# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rubyzip/rubyzip-0.9.4.ebuild,v 1.6 2012/05/01 18:24:22 armin76 Exp $

EAPI=2

# ruby19 → testsuite fail, code assumes Ruby 1.8 syntax
# jruby → adding zip files to the load path fails, badly
USE_RUBY="ruby18"

RUBY_FAKEGEM_DOCDIR="html"
RUBY_FAKEGEM_EXTRADOC="README TODO NEWS ChangeLog"

inherit ruby-fakegem

DESCRIPTION="A ruby library for reading and writing zip files"
HOMEPAGE="http://rubyzip.sourceforge.net/"

LICENSE="Ruby"
SLOT="0"
KEYWORDS="amd64 ~ppc x86"
IUSE=""

RDEPEND=""
DEPEND="test? ( app-arch/zip )"

all_ruby_prepare() {
	# The Rakefile unconditionally requires net-sftp for the “Publish
	# Package” task, avoid that.
	sed -i \
		-e '/net\/sftp/s:^:#:' \
		Rakefile || die
}

all_ruby_install() {
	all_fakegem_install

	docinto examples
	dodoc samples/* || die
}
