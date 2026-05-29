# Copyright 2024-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..13} )

inherit cmake python-single-r1

DESCRIPTION="Command-line package manager (DNF5)"
HOMEPAGE="https://github.com/rpm-software-management/dnf5"
SRC_URI="https://github.com/rpm-software-management/dnf5/archive/${PV}/${P}.tar.gz"

LICENSE="GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 arm64"
IUSE="+comps modulemd python test zchunk"
REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

RESTRICT="!test? ( test )"

DEPEND="
	>=app-arch/rpm-4.17.0
	>=dev-cpp/toml11-4.0.0
	>=dev-db/sqlite-3.35.0:3
	dev-libs/json-c
	dev-libs/libfmt
	dev-libs/libxml2
	>=net-libs/librepo-1.18.0
	>=dev-libs/libsolv-0.7.30
	dev-libs/openssl:=
	sys-apps/util-linux
	comps? ( dev-libs/libcomps )
	modulemd? ( >=dev-libs/libmodulemd-2.5.0 )
	python? ( ${PYTHON_DEPS} )
	zchunk? ( >=app-arch/zchunk-0.9.11 )
"
RDEPEND="
	${DEPEND}
"
BDEPEND="
	sys-devel/gettext
	virtual/pkgconfig
	python? ( dev-lang/swig )
"

# No patch needed - 5.2.5.0 has native WITH_MODULEMD conditional compilation

pkg_setup() {
	use python && python-single-r1_pkg_setup
}

src_configure() {
	local mycmakeargs=(
		-DWITH_COMPS=$(usex comps)
		-DWITH_MODULEMD=$(usex modulemd)
		-DWITH_ZCHUNK=$(usex zchunk)
		-DWITH_SYSTEMD=OFF
		-DWITH_HTML=OFF
		-DWITH_MAN=OFF
		-DWITH_PYTHON3=$(usex python)
		-DWITH_PERL5=OFF
		-DWITH_RUBY=OFF
		-DWITH_GO=OFF
		-DWITH_DNF5DAEMON_CLIENT=OFF
		-DWITH_DNF5DAEMON_SERVER=OFF
		-DWITH_DNF5_PLUGINS=OFF
		-DWITH_PLUGIN_ACTIONS=OFF
		-DWITH_PLUGIN_RHSM=OFF
		-DWITH_PYTHON_PLUGINS_LOADER=OFF
		-DENABLE_PERFORMANCE_TESTS=OFF
		-DENABLE_DNF5DAEMON_TESTS=OFF
		-DWITH_TESTS=$(usex test)
	)

	cmake_src_configure
}

src_install() {
	cmake_src_install

	# Install configuration directories
	keepdir /etc/dnf/dnf5-aliases.d
	keepdir /etc/dnf/libdnf5.conf.d
	keepdir /etc/dnf/libdnf5-plugins
	keepdir /etc/dnf/repos.override.d
	
	keepdir /usr/share/dnf5/aliases.d
	keepdir /usr/share/dnf5/libdnf.conf.d
	keepdir /usr/share/dnf5/repos.d
	keepdir /usr/share/dnf5/repos.override.d
	keepdir /usr/share/dnf5/vars.d
	
	keepdir /usr/lib/dnf5/plugins
	keepdir /usr/lib/libdnf5/plugins
	keepdir /usr/lib/sysimage/dnf
	
	keepdir /var/cache/libdnf5

	# README files
	echo "Place your DNF5 aliases here" > "${ED}/etc/dnf/dnf5-aliases.d/README" || die
	echo "DNF5 plugins directory" > "${ED}/usr/lib/dnf5/plugins/README" || die
}

pkg_postinst() {
	elog "DNF5 is the next-generation version of DNF package manager."
	elog "Configuration files are located in /etc/dnf/"
	elog "Plugin directories: /usr/lib/dnf5/plugins and /usr/lib/libdnf5/plugins"
}
