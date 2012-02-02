# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/ruby-ng-gnome2.eclass,v 1.1 2010/01/13 18:33:32 graaff Exp $
#
# @ECLASS: ruby-ng-gnome2.eclass
# @MAINTAINER:
# Ruby herd <ruby@gentoo.org>
#
# Author: Hans de Graaff <graaff@gentoo.org>
#
# @BLURB:
# This eclass simplifies installation of the various pieces of
# ruby-gnome2 since they share a very common installation procedure.

inherit ruby-ng multilib

IUSE=""

subbinding=${PN#ruby-} ; subbinding=${subbinding%2}
S=${WORKDIR}/ruby-gnome2-all-${PV}/${subbinding}
SRC_URI="mirror://sourceforge/ruby-gnome2/ruby-gnome2-all-${PV}.tar.gz"
HOMEPAGE="http://ruby-gnome2.sourceforge.jp/"
LICENSE="Ruby"
SLOT="0"

# @FUNCTION: each_ruby_configure
# @DESCRIPTION:
# Run the configure script in the subbinding for each specific ruby target.
each_ruby_configure() {
	${RUBY} extconf.rb || die "extconf.rb failed"
}

# @FUNCTION: each_ruby_compile
# @DESCRIPTION:
# Compile the C bindings in the subbinding for each specific ruby target.
each_ruby_compile() {
	emake || die "emake failed"
}

# @FUNCTION: each_ruby_install
# @DESCRIPTION:
# Install the files in the subbinding for each specific ruby target.
each_ruby_install() {
	# Create the directories, or the package will create them as files.
	dodir $(${RUBY} -r rbconfig -e 'print Config::CONFIG["sitearchdir"]') /usr/$(get_libdir)/pkgconfig

	emake DESTDIR="${D}" install || die "make install failed"
}

# @FUNCTION: all_ruby_install
# @DESCRIPTION:
# Install the files common to all ruby targets.
all_ruby_install() {
	for doc in ../AUTHORS ../NEWS ChangeLog README; do
		[ -s "$doc" ] && dodoc $doc
	done
	if [[ -d sample ]]; then
		dodir /usr/share/doc/${PF}
		cp -a sample "${D}"/usr/share/doc/${PF} || die "cp failed"
	fi
}
