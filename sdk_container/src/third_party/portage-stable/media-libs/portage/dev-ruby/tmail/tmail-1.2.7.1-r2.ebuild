# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/tmail/tmail-1.2.7.1-r2.ebuild,v 1.9 2012/05/01 18:24:18 armin76 Exp $

EAPI=2
USE_RUBY="ruby18 ree18 jruby"

RUBY_FAKEGEM_TASK_DOC="doc"
RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="README CHANGES NOTES"

inherit ruby-fakegem

DESCRIPTION="An email handling library"
HOMEPAGE="http://rubyforge.org/projects/tmail/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 ppc ppc64 x86 ~ppc-macos ~x86-macos ~x64-solaris ~x86-solaris"
IUSE="debug"

# Tests seem to be broken with the new encoding handling from Ruby,
# need to be verified twice; code seems to work anyway.
RESTRICT=test

# Once it's added to portage, this should be added, right now it's
# bundled.
# ruby_add_rdepend dev-ruby/rchardet

ruby_add_bdepend "
	dev-ruby/racc
	test? ( >=dev-ruby/mocha-0.9.5 )"

all_ruby_prepare() {
	# Provide file that is no longer distributed but still needed
	mkdir meta || die "Failed to mkdir meta."
	echo "tmail" > meta/unixname || die "Failed to create unixname file."
}

each_ruby_configure() {
	case ${RUBY} in
		*ruby18 | *rubyee18)
			${RUBY} -Cext/tmailscanner/tmail extconf.rb || die "extconf failed"
			;;
	esac
}

each_ruby_compile() {
	emake -C lib/tmail $(use debug && echo DEBUG=true) parser.rb || die "emake failed"

	case ${RUBY} in
		*ruby18 | *rubyee18)
			emake -Cext/tmailscanner/tmail \
				CFLAGS="${CFLAGS} -fPIC" archflag="${LDFLAGS}" || die "emake extension failed"
			;;
	esac
}

each_ruby_install() {
	# We cannot use the recursive install because there are
	# racc source files and a makefile.
	find lib -name '*.rb' | while read file; do
		ruby_fakegem_newins $file $file
	done

	[[ -f ext/tmailscanner/tmail/tmailscanner.so ]] && \
		ruby_fakegem_newins ext/tmailscanner/tmail/tmailscanner.so lib/tmail/tmailscanner.so

	ruby_fakegem_install_gemspec
}
