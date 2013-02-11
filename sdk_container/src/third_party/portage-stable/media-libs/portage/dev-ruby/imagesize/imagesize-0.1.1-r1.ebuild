# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/imagesize/imagesize-0.1.1-r1.ebuild,v 1.2 2011/07/21 10:37:00 graaff Exp $

EAPI=2
USE_RUBY="ruby18"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_TASK_TEST=""
RUBY_FAKEGEM_EXTRADOC="README.txt"

inherit ruby-fakegem

DESCRIPTION="Measure image size (GIF, PNG, JPEG, etc)"
HOMEPAGE="http://imagesize.rubyforge.org/"

LICENSE="Ruby"
SLOT="0"
KEYWORDS="amd64 ~ppc x86"
IUSE=""

# The tests are broken because a test image is missing.
