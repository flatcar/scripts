# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rubygems/rubygems-1.3.7-r1.ebuild,v 1.7 2011/09/14 16:14:25 jer Exp $

EAPI="2"

USE_RUBY="ruby18 ree18 jruby"

inherit ruby-ng

DESCRIPTION="Centralized Ruby extension management system"
HOMEPAGE="http://rubyforge.org/projects/rubygems/"
LICENSE="|| ( Ruby GPL-2 )"

# Needs to be installed first
RESTRICT="test"

SRC_URI="mirror://rubyforge/${PN}/${P}.tgz"

KEYWORDS="~alpha amd64 ~arm hppa ~ia64 ~mips ~ppc64 ~s390 ~sh ~sparc x86 ~x86-fbsd"
SLOT="0"
IUSE="doc server"

# previous versions had rubygems bundled, so it would collide badly
RDEPEND="ruby_targets_jruby? ( >=dev-java/jruby-1.4.0-r5 )"

# index_gem_repository.rb
PDEPEND="server? ( dev-ruby/builder[ruby_targets_ruby18] )"

all_ruby_prepare() {
	epatch "${FILESDIR}/${PN}-1.3.5-setup.patch"
	# Fixes a new "feature" that would prevent us from recognizing installed
	# gems inside the sandbox
	epatch "${FILESDIR}/${PN}-1.3.3-gentoo.patch"
}

each_ruby_install() {
	# Unset RUBYOPT to avoid interferences, bug #158455 et. al.
	unset RUBYOPT

	local gemsitedir=$(ruby_rbconfig_value 'sitelibdir' | sed -e 's:site_ruby:gems:')

	# rubygems tries to create GEM_HOME if it doesn't exist, upsetting sandbox,
	# bug #202109. Since 1.2.0 we also need to set GEM_PATH for this reason, bug #230163
	export GEM_HOME="${D}${gemsitedir}"
	export GEM_PATH="${GEM_HOME}/"
	keepdir ${gemsitedir}/{doc,gems,cache,specifications}

	myconf=""
	if ! use doc; then
		myconf="${myconf} --no-ri"
		myconf="${myconf} --no-rdoc"
	fi

	${RUBY} setup.rb $myconf --destdir="${D}" || die "setup.rb install failed"

	doruby "${FILESDIR}/auto_gem.rb"
}

all_ruby_install() {
	dodoc README || die "dodoc README failed"

	doenvd "${FILESDIR}/10rubygems" || die "doenvd 10rubygems failed"

	if use server; then
		newinitd "${FILESDIR}/init.d-gem_server2" gem_server || die "newinitd failed"
		newconfd "${FILESDIR}/conf.d-gem_server" gem_server || die "newconfd failed"
	fi
}

clear_source_cache() {
	local gemsitedir=$(ruby_rbconfig_value 'sitelibdir' | sed -e 's:site_ruby:gems:')
	SOURCE_CACHE="${gemsitedir}/source_cache"

	if [[ -e "${SOURCE_CACHE}" ]]; then
		rm "${SOURCE_CACHE}"
		einfo "Cleared gem source cache."
	fi
}

pkg_postinst() {
	_ruby_each_implementation clear_source_cache

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
