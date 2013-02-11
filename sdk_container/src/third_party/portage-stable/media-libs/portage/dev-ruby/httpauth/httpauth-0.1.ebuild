# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/httpauth/httpauth-0.1.ebuild,v 1.1 2012/09/02 07:47:53 graaff Exp $

EAPI=4
USE_RUBY="ruby18 ree18 ruby19"

# There are tests in the upstream SVN rubyforge repo.
RUBY_FAKEGEM_TASK_TEST=""

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="README examples/*"

inherit ruby-fakegem

DESCRIPTION="A library supporting the full HTTP Authentication protocol as specified in RFC 2617."
HOMEPAGE="http://httpauth.rubyforge.org/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""
