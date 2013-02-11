# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-debug/ruby-debug-0.10.4.ebuild,v 1.4 2012/05/01 18:24:19 armin76 Exp $

EAPI="2"
USE_RUBY="ruby18 ree18"

# The Rakefile has targets that are part of ruby-debug-base, so avoid
# hitting it for now.
RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_TASK_TEST=""
RUBY_FAKEGEM_EXTRADOC="AUTHORS ChangeLog CHANGES README"

RUBY_FAKEGEM_EXTRAINSTALL="cli"
RUBY_FAKEGEM_REQUIRE_PATHS="cli"

inherit elisp-common ruby-fakegem

DESCRIPTION="CLI interface to ruby-debug"
HOMEPAGE="http://rubyforge.org/projects/ruby-debug/"

LICENSE="BSD-2"
KEYWORDS="~amd64 ~hppa ~ppc64 ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~x86-solaris"
IUSE="doc emacs"
SLOT="0"
SRC_URI="mirror://rubygems/${P}.gem
	doc? ( mirror://rubyforge/ruby-debug/${PN}-extra-${PV}.tar.gz )
	emacs? ( mirror://rubyforge/ruby-debug/${PN}-extra-${PV}.tar.gz )"

EXTRA_S="${WORKDIR}/all/${PN}-extra-${PV}"

ruby_add_rdepend "
	>=dev-ruby/columnize-0.1
	~dev-ruby/ruby-debug-base-${PV}"

DEPEND="${DEPEND} emacs? ( >=virtual/emacs-22 )"
RDEPEND="${RDEPEND} emacs? ( >=virtual/emacs-22 )"

all_ruby_compile() {
	all_fakegem_compile

	if use emacs; then
		pushd "${EXTRA_S}/emacs"
		elisp-compile *.el || die
		popd
	fi
}

all_ruby_install() {
	all_fakegem_install

	if use emacs; then
		pushd "${EXTRA_S}/emacs"
		elisp-install ${PN} *.el *.elc || die
		popd
	fi

	if use doc; then
		doman "${EXTRA_S}/doc/rdebug.1" || die
		dodoc "${EXTRA_S}/doc/ruby-debug.pdf" || die
		doinfo "${EXTRA_S}"/doc/*.info || die
	fi
}
