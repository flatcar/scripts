# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/prawn-core/prawn-core-0.8.4-r2.ebuild,v 1.7 2012/10/28 17:48:36 armin76 Exp $

EAPI=2
USE_RUBY="ruby18 ruby19 ree18 jruby"

RUBY_FAKEGEM_DOCDIR="doc/html"
RUBY_FAKEGEM_EXTRADOC="HACKING README"

# ttfunk and pdf-inspector are vendored. These packages are maintained
# separately upstream but never released, so we now keep on using
# these vendored versions.
RUBY_FAKEGEM_EXTRAINSTALL="data vendor"

inherit ruby-fakegem

DESCRIPTION="Fast, Nimble PDF Generation For Ruby"
HOMEPAGE="http://prawn.majesticseacreature.com/"

LICENSE="|| ( GPL-2 Ruby )"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd"
IUSE="examples"

ruby_add_bdepend test "dev-ruby/test-spec dev-ruby/mocha >=dev-ruby/pdf-reader-0.8"

# Older versions of prawn install the same files, but in site_ruby
# which gets found before the newer gem install path that prawn-core
# uses.
RDEPEND="!<dev-ruby/prawn-0.7"

RUBY_PATCHES=( "${P}-ruby19-document.patch" )

all_ruby_prepare() {
	# Our version of test-spec works with and needs test-unit:2
	sed -i -e '/ruby_19/,/end/ s:^:#:' spec/spec_helper.rb || die

	# Avoid broken test altogether instead of trying to patch it up.
	sed -i -e '/should encode text without kerning by default/,/end/ s:^:#:' spec/font_spec.rb || die
}

all_ruby_install() {
	all_fakegem_install

	if use examples; then
		insinto /usr/share/doc/${PF}/examples
		doins -r examples || die "Installing examples failed."
	fi
}
