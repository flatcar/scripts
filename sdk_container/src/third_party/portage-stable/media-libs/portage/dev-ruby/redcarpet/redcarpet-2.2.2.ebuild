# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/redcarpet/redcarpet-2.2.2.ebuild,v 1.2 2012/12/10 07:10:34 pinkbyte Exp $

EAPI=4
USE_RUBY="ruby18 ree18 ruby19"

RUBY_FAKEGEM_TASK_DOC=""

# There are also conformance tests but these files are not shipped in
# the gem.
RUBY_FAKEGEM_TASK_TEST="test:unit"

inherit multilib ruby-fakegem

DESCRIPTION="A Ruby wrapper for Upskirt."
HOMEPAGE="https://github.com/vmg/redcarpet"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

all_ruby_prepare() {
	# Remove test depending on compile, since we handle compilation
	# directly.
	sed -i -e 's/:compile//' Rakefile || die
}

each_ruby_configure() {
	${RUBY} -Cext/redcarpet extconf.rb || die
}

each_ruby_compile() {
	emake -Cext/redcarpet
	cp ext/redcarpet/*$(get_modname) lib/ || die
}
