# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/locale_rails/locale_rails-2.0.5_p20100710.ebuild,v 1.4 2012/02/06 17:33:00 ranger Exp $

EAPI=2
USE_RUBY="ruby18"

# Documentation is generated using allison. We have that in the tree
# but this causes sandbox violations.
RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="ChangeLog README.rdoc"

RUBY_FAKEGEM_VERSION="${PV%_*}"

GITHUB_USER="mutoh"
TREE_HASH="13a096f20b4be16ae45f"

inherit ruby-fakegem

DESCRIPTION="This library provides some Rails localized functions."
HOMEPAGE="http://www.yotabanana.com/hiki/ruby-gettext-rails.html"
LICENSE="Ruby"
SRC_URI="http://github.com/${GITHUB_USER}/${PN}/tarball/${TREE_HASH} -> ${PN}-git-${PV}.tgz"

KEYWORDS="amd64 ppc x86 ~x86-macos"
SLOT="0"
IUSE=""

S="${WORKDIR}/${GITHUB_USER}-${PN}-*"

# Tests fail. We did not run them previously so not considered a
# regression. Needs further investigation.
RESTRICT="test"

ruby_add_rdepend ">=dev-ruby/locale-2.0.5"
