# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/GeoRuby/GeoRuby-1.3.4.ebuild,v 1.4 2011/08/24 20:50:00 maekke Exp $

EAPI=2

# ruby19 → fails tests; needs porting for new interfaces and floats
USE_RUBY="ruby18 ree18 jruby"

RUBY_FAKEGEM_TASK_TEST="-f rakefile.rb test"

RUBY_FAKEGEM_TASK_DOC="-f rakefile.rb rdoc"

RUBY_FAKEGEM_DOCDIR="georuby-doc"
RUBY_FAKEGEM_EXTRADOC="README"

inherit ruby-fakegem

DESCRIPTION="Ruby data holder for OGC Simple Features"
HOMEPAGE="http://github.com/nofxx/georuby"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""
