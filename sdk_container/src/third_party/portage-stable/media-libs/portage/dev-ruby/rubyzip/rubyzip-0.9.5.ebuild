# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rubyzip/rubyzip-0.9.5.ebuild,v 1.3 2012/05/01 18:24:22 armin76 Exp $

EAPI=4

# jruby → adding zip files to the load path fails, badly
USE_RUBY="ruby18 ruby19 ree18"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="README.md TODO NEWS"

inherit ruby-fakegem

DESCRIPTION="A ruby library for reading and writing zip files"
HOMEPAGE="https://github.com/aussiegeek/rubyzip"
SRC_URI="https://github.com/aussiegeek/rubyzip/tarball/${PV} -> ${P}-git.tgz"
RUBY_S="aussiegeek-rubyzip-*"

LICENSE="Ruby"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~ppc64 ~x86 ~x86-fbsd"
IUSE=""

RDEPEND=""
DEPEND="test? ( app-arch/zip )"

all_ruby_install() {
	all_fakegem_install

	docinto examples
	dodoc samples/*
}
