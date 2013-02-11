# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/css_parser/css_parser-1.2.6.ebuild,v 1.2 2012/05/05 05:44:15 graaff Exp $

EAPI=4
USE_RUBY="ruby18 ruby19 ree18 jruby"

RUBY_FAKEGEM_TASK_DOC="rdoc"
RUBY_FAKEGEM_DOC_DIR="doc"
RUBY_FAKEGEM_EXTRADOC="README.rdoc"

RUBY_FAKEGEM_GEMSPEC="${PN}.gemspec"

GITHUB_USER="alexdunae"
GITHUB_PROJECT="${PN}"
RUBY_S="${GITHUB_USER}-${GITHUB_PROJECT}-*"

inherit ruby-fakegem

DESCRIPTION="Sass-based Stylesheet Framework"
HOMEPAGE="http://compass-style.org/"
LICENSE="MIT"

SRC_URI="https://github.com/${GITHUB_USER}/${GITHUB_PROJECT}/tarball/${PV} -> ${GITHUB_PROJECT}-${PV}.tar.gz"

SLOT="0"
KEYWORDS="~amd64"
IUSE="doc test"

ruby_add_rdepend "dev-ruby/addressable
	virtual/ruby-ssl"

all_ruby_prepare() {
	# fix wrong runtime dependency over rdoc
	sed -i -e '/rdoc/s:add_dep:add_development_dep:' "${RUBY_FAKEGEM_GEMSPEC}" || die

	# get rid of bundler usage
	rm Gemfile || die
	sed -i -e '/bundler/d' rakefile.rb || die
}

each_ruby_prepare() {
	if [[ ${RUBY} == */jruby ]]; then
		sed -i -e '/add_development_dependency/i s.add_dependency("jruby-openssl")' "${RUBY_FAKEGEM_GEMSPEC}" || die
	fi
}
