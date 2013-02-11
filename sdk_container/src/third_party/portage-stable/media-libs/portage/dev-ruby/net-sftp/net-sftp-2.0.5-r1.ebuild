# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/net-sftp/net-sftp-2.0.5-r1.ebuild,v 1.1 2012/12/15 13:05:29 graaff Exp $

EAPI=4
USE_RUBY="ruby18 ruby19 jruby"

RUBY_FAKEGEM_TASK_DOC="doc"

RUBY_FAKEGEM_EXTRADOC="CHANGELOG.rdoc README.rdoc"

inherit ruby-fakegem

DESCRIPTION="SFTP in pure Ruby"
HOMEPAGE="http://net-ssh.rubyforge.org/"

LICENSE="GPL-2"
SLOT="2"
KEYWORDS="~amd64 ~ppc ~ppc64 ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~x64-solaris ~x86-solaris"
IUSE=""

ruby_add_rdepend ">=dev-ruby/net-ssh-2.0.17-r1"

ruby_add_bdepend "
	doc? ( dev-ruby/echoe )
	test? (
		dev-ruby/echoe
		dev-ruby/mocha
	)"

each_ruby_test() {
	case ${RUBY} in
		*ruby19)
			each_fakegem_test
			;;
		*)
			# Ignore tests since they hang, mostl likely due to bad
			# interaction with net-ssh:
			# https://github.com/net-ssh/net-sftp/issues/16 This seems
			# fixed in newer net-ssh versions but these are ruby19 only.
			;;
	esac
}
