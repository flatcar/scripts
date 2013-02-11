# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/barby/barby-0.5.0-r2.ebuild,v 1.1 2012/05/12 04:29:15 flameeyes Exp $

EAPI=4

USE_RUBY="ruby18 ree18 jruby ruby19"

RUBY_FAKEGEM_TASK_TEST="test"

RUBY_FAKEGEM_TASK_DOC="doc"
RUBY_FAKEGEM_DOCDIR="site"

RUBY_FAKEGEM_EXTRADOC="CHANGELOG README"

RUBY_FAKEGEM_GEMSPEC="${PN}.gemspec"

inherit ruby-fakegem

DESCRIPTION="Ruby barcode generator that doesn't rely on 3rd party libraries."
HOMEPAGE="http://toretore.eu/barby/"

GITHUB_USER="toretore"
SRC_URI="https://github.com/${GITHUB_USER}/${PN}/tarball/v${PV} -> ${P}.tgz"
RUBY_S="${GITHUB_USER}-${PN}-*"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test datamatrix pdf-writer qrcode rmagick prawn png cairo"

USE_RUBY="ruby18 ree18" \
	ruby_add_rdepend "
		datamatrix? ( dev-ruby/semacode )
		pdf-writer? ( dev-ruby/pdf-writer )"

USE_RUBY="ruby18 ruby19 ree18" \
	ruby_add_rdepend "
		rmagick? ( dev-ruby/rmagick )
		cairo? ( dev-ruby/rcairo )"

ruby_add_rdepend "qrcode? ( dev-ruby/rqrcode )
	png? ( dev-ruby/chunky_png )
	prawn? ( dev-ruby/prawn )"

ruby_add_bdepend "test? ( dev-ruby/minitest )"

# testing requires imagemagick capable of png output
DEPEND+=" test? ( media-gfx/imagemagick[png] )"

# make sure that the various options require a compatible Ruby implementation
REQUIRE_USE+="
	datamatrix? ( || ( ruby_targets_ruby18 ruby_targets_ree18 )
	pdf-writer? ( || ( ruby_targets_ruby18 ruby_targets_ree18 )
	rmagick?    ( || ( ruby_targets_ruby18 ruby_targets_ruby19 ruby_targets_ree18 ) )
	cairo?      ( || ( ruby_targets_ruby18 ruby_targets_ruby19 ruby_targets_ree18 ) )
"

# prawn breaks tests for some reasons, needs to be investigated; code
# still works though.
RESTRICT="prawn? ( test )"

all_ruby_prepare() {
	sed -i -e '/[bB]undler/s:^:#:' test/test_helper.rb
}

each_ruby_prepare() {
	if use datamatrix; then
		sed -i -e '/^end/i s.add_dependency "semacode"' ${RUBY_FAKEGEM_GEMSPEC}
	else
		rm \
			lib/barby/barcode/data_matrix.rb \
			test/data_matrix_test.rb
	fi

	if use pdf-writer; then
		sed -i -e '/^end/i s.add_dependency "pdf-writer"' ${RUBY_FAKEGEM_GEMSPEC}
	else
		rm \
			lib/barby/outputter/pdfwriter_outputter.rb \
			test/outputter/pdfwriter_outputter_test.rb
	fi

	if use qrcode; then
		sed -i -e '/^end/i s.add_dependency "rqrcode"' ${RUBY_FAKEGEM_GEMSPEC}
	else
		rm \
			lib/barby/barcode/qr_code.rb \
			test/qr_code_test.rb
	fi

	if use rmagick; then
		sed -i -e '/^end/i s.add_dependency "rmagick"' ${RUBY_FAKEGEM_GEMSPEC}
	else
		rm \
			lib/barby/outputter/rmagick_outputter.rb \
			test/outputter/rmagick_outputter_test.rb
	fi

	if use prawn; then
		sed -i -e '/^end/i s.add_dependency "prawn"' ${RUBY_FAKEGEM_GEMSPEC}
	else
		rm \
			lib/barby/outputter/prawn_outputter.rb \
			test/outputter/prawn_outputter_test.rb
	fi

	if use png; then
		sed -i -e '/^end/i s.add_dependency "chunky_png"' ${RUBY_FAKEGEM_GEMSPEC}
	else
		rm \
			lib/barby/outputter/png_outputter.rb \
			test/outputter/png_outputter_test.rb
	fi

	if use cairo; then
		sed -i -e '/^end/i s.add_dependency "cairo"' ${RUBY_FAKEGEM_GEMSPEC}
	else
		rm \
			lib/barby/outputter/cairo_outputter.rb \
			test/outputter/cairo_outputter_test.rb
	fi

	case ${RUBY} in
		*/ruby19)
			rm -f \
				lib/barby/barcode/data_matrix.rb \
				test/data_matrix_test.rb \
				lib/barby/outputter/pdfwriter_outputter.rb \
				test/outputter/pdfwriter_outputter_test.rb

			sed -i \
				-e '/semacode/d' \
				-e '/pdf-writer/d' \
				${RUBY_FAKEGEM_GEMSPEC}
			;;
		*/jruby)
			rm -f \
				lib/barby/barcode/data_matrix.rb \
				test/data_matrix_test.rb \
				lib/barby/outputter/pdfwriter_outputter.rb \
				test/outputter/pdfwriter_outputter_test.rb \
				lib/barby/outputter/rmagick_outputter.rb \
				test/outputter/rmagick_outputter_test.rb \
				lib/barby/outputter/cairo_outputter.rb \
				test/outputter/cairo_outputter_test.rb

			sed -i \
				-e '/semacode/d' \
				-e '/pdf-writer/d' \
				-e '/rmagick/d' \
				-e '/cairo/d' \
				${RUBY_FAKEGEM_GEMSPEC}
			;;
	esac
}
