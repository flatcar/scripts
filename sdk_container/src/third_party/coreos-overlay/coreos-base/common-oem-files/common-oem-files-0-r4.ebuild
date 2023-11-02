# Copyright (c) 2023 The Flatcar Maintainers.
# Distributed under the terms of the GNU General Public License v2

# Hack description below.

if [[ ${1:-} = 'flatcar-local-variables' ]]; then
    local -a EAPI COMMON_OEMIDS ARM64_ONLY_OEMIDS AMD64_ONLY_OEMIDS OEMIDS
fi

EAPI=8

COMMON_OEMIDS=(
    ami
    azure
    openstack
    packet
    qemu
)

ARM64_ONLY_OEMIDS=(
)

AMD64_ONLY_OEMIDS=(
    digitalocean
    vmware
)

OEMIDS=(
    "${COMMON_OEMIDS[@]}"
    "${ARM64_ONLY_OEMIDS[@]}"
    "${AMD64_ONLY_OEMIDS[@]}"
)

if [[ ${1:-} = 'flatcar-local-variables' ]]; then
    unset EAPI
    return 0
else
    unset COMMON_OEMIDS ARM64_ONLY_OEMIDS AMD64_ONLY_OEMIDS
fi

# The hack above was done in order to avoid excessive duplication of
# OEM IDs around the place. This ebuild serves as a Gentoo ebuild and
# as a bash file to be sourced in order to get arch-specific
# information about possible OEM IDs. The latter role is assumed when
# the ebuild is sourced with first argument being
# 'flatcar-local-variables'. This role is used by our image-changes
# job. All this fluff needs to happen before we define or invoke any
# Gentoo-specific variables or functions like "DEPEND" or "inherit"
# that may mess up sourcing. The only exception is EAPI, which must
# happen in first 24 lines of the ebuild - this is defined in Package
# Manager Specification and is enforced by portage.
#
# This can't be done with a separate shell file in FILESDIR, because
# portage moves the ebuild into some temporary directory where
# FILESDIR, although defined, does not even exist at first - it shows
# up during the invocation of any src_ functions. Probably a security
# measure or something.

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
    local oemid package ebuild version name homepage lines oemid_cmdline

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

    oemid_cmdline="${oemid}"

    # In this specific case, the OEM ID from the oem-release file ('ami')
    # is different from the OEM ID kernel command line parameter ('ec2')
    # because some services like Afterburn or Ignition expects 'ec2|aws' value.
    if [[ "${oemid}" == "ami" ]]; then
        oemid_cmdline="ec2"
    fi

    lines=(
        '# Flatcar GRUB settings'
        ''
        "set oem_id=\"${oemid_cmdline}\""
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
