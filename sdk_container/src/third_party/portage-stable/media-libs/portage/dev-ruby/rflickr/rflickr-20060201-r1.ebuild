# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rflickr/rflickr-20060201-r1.ebuild,v 1.1 2010/07/03 06:28:50 graaff Exp $

EAPI=2
USE_RUBY="ruby18"

RUBY_FAKEGEM_TASK_TEST=""
RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="GETTING-STARTED"

inherit ruby-fakegem

MY_P="${PN}-${PV:0:4}.${PV:4:2}.${PV:6:2}"

DESCRIPTION="A Ruby implementation of the Flickr API."
HOMEPAGE="http://rubyforge.org/projects/rflickr"
SRC_URI="mirror://rubygems/${MY_P}.gem"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE=""

ruby_add_rdepend "dev-ruby/mime-types"

all_ruby_install() {
	all_fakegem_install

	insinto /usr/share/doc/${PF}
	doins -r sample || die
}

pkg_postinst() {
	elog "In order to use this library, you need to have:"
	elog
	elog "1. A Yahoo!/Flickr account."
	elog "2. A Flickr API key."
	elog
	elog "Visit http://www.flickr.com/services/api/ for more info."
}
