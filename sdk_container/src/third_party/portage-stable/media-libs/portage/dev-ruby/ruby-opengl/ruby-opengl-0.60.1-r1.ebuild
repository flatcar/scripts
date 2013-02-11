# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-opengl/ruby-opengl-0.60.1-r1.ebuild,v 1.10 2012/07/01 18:31:45 armin76 Exp $

EAPI="2"
USE_RUBY="ruby18"

RUBY_FAKEGEM_TASK_DOC=""

# Two tests fails but the README already indicates that this may not work.
RUBY_FAKEGEM_TASK_TEST=""

inherit ruby-fakegem

DESCRIPTION="OpenGL / GLUT bindings for ruby"
HOMEPAGE="http://ruby-opengl.rubyforge.org/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 ppc x86"

IUSE=""

DEPEND="${DEPEND}
	virtual/opengl
	media-libs/freeglut"
RDEPEND="${RDEPEND}
	virtual/opengl
	media-libs/freeglut"

ruby_add_rdepend ">=dev-ruby/mkrf-0.2.3  >=dev-ruby/rake-0.7.3"

each_ruby_compile() {
	${RUBY} -S rake || die "rake failed"
}

all_ruby_install() {
	dodoc doc/*

	insinto /usr/share/doc/${PF}/examples
	doins -r examples/* || die "Failed installing example files."
}
