# Copyright 1999-2004 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/ruby-gnome2.eclass,v 1.16 2009/09/13 12:30:44 flameeyes Exp $
#
# This eclass simplifies installation of the various pieces of
# ruby-gnome2 since they share a very common installation procedure.
# It's possible that this could provide a foundation for a generalized
# ruby-module.eclass, but at the moment it contains some things
# specific to ruby-gnome2

# Variables:
# PATCHES	Space delimited list of patch files.

inherit multilib

EXPORT_FUNCTIONS src_compile src_install src_unpack

IUSE=""

subbinding=${PN#ruby-} ; subbinding=${subbinding%2}
S=${WORKDIR}/ruby-gnome2-all-${PV}/${subbinding}
SRC_URI="mirror://sourceforge/ruby-gnome2/ruby-gnome2-all-${PV}.tar.gz"
HOMEPAGE="http://ruby-gnome2.sourceforge.jp/"
LICENSE="Ruby"
SLOT="0"

# This eclass can currently only deal with a single ruby version, see
# bug 278012. Since the code is know to work with Ruby 1.8 we
# hard-code it to that version for now.

DEPEND="=dev-lang/ruby-1.8*"
RDEPEND="${DEPEND}"
USE_RUBY="ruby18"
RUBY=/usr/bin/ruby18

ruby-gnome2_src_unpack() {
	if [ ! -x /bin/install -a -x /usr/bin/install ]; then
		cat <<END >"${T}"/mkmf.rb
require 'mkmf'

STDERR.puts 'patching mkmf'
CONFIG['INSTALL'] = '/usr/bin/install'
END
		# save it because rubygems needs it (for unsetting RUBYOPT)
		export GENTOO_RUBYOPT="-r${T}/mkmf.rb"
		export RUBYOPT="${RUBYOPT} ${GENTOO_RUBYOPT}"
	fi

	unpack ${A}
	cd "${S}"
	# apply bulk patches
	if [[ ${#PATCHES[@]} -gt 1 ]]; then
		for x in "${PATCHES[@]}"; do
			epatch "${x}"
		done
	else
		for x in ${PATCHES}; do
			epatch "${x}"
		done
	fi
}

ruby-gnome2_src_compile() {
	${RUBY} extconf.rb || die "extconf.rb failed"
	emake CC=${CC:-gcc} CXX=${CXX:-g++} || die "emake failed"
}

ruby-gnome2_src_install() {
	# Create the directories, or the package will create them as files.
	dodir $(${RUBY} -r rbconfig -e 'print Config::CONFIG["sitearchdir"]') /usr/$(get_libdir)/pkgconfig

	make DESTDIR="${D}" install || die "make install failed"
	for doc in ../AUTHORS ../NEWS ChangeLog README; do
		[ -s "$doc" ] && dodoc $doc
	done
	if [[ -d sample ]]; then
		dodir /usr/share/doc/${PF}
		cp -a sample "${D}"/usr/share/doc/${PF} || die "cp failed"
	fi
}
