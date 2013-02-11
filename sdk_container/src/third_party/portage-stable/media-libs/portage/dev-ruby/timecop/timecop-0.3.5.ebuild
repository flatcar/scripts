# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/timecop/timecop-0.3.5.ebuild,v 1.1 2012/02/28 16:52:15 flameeyes Exp $

EAPI="4"

# jruby → one full test fail, that works on theo ther implementations
USE_RUBY="ruby18 ree18 ruby19"

RUBY_FAKEGEM_TASK_TEST=""

RUBY_FAKEGEM_TASK_DOC="rdoc"
RUBY_FAKEGEM_DOCDIR="rdoc"
RUBY_FAKEGEM_EXTRADOC="README.rdoc History.rdoc"

inherit ruby-fakegem

DESCRIPTION="A gem providing 'time travel' and 'time freezing' capabilities"
HOMEPAGE="http://github.com/jtrupiano/timecop"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

# tests do not work; the issue has been reported upstream but I have had
# no answer yet; the use of timecop seems to generally work though.
RESTRICT=test
