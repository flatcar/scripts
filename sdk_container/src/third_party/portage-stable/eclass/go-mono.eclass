# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/go-mono.eclass,v 1.8 2010/01/03 19:10:49 scarabeus Exp $

# @ECLASS: go-mono.eclass
# @MAINTAINER:
# dotnet@gentoo.org
# @BLURB: Common functionality for go-mono.org apps
# @DESCRIPTION:
# Common functionality needed by all go-mono.org apps.


inherit base versionator mono


PRE_URI="http://mono.ximian.com/monobuild/preview/sources"

SVN_PN="${PN/mono-debugger/debugger}"

ESVN_STORE_DIR="${PORTAGE_ACTUAL_DISTDIR:-${DISTDIR}}/svn-src/mono"

GO_MONO_SUB_BRANCH=${GO_MONO_SUB_BRANCH}

if [[ "${PV%_rc*}" != "${PV}" ]]
then
	GO_MONO_P="${P%_rc*}"
	SRC_URI="${PRE_URI}/${PN}/${GO_MONO_P}.tar.bz2 -> ${P}.tar.bz2"
	S="${WORKDIR}/${GO_MONO_P}"
elif [[ "${PV%_pre*}" != "${PV}" ]]
then
	GO_MONO_P="${P%_pre*}"
	SRC_URI="${PRE_URI}/${PN}/${GO_MONO_P}.tar.bz2 -> ${P}.tar.bz2"
	S="${WORKDIR}/${GO_MONO_P}"
elif [[ "${PV}" == "9999" ]]
then
	GO_MONO_P=${P}
	ESVN_REPO_URI="svn://anonsvn.mono-project.com/source/trunk/${SVN_PN}"
	SRC_URI=""
	inherit autotools subversion
elif [[ "${PV%.9999}" != "${PV}" ]]
then
	GO_MONO_P=${P}
	ESVN_REPO_URI="svn://anonsvn.mono-project.com/source/branches/mono-$(get_version_component_range 1)-$(get_version_component_range 2)${GO_MONO_SUB_BRANCH}/${SVN_PN}"
	SRC_URI=""
	inherit autotools subversion
else
	GO_MONO_P=${P}
	SRC_URI="http://ftp.novell.com/pub/mono/sources/${PN}/${P}.tar.bz2"
fi


NO_MONO_DEPEND=( "dev-lang/mono" "dev-dotnet/libgdiplus" )

if [[ "$(get_version_component_range 3)" != "9999" ]]
then
	GO_MONO_REL_PV="$(get_version_component_range 1-2)"

else
	GO_MONO_REL_PV="${PV}"
fi

if ! has "${CATEGORY}/${PN}" "${NO_MONO_DEPEND[@]}"
then
	RDEPEND="=dev-lang/mono-${GO_MONO_REL_PV}*"
	DEPEND="${RDEPEND}"
fi

DEPEND="${DEPEND}
	>=dev-util/pkgconfig-0.23
	userland_GNU? ( >=sys-apps/findutils-4.4.0 )"

# @FUNCTION: go-mono_src_unpack
# @DESCRIPTION: Runs default()
go-mono_src_unpack() {
	if [[ "${PV%.9999}" != "${PV}" ||  "${PV}" == "9999" ]]
	then
		default
		subversion_src_unpack
	else
		default
	fi
}

# @FUNCTION: go-mono_src_prepare
# @DESCRIPTION: Runs autopatch from base.eclass, if PATCHES is set.
go-mono_src_prepare() {
	if [[ "${PV%.9999}" != "${PV}" ||  "${PV}" == "9999" ]]
	then
		base_src_prepare
		[[ "$EAUTOBOOTSTRAP" != "no" ]] && eautoreconf
	else
		base_src_prepare
	fi
}

# @FUNCTION: go-mono_src_configure
# @DESCRIPTION: Runs econf, disabling static libraries and dependency-tracking.
go-mono_src_configure() {
	econf	--disable-dependency-tracking		\
		--disable-static			\
		"$@"
}

# @FUNCTION: go-mono_src_configure
# @DESCRIPTION: Runs default()
go-mono_src_compile() {
	emake "$@" || die "emake failed"
}

# @ECLASS-VARIABLE: DOCS
# @DESCRIPTION: Insert path of docs you want installed. If more than one,
# consider using an array.

# @FUNCTION: go-mono_src_install
# @DESCRIPTION: Rune emake, installs common doc files, if DOCS is
# set, installs those. Gets rid of .la files.
go-mono_src_install () {
	emake -j1 DESTDIR="${D}" "$@" install || die "install failed"
	mono_multilib_comply
	local	commondoc=( AUTHORS ChangeLog README TODO )
	for docfile in "${commondoc[@]}"
	do
		[[ -e "${docfile}" ]] && dodoc "${docfile}"
	done
	if [[ "${DOCS[@]}" ]]
	then
		dodoc "${DOCS[@]}" || die "dodoc DOCS failed"
	fi
	find "${D}" -name '*.la' -exec rm -rf '{}' '+' || die "la removal failed"
}

EXPORT_FUNCTIONS src_unpack src_prepare src_configure src_compile src_install
