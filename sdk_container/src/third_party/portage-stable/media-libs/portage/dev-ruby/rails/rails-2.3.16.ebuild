# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rails/rails-2.3.16.ebuild,v 1.5 2013/01/31 17:47:40 ago Exp $

EAPI=2
USE_RUBY="ruby18 ree18"

RUBY_FAKEGEM_EXTRAINSTALL="builtin configs doc dispatches environments fresh_rakefile helpers html README"
RUBY_FAKEGEM_EXTRADOC="README CHANGELOG"

RUBY_FAKEGEM_BINWRAP=""

# gem lacks tests
RUBY_FAKEGEM_TASK_TEST=""

inherit ruby-fakegem

DESCRIPTION="ruby on rails is a web-application and persistance framework"
HOMEPAGE="http://www.rubyonrails.org"

LICENSE="MIT"
SLOT="2.3"
KEYWORDS="amd64 ppc ppc64 x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~x64-solaris ~x86-solaris"

IUSE=""

RDEPEND=">=app-admin/eselect-rails-0.15"

ruby_add_rdepend ">=dev-ruby/rake-0.8.3
	dev-ruby/rdoc
	~dev-ruby/activerecord-${PV}
	~dev-ruby/activeresource-${PV}
	~dev-ruby/activesupport-${PV}
	~dev-ruby/actionmailer-${PV}
	~dev-ruby/actionpack-${PV}"
ruby_add_bdepend "doc? ( dev-ruby/redcloth )"

all_ruby_prepare() {
	sed -i -e '/horo/d' Rakefile || die "Could not remove reference to unavailable documentation template."

	# Create the documentation that we create on the fly in a separate
	# directory, since we need to install the doc directory for the
	# rails script.
	sed -i -e "s/rdoc_dir = 'doc'/rdoc_dir = 'rdoc'/" Rakefile || die
}

all_ruby_install() {
	all_fakegem_install

	ruby_fakegem_binwrapper rails rails-${PV}

	if use doc; then
		pushd rdoc
		docinto api
		dohtml -r *
		popd
	fi
}

pkg_postinst() {
	elog "To select between slots of rails, use:"
	elog "\teselect rails"

	eselect rails update
}

pkg_postrm() {
	eselect rails update
}
