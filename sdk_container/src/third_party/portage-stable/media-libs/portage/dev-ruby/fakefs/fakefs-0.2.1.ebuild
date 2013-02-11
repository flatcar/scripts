# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/fakefs/fakefs-0.2.1.ebuild,v 1.19 2012/12/02 13:37:29 graaff Exp $

EAPI=2

# jruby → Marshal/DeMarshal to clone directories fail; tests fail in
# release 0.2.1
USE_RUBY="ruby18 ree18"

# requires sdoc
RUBY_FAKEGEM_TASK_DOC=""

RUBY_FAKEGEM_EXTRADOC="CONTRIBUTORS README.markdown"

inherit ruby-fakegem eutils

DESCRIPTION="A fake filesystem. Use it in your tests."
HOMEPAGE="http://github.com/defunkt/fakefs"

LICENSE="MIT"
SLOT="0"
KEYWORDS="alpha amd64 hppa ia64 ppc ppc64 sparc x86"
IUSE=""

all_ruby_prepare() {
	epatch "${FILESDIR}"/${P}-ruby19.patch
}
