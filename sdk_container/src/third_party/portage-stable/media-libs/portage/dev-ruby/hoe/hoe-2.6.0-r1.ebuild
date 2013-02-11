# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/hoe/hoe-2.6.0-r1.ebuild,v 1.11 2011/03/07 11:58:42 armin76 Exp $

EAPI=2
USE_RUBY="ruby18 jruby"

RUBY_FAKEGEM_TASK_DOC="docs"

RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="History.txt Manifest.txt README.txt"

RUBY_FAKEGEM_EXTRAINSTALL="template"

inherit ruby-fakegem

DESCRIPTION="Hoe extends rake to provide full project automation."
HOMEPAGE="http://seattlerb.rubyforge.org/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 ~hppa ia64 ~ppc ppc64 ~s390 ~sh sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~x86-solaris"
IUSE=""

RUBY_PATCHES="${P}-rubyforge-without-account.patch"

# - also requires dev-ruby/hoe-seattlerb for 1.9;
# - dev-ruby/gemcutter is an optional dependency at both runtime and
#   test-time, at least for us;
# - rubyforge is loaded at runtime when needed, so we don't strictly
#   depend on it at runtime, but we need it for tests (for now);
ruby_add_bdepend "test? ( dev-ruby/minitest >=dev-ruby/rubyforge-2.0.3 )"

ruby_add_rdepend ">=dev-ruby/rake-0.8.7"

all_ruby_prepare() {
	# Remove normal metadata so that our stub gemspec is generated.
	# This avoids problems with the gemspec requiring rubyforge and
	# gemcutter while we don't.
	rm ../metadata || die
}
