# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/jruby-debug-base/jruby-debug-base-0.10.3.1.ebuild,v 1.3 2010/05/28 17:21:36 josejx Exp $

EAPI="2"
USE_RUBY="jruby"

# No tests shipped :(
RUBY_FAKEGEM_TASK_TEST=""
RESTRICT="test"

RUBY_FAKEGEM_DOCDIR="html"
RUBY_FAKEGEM_EXTRADOC="AUTHORS ChangeLog README"

# Uses the same gem name as the MRI version, but it's a different gem
# altogether.
RUBY_FAKEGEM_NAME="${PN/jruby/ruby}"

inherit ruby-fakegem

DESCRIPTION="Fast Ruby debugger"
HOMEPAGE="http://rubyforge.org/projects/ruby-debug/"

# This is not registered in the gemcutter index!
SRC_URI="mirror://rubyforge/debug-commons/${RUBY_FAKEGEM_NAME}-${RUBY_FAKEGEM_VERSION}-java.gem"

LICENSE="MIT"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE=""
SLOT="0"
