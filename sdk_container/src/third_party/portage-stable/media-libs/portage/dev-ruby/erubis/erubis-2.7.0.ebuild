# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/erubis/erubis-2.7.0.ebuild,v 1.10 2013/01/15 06:50:09 zerochaos Exp $

EAPI="2"

USE_RUBY="ruby18 ree18 ruby19 jruby"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_TASK_TEST=""

RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="CHANGES.txt README.txt"

inherit ruby-fakegem

DESCRIPTION="Erubis is an implementation of eRuby"
HOMEPAGE="http://www.kuwata-lab.com/erubis/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~ppc ~ppc64 ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""

ruby_add_bdepend "test? ( virtual/ruby-test-unit )"
ruby_add_rdepend ">=dev-ruby/abstract-1.0.0"

each_ruby_prepare() {
	# Fix case so that the associated test will work. Reported as http://rubyforge.org/tracker/index.php?func=detail&aid=27330&group_id=1320&atid=5201
	mv test/data/users-guide/Example.ejava test/data/users-guide/example.ejava || die

	# jruby seems to have a different ordering of variables.
	# http://rubyforge.org/tracker/?func=detail&aid=28555&group_id=1320&atid=5201
	case ${RUBY} in
		*jruby)
			sed -i -e 's/"x", "_buf"/"_buf", "x"/' test/data/users-guide/main_program2.result
			;;
		*)
			;;
	esac
}

each_ruby_test() {
	case ${RUBY} in
		# http://rubyforge.org/tracker/index.php?func=detail&aid=29484&group_id=1320&atid=5201
		*ruby19)
			einfo "Tests are not compatible with ruby 1.9.3 with Psych as YAML module."
			;;
		*)
			PATH="${S}/bin:${PATH}" RUBYLIB="${S}/lib" ${RUBY} -I. test/test.rb || die
			;;
	esac
}
