# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-opengl/ruby-opengl-0.60.1-r2.ebuild,v 1.10 2013/01/08 08:46:21 nativemad Exp $

EAPI="4"
USE_RUBY="ruby18 ruby19"

RUBY_FAKEGEM_TASK_DOC=""

# Two tests fails but the README already indicates that this may not
# work. Additionally these tests require access to video devices such as
# /dev/nvidiactl.
RUBY_FAKEGEM_TASK_TEST=""

inherit multilib ruby-fakegem

DESCRIPTION="OpenGL / GLUT bindings for ruby"
HOMEPAGE="http://ruby-opengl.rubyforge.org/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 hppa ppc ppc64 x86"

IUSE=""

DEPEND="${DEPEND}
	virtual/opengl
	media-libs/freeglut"
RDEPEND="${RDEPEND}
	virtual/opengl
	media-libs/freeglut"

ruby_add_bdepend ">=dev-ruby/mkrf-0.2.3  >=dev-ruby/rake-0.7.3"

each_ruby_configure() {
	for dir in gl glu glut ; do
		${RUBY} -Cext/$dir mkrf_conf.rb || die
		# Add our own LDFLAGS to the generated Rakefile.
		sed -i -e "/^LDSHARED/s/$/+ENV['LDFLAGS']/" ext/$dir/Rakefile || die
	done
}

each_ruby_compile() {
	for dir in gl glu glut ; do
		${RUBY} -Cext/$dir -S rake || die
	done

	cp ext/*/*$(get_modname) lib/ || die
}

all_ruby_install() {
	dodoc -r doc

	insinto /usr/share/doc/${PF}/examples
	doins -r examples/* || die "Failed installing example files."
}
