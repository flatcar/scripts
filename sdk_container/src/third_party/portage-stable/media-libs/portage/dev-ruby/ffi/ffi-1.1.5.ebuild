# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ffi/ffi-1.1.5.ebuild,v 1.9 2013/01/15 04:47:05 zerochaos Exp $

EAPI=4

# jruby → unneeded, this is part of the standard JRuby distribution, and
# would just install a dummy.
USE_RUBY="ruby18 ruby19 ree18"

RUBY_FAKEGEM_TASK_TEST="specs"

RUBY_FAKEGEM_TASK_DOC="doc:rdoc"
RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="History.txt README.rdoc"

inherit ruby-fakegem

DESCRIPTION="Ruby extension for programmatically loading dynamic libraries"
HOMEPAGE="http://wiki.github.com/ffi/ffi"

SRC_URI="http://github.com/${PN}/${PN}/tarball/${PV} -> ${PN}-git-${PV}.tgz"
RUBY_S="${PN}-${PN}-*"

IUSE=""
LICENSE="BSD"
SLOT="0"
KEYWORDS="alpha amd64 ~arm ~hppa ~ia64 ppc ppc64 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~x86-solaris"

RDEPEND="${RDEPEND} virtual/libffi"
DEPEND="${DEPEND} virtual/libffi"

ruby_add_bdepend "dev-ruby/rake-compiler dev-ruby/rdoc
	test? ( dev-ruby/rspec:2 )"

ruby_add_rdepend "virtual/ruby-threads"

each_ruby_prepare() {
	case ${RUBY} in
		*ruby19)
			sed -i -e '1i Encoding.default_external = Encoding::UTF_8' tasks/setup.rb || die
			;;
		*)
			;;
	esac
}

each_ruby_compile() {
	${RUBY} -S rake compile || die "compile failed"
	${RUBY} -S rake -f gen/Rakefile || die "types.conf generation failed"
}

all_ruby_install() {
	all_fakegem_install

	docinto examples
	dodoc samples/*
}
