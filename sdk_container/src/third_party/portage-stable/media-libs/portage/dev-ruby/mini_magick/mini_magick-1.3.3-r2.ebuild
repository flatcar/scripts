# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/mini_magick/mini_magick-1.3.3-r2.ebuild,v 1.1 2012/05/12 17:34:41 flameeyes Exp $

EAPI=4

# jruby → test_tempfile_at_path_after_format fails with jruby 1.3.1,
# sounds like a bug in JRuby itself, or the code not being compatible.
USE_RUBY="ruby18 ruby19"

RUBY_FAKEGEM_DOCDIR="rdoc"
RUBY_FAKEGEM_EXTRADOC="README.rdoc"

RUBY_FAKEGEM_GEMSPEC="${PN}.gemspec"

inherit ruby-fakegem eutils

DESCRIPTION="Manipulate images with minimal use of memory."
HOMEPAGE="http://github.com/probablycorey/mini_magick"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

# It's only used at runtime in this case because this extension only
# _calls_ the commands. But when we run tests we're going to need tiff
# and jpeg support at a minimum.
RDEPEND="media-gfx/imagemagick"
DEPEND="test? ( media-gfx/imagemagick[tiff,jpeg] )"

# tests are known to fail under imagemagick 6.5 at least, reported upstream:
# http://github.com/probablycorey/mini_magick/issues/#issue/2
# update: still fails with imagemagick 6.6.
ruby_add_bdepend "test? ( virtual/ruby-test-unit )"

ruby_add_rdepend ">=dev-ruby/subexec-0.0.4"

all_ruby_prepare() {
	# remove executable bit from all files
	find "${S}" -type f -exec chmod -x {} +

	# Remove spec definition part because the gemspec file is not included
	sed -i -e '/gemspec/,$ d' Rakefile || die

	# convert the metadata to gemspec for easier editing; this has to be
	# executed — this requires a ruby interpreter to be set
	RUBY=ruby \
		ruby_fakegem_metadata_gemspec ../metadata "${PN}.gemspec" || die

	# fix dependency over subexec, so that 0.1.x is also accepted (tests
	# pass just fine, package works).
	sed -i -e 's:~>:>=:' "${PN}.gemspec"
}
