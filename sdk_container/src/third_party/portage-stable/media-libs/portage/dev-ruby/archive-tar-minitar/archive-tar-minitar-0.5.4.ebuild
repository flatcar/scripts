# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/archive-tar-minitar/archive-tar-minitar-0.5.4.ebuild,v 1.9 2013/01/09 14:23:21 jer Exp $

EAPI=4
USE_RUBY="ruby18 ree18 ruby19 jruby"

RUBY_FAKEGEM_TASK_TEST=""
RUBY_FAKEGEM_TASK_DOC=""

RUBY_FAKEGEM_EXTRADOC="README ChangeLog"

# We don't use RUBY_FAKEGEM_NAME here since for now we want to keep the
# same gem name.

inherit ruby-fakegem

DESCRIPTION="Provides POSIX tarchive management from Ruby programs."
HOMEPAGE="http://rubyforge.org/projects/ruwiki/"
SRC_URI="mirror://rubygems/minitar-${PV}.gem"

LICENSE="|| ( GPL-2 Ruby )"
SLOT="0"
KEYWORDS="alpha amd64 hppa ia64 ppc ppc64 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~x64-solaris ~x86-solaris"
IUSE=""

# Tests are broken but this was already the case with 0.5.2 and it seems
# that only the test case is broken:
# https://github.com/halostatue/minitar/issues/9
#RESTRICT="test"

RUBY_PATCHES=(
	${PN}-0.5.2-gentoo.patch
	${PN}-0.5.3-pipes.patch
)

all_ruby_prepare() {
	# ignore faulty metadata
	rm ../metadata
}

each_ruby_test() {
	${RUBY} -Itests -Ctests testall.rb || die
}
