# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/mail/mail-2.4.4.ebuild,v 1.3 2013/01/16 00:21:20 zerochaos Exp $

EAPI=4
USE_RUBY="ruby18 ruby19 ree18"

RUBY_FAKEGEM_RECIPE_TEST="rspec"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="CHANGELOG.rdoc README.md ROADMAP TODO.rdoc"

RUBY_FAKEGEM_GEMSPEC="mail.gemspec"

inherit ruby-fakegem versionator

GITHUB_USER="mikel"
COMMIT="e8ec8d53c4f5c889691630d0422b9dc044762f1b"

DESCRIPTION="An email handling library"
HOMEPAGE="https://github.com/mikel/mail"
SRC_URI="https://github.com/${GITHUB_USER}/mail/tarball/${PV} -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="$(get_version_component_range 1-2)"
KEYWORDS="~amd64 ~arm ~ppc64 ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""

RUBY_S="${GITHUB_USER}-${PN}-*"

ruby_add_rdepend "
	>=dev-ruby/i18n-0.4.0
	>=dev-ruby/mime-types-1.16
	>=dev-ruby/treetop-1.4.8"

all_ruby_prepare() {
	rm Gemfile || die
	sed -i -e '/[Bb]undle/d' -e '6d' Rakefile || die "Unable to remove Bundler code."

	# Fix up dependencies to match our own.
	sed -i -e 's/~>/>=/' mail.gemspec || die "Unable to fix up dependencies."
}
