# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/linecache/linecache-0.46.ebuild,v 1.9 2012/08/25 06:19:41 graaff Exp $

EAPI=4
# ruby19 → not supported in extconf.rb
# jruby → compiled extension
USE_RUBY="ruby18 ree18"

RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="AUTHORS ChangeLog NEWS README"

inherit ruby-fakegem multilib

DESCRIPTION="Caches files as might be used in a debugger or a tool that works with sets of Ruby source files."
HOMEPAGE="http://rubyforge.org/projects/rocky-hacks/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~hppa ~ppc ~ppc64 ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~x86-solaris"
IUSE=""

ruby_add_rdepend "dev-ruby/require_relative"
ruby_add_bdepend "dev-ruby/rake"

all_ruby_prepare() {
	sed -i -e 's/rbx-require-relative/require_relative/' ../metadata || die
}

each_ruby_compile() {
	${RUBY} -S rake lib || die "build failed"
}

each_ruby_install() {
	each_fakegem_install
	ruby_fakegem_newins ext/trace_nums$(get_modname) lib/trace_nums$(get_modname)
}
