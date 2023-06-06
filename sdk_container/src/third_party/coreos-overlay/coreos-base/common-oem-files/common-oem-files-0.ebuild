# Copyright (c) 2023 The Flatcar Maintainers.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

OEMIDS=(
)

DESCRIPTION='Common OEM files'
HOMEPAGE='https://www.flatcar.org/'

LICENSE='Apache-2.0'
SLOT='0'
KEYWORDS='amd64 arm64'
IUSE="${OEMIDS[*]}"
REQUIRED_USE="^^ ( ${OEMIDS[*]} )"

# No source directory.
S="${WORKDIR}"

DEPEND=""
RDEPEND="${DEPEND}"
BDEPEND="
	app-portage/gentoolkit
"

src_compile() {
    local oemid package ebuild version name homepage lines

    for oemid in "${OEMIDS[@]}"; do
        if use "${oemid}"; then break; fi
    done

    package="coreos-base/oem-${oemid}"
    ebuild=$(equery which "${package}")
    version=${ebuild##*"oem-${oemid}-"}
    version=${version%%'.ebuild'}
    if [[ -z "${version}" ]]; then
        die "Could not deduce a version from ebuild ${ebuild##*/} (${ebuild})"
    fi
    name=$(source <(grep -F 'OEM_NAME=' "${ebuild}"); echo "${OEM_NAME}")
    if [[ -z "${name}" ]]; then
        die "Missing OEM_NAME variable in ${ebuild##*/}"
    fi
    # We need to prefix the HOMEPAGE variable with SYSEXT_, because
    # portage marks HOMEPAGE as readonly and this gets propagated to
    # subshells, so sourcing a snippet with HOMEPAGE=foo won't
    # overwrite the readonly variable.
    homepage=$(source <(grep -F 'HOMEPAGE=' "${ebuild}" | sed -e 's/^/SYSEXT_/'); echo "${SYSEXT_HOMEPAGE}")
    lines=(
        "ID=${oemid}"
        "VERSION_ID=${version}"
        "NAME=\"${name}\""
    )
    if [[ -n "${homepage}" ]]; then
        lines+=( "HOME_URL=\"${homepage}\"" )
    fi
    lines+=(
        'BUG_REPORT_URL="https://issues.flatcar.org"'
    )

    {
        printf '%s\n' "${lines[@]}"
        if [[ -e "${FILESDIR}/${oemid}/oem-release.frag" ]]; then
            cat "${FILESDIR}/${oemid}/oem-release.frag"
        fi
    } >"${T}/oem-release"

    lines=(
        '# Flatcar GRUB settings'
        ''
        "set oem_id=\"${oemid}\""
    )
    {
        printf '%s\n' "${lines[@]}"
        if [[ -e "${FILESDIR}/${oemid}/grub.cfg.frag" ]]; then
            cat "${FILESDIR}/${oemid}/grub.cfg.frag"
        fi
    } >"${T}/grub.cfg"
}

src_install() {
    insinto "/oem"
    doins "${T}/grub.cfg"
    doins "${T}/oem-release"
}
