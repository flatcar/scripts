# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/color-tools/color-tools-1.3.0-r1.ebuild,v 1.6 2011/12/11 09:28:24 phajdan.jr Exp $

EAPI=2
USE_RUBY="ruby18"

RUBY_FAKEGEM_TASK_DOC="docs"
RUBY_FAKEGEM_DOCDIR="doc"

RUBY_FAKEGEM_EXTRADOC="Changelog README"

inherit ruby-fakegem

DESCRIPTION="Ruby library to provide RGB and CMYK colour support."
HOMEPAGE="http://ruby-pdf.rubyforge.org/color-tools/"
LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 ppc64 x86"
IUSE=""

all_ruby_prepare() {
	# Provide a fake gemspec to support the version code in the Rakefile
	echo "Gem::Specification.new{|s| s.version = '${PV}'}" > "${PN}.gemspec" || die

	# Remove unsupported verbose task conditional
	sed -i -e '/t.verbose/d' Rakefile || die

	# Remove dependency that is unneeded for our purpose
	sed -i -e '/minitar/d' Rakefile || die
}
