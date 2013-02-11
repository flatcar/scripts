# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/gruff/gruff-0.3.6-r3.ebuild,v 1.1 2012/07/22 18:08:15 graaff Exp $

EAPI=4
USE_RUBY="ruby18 ruby19"

RUBY_FAKEGEM_TASK_DOC="docs"

RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="History.txt Manifest.txt README.txt"

RUBY_FAKEGEM_EXTRAINSTALL="assets rails_generators"

inherit ruby-fakegem

ruby_add_rdepend '>=dev-ruby/rmagick-2'
ruby_add_bdepend "
	test? (
		dev-ruby/hoe
	)
	doc? ( dev-ruby/hoe )"

DESCRIPTION="RMagick Implementation for JRuby"
HOMEPAGE="http://rubyforge.org/projects/gruff/"
SRC_URI="mirror://rubyforge/${PN}/${P}.tgz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~x86-macos"
IUSE=""

RUBY_PATCHES=(
	${P}-sort-filenames.patch
	${P}-fix-tests.patch
	${P}-spider.patch
	${P}-zero-division.patch
)

# imagemagick is an indirect dependency through rmagick. However, for
# gruff to work properly imagemagick needs to be compiled with
# truetype support and this cannot be expressed in the rmagick
# dependency. Test also require imagemagick to have jpeg support.
DEPEND="${DEPEND} test? ( media-gfx/imagemagick[jpeg,truetype] )"
RDEPEND="${RDEPEND} media-gfx/imagemagick[truetype]"
