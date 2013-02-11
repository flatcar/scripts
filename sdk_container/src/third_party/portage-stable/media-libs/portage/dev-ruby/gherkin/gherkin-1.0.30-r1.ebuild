# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/gherkin/gherkin-1.0.30-r1.ebuild,v 1.8 2012/10/28 17:18:05 armin76 Exp $

EAPI=2
USE_RUBY="ruby18 ree18"

RUBY_FAKEGEM_TASK_DOC="-I lib rdoc"
RUBY_FAKEGEM_TASK_TEST=""

RUBY_FAKEGEM_DOCDIR="rdoc"
RUBY_FAKEGEM_EXTRADOC="History.txt README.rdoc"

inherit ruby-fakegem

DESCRIPTION="Fast Gherkin lexer and parser based on Ragel."
HOMEPAGE="http://wiki.github.com/aslakhellesoy/cucumber/gherkin"
LICENSE="MIT"

KEYWORDS="~alpha ~amd64 hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
SLOT="0"
IUSE=""

DEPEND="${DEPEND} dev-util/ragel"

ruby_add_bdepend "
	>=dev-ruby/rspec-1.3.0:0
	>=dev-ruby/rake-compiler-0.7.0
	test? ( >=dev-util/cucumber-0.7.0 )"

ruby_add_rdepend ">=dev-ruby/trollop-1.16.2"

all_ruby_prepare() {
	sed -i -e '/check_dependencies/d' tasks/rspec.rake tasks/cucumber.rake || die
}

each_ruby_compile() {
	${RUBY} -I lib -S rake compile || die
}

each_ruby_test() {
	${RUBY} -S rake spec || die "Specs failed"
	CUCUMBER_HOME="${HOME}" ${RUBY} -S rake cucumber || die "Cucumber features failed"
}
