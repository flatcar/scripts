# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rubygems/rubygems-1.8.15.ebuild,v 1.7 2012/06/16 05:01:36 hattya Exp $

EAPI="4"

USE_RUBY="ruby18 ree18 jruby"

inherit ruby-ng prefix

DESCRIPTION="Centralized Ruby extension management system"
HOMEPAGE="http://rubyforge.org/projects/rubygems/"
LICENSE="|| ( Ruby MIT )"

SRC_URI="mirror://rubyforge/${PN}/${P}.tgz"

KEYWORDS="~alpha amd64 ~arm hppa ia64 ~mips ppc ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd ~x64-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
SLOT="0"
IUSE="server test"

RDEPEND="
	ruby_targets_jruby? ( >=dev-java/jruby-1.5.6-r1 )"

# index_gem_repository.rb
PDEPEND="server? ( dev-ruby/builder[ruby_targets_ruby18] )"

# Tests fail when YARD is installed.. but just the rdoc-related stuff,
# so it's not a mistake.
ruby_add_bdepend "
	test? (
		dev-ruby/minitest
		virtual/ruby-rdoc
		!!dev-ruby/yard
	)"

all_ruby_prepare() {
	mkdir -p lib/rubygems/defaults || die
	cp "${FILESDIR}/gentoo-defaults.rb" lib/rubygems/defaults/operating_system.rb || die

	eprefixify lib/rubygems/defaults/operating_system.rb

	# Disable broken tests when changing default values:
	sed -i -e '/^  def test_self_bindir_default_dir/, /^  end/ s:^:#:' \
		-e '/^  def test_self_default_dir/, /^  end/ s:^:#:' \
		test/rubygems/test_gem.rb || die

	# Remove tests that want to write to /usr/local/bin
	rm test/rubygems/test_gem_uninstaller.rb test/rubygems/test_gem_install_update_options.rb || die
}

each_ruby_compile() {
	# Not really a build but...
	sed -i -e 's:#!.*:#!'"${RUBY}"':' bin/gem
}

each_ruby_test() {
	# Unset RUBYOPT to avoid interferences, bug #158455 et. al.
	unset RUBYOPT

	if [[ "${EUID}" -ne "0" ]]; then
		case ${RUBY} in
			*jruby)
				eqawarn "Skipping tests for jruby 1.5."
				;;
			*)
				RUBYLIB="$(pwd)/lib${RUBYLIB+:${RUBYLIB}}" ${RUBY} -I.:lib:test \
				-e 'Dir["test/**/test_*.rb"].each { |tu| require tu }' || die "tests failed"
				;;
		esac
	else
		ewarn "The userpriv feature must be enabled to run tests, bug 408951."
		eerror "Testsuite will not be run."
	fi
}

each_ruby_install() {
	# Unset RUBYOPT to avoid interferences, bug #158455 et. al.
	unset RUBYOPT
	export RUBYLIB="$(pwd)/lib${RUBYLIB+:${RUBYLIB}}"

	pushd lib &>/dev/null
	doruby -r *
	popd &>/dev/null

	case "${RUBY}" in
		*ruby19)
			local sld=$(ruby_rbconfig_value 'sitelibdir')
			insinto "${sld#${EPREFIX}}"  # bug #320813
			newins "${FILESDIR}/auto_gem.rb.ruby19" auto_gem.rb || die
			;;
		*)
			doruby "${FILESDIR}/auto_gem.rb" || die
			;;
	esac

	newbin bin/gem $(basename ${RUBY} | sed -e 's:ruby:gem:') || die
}

all_ruby_install() {
	dodoc History.txt README.rdoc

	doenvd "${FILESDIR}/10rubygems"

	if use server; then
		newinitd "${FILESDIR}/init.d-gem_server2" gem_server || die "newinitd failed"
		newconfd "${FILESDIR}/conf.d-gem_server" gem_server || die "newconfd failed"
	fi
}

pkg_postinst() {
	if [[ ! -n $(readlink "${ROOT}"usr/bin/gem) ]] ; then
		eselect ruby set $(eselect --brief --no-color ruby show | head -n1)
	fi

	ewarn
	ewarn "To switch between available Ruby profiles, execute as root:"
	ewarn "\teselect ruby set ruby(18|19|...)"
	ewarn
}

pkg_postrm() {
	ewarn "If you have uninstalled dev-ruby/rubygems, Ruby applications are unlikely"
	ewarn "to run in current shells because of missing auto_gem."
	ewarn "Please run \"unset RUBYOPT\" in your shells before using ruby"
	ewarn "or start new shells"
	ewarn
	ewarn "If you have not uninstalled dev-ruby/rubygems, please do not unset "
	ewarn "RUBYOPT"
}
