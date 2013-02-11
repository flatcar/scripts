# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/piston/piston-2.0.10.ebuild,v 1.1 2010/09/19 08:05:07 graaff Exp $

EAPI="2"
USE_RUBY="ruby18"

RUBY_FAKEGEM_TASK_DOC=""

RUBY_FAKEGEM_EXTRADOC="History.txt README.txt TODO"
RUBY_FAKEGEM_EXTRAINSTALL="script"

inherit ruby-fakegem

DESCRIPTION="A Rails utility that uses Subversion to manage local copies of upstream vendor branches."
HOMEPAGE="http://piston.rubyforge.org"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

# Tests fails. Disabled for now and reported upstream:
# http://github.com/francois/piston/issues/issue/4
RESTRICT="test"

ruby_add_bdepend "test? ( dev-ruby/mocha )"

ruby_add_rdepend " >=dev-ruby/log4r-1.0.5
	>=dev-ruby/main-2.8.3
	>=dev-ruby/activesupport-2.0.0"
