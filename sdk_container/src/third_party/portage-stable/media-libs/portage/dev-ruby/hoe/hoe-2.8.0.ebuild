# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/hoe/hoe-2.8.0.ebuild,v 1.13 2011/07/10 22:23:46 halcy0n Exp $

EAPI=2
USE_RUBY="ruby18 ree18 jruby"

RUBY_FAKEGEM_TASK_DOC="docs"

RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="History.txt Manifest.txt README.txt"

RUBY_FAKEGEM_EXTRAINSTALL="template"

inherit ruby-fakegem

DESCRIPTION="Hoe extends rake to provide full project automation."
HOMEPAGE="http://seattlerb.rubyforge.org/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="alpha amd64 ~arm hppa ia64 ppc ppc64 ~s390 ~sh sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~x64-solaris ~x86-solaris"
IUSE=""

# Restrict tests since we lack a dependency on hoe-seattlerb (bug
# 368631)), and this can't be added easily since not all arches have it
# stable. Newer versions of hoe no longer have this requirement, so we
# just restrict tests here to avoid test failure.
RESTRICT="test"

RUBY_PATCHES=( "${P}-test-file-ordering.patch" )

# - also requires dev-ruby/hoe-seattlerb for 1.9;
# - dev-ruby/gemcutter is an optional dependency at both runtime and
#   test-time, at least for us;
# - rubyforge is loaded at runtime when needed, so we don't strictly
#   depend on it at runtime, but we need it for tests (for now);
ruby_add_bdepend "test? ( dev-ruby/minitest >=dev-ruby/rubyforge-2.0.4 )"

ruby_add_rdepend ">=dev-ruby/rake-0.8.7"
