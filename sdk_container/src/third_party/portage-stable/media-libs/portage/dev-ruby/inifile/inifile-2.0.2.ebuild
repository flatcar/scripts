# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/inifile/inifile-2.0.2.ebuild,v 1.1 2012/10/12 05:23:15 graaff Exp $

EAPI="4"

USE_RUBY="ruby18 ree18 ruby19 jruby"

RUBY_FAKEGEM_TASK_TEST="test"

RUBY_FAKEGEM_RECIPE_DOC="rdoc"
RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="README.md History.txt"

inherit ruby-fakegem eutils

DESCRIPTION="Native Ruby package for reading and writing INI files."
HOMEPAGE="https://github.com/TwP/inifile"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

each_ruby_test() {
	${RUBY} -S testrb test/test_*.rb || die
}
