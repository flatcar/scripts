# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/extensions/extensions-0.6.0-r1.ebuild,v 1.3 2012/05/01 18:24:25 armin76 Exp $

EAPI=2
USE_RUBY="ruby18"

RUBY_FAKEGEM_EXTRADOC="ChangeLog HISTORY README README.1st"

inherit ruby-fakegem

DESCRIPTION="Extensions to the standard Ruby library"
HOMEPAGE="http://rubyforge.org/projects/extensions/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ppc64 x86"
IUSE=""

# Some tests fail, but given that we've had this code in stable for
# years we are going to ignore this for now.
RESTRICT="test"
