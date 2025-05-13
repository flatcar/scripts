# Goo to attempt to resolve dependency loops on individual packages.
# If this becomes insufficient we will need to move to a full multi-stage
# bootstrap process like we do with the SDK via catalyst.
#
# Called like:
#
#     break_dep_loop [-v] [PKG_USE_PAIR]…
#
# Pass -v for verbose output.
#
# PKG_USE_PAIR consists of two arguments: a package name (for example:
# sys-fs/lvm2), and a comma-separated list of USE flags to clear (for
# example: udev,systemd).
#
# Env vars:
#
# BDL_ROOT, BDL_PORTAGEQ, BDL_EQUERY, BDL_EMERGE, BDL_INFO
break_dep_loop() {
    local bdl_root=${BDL_ROOT:-/}
    local bdl_portageq=${BDL_PORTAGEQ:-portageq}
    local bdl_equery=${BDL_EQUERY:-equery}
    local bdl_emerge=${BDL_EMERGE:-emerge}
    local bdl_info=${BDL_INFO:-echo}
    local conf_dir="${bdl_root%/}/etc/portage"
    local flag_file="${conf_dir}/package.use/break_dep_loop"
    local force_flag_file="${conf_dir}/profile/package.use.force/break_dep_loop"

    local verbose=
    if [[ ${1:-} = '-v' ]]; then
        verbose=x
        shift
    fi

    # Be sure to clean up use flag hackery from previous failed runs
    sudo rm -f "${flag_file}" "${force_flag_file}"

    if [[ ${#} -eq 0 ]]; then
        return 0
    fi

    function bdl_call() {
        local output_var_name=${1}; shift
        if [[ ${output_var_name} = '-' ]]; then
            local throw_away
            output_var_name=throw_away
        fi
        local -n output_ref=${output_var_name}
        if [[ -n ${verbose} ]]; then
            "${bdl_info}" "${*@Q}"
        fi
        local -i rv=0
        output_ref=$("${@}") || rv=${?}
        if [[ -n ${verbose} ]]; then
            "${bdl_info}" "output: ${output_ref}"
            "${bdl_info}" "exit status: ${rv}"
        fi
        return ${rv}
    }

    # Temporarily compile/install packages with flags disabled. If a binary
    # package is available use it regardless of its version or use flags.
    local pkg use_flags disabled_flags
    local -a flags
    local -a pkgs args flag_file_entries pkg_summaries
    local -A per_pkg_flags=()
    while [[ $# -gt 1 ]]; do
        pkg=${1}
        use_flags=${2}
        shift 2

        mapfile -t flags <<<"${use_flags//,/$'\n'}"
        disabled_flags="${flags[*]/#/-}"

        pkgs+=( "${pkg}" )
        per_pkg_flags["${pkg}"]=${use_flags}
        flag_file_entries+=( "${pkg} ${disabled_flags}" )
        args+=( "--buildpkg-exclude=${pkg}" )
        pkg_summaries+=( "${pkg}[${disabled_flags}]" )
    done
    unset pkg use_flags disabled_flags flags

    # If packages are already installed we have nothing to do
    local pkg any_package_uninstalled=
    for pkg in "${pkgs[@]}"; do
        if ! bdl_call - "${bdl_portageq}" has_version "${bdl_root}" "${pkg}"; then
            any_package_uninstalled=x
            break
        fi
    done
    if [[ -z ${any_package_uninstalled} ]]; then
        if [[ -n ${verbose} ]]; then
            "${bdl_info}" "all packages (${pkgs[*]}) are installed already, skipping"
        fi
        return 0
    fi
    unset pkg any_package_uninstalled

    # Likewise, nothing to do if the flags aren't actually enabled.
    local pkg any_flag_enabled= equery_output flag flags_str
    local -a flags grep_args
    for pkg in "${pkgs[@]}"; do
        bdl_call equery_output "${bdl_equery}" -q uses "${pkg}"
        flags_str=${per_pkg_flags["${pkg}"]}
        mapfile -t flags <<<"${flags_str//,/$'\n'}"
        for flag in "${flags[@]}"; do
            grep_args+=( -e "${flag/#/+}" )
        done
        if bdl_call - grep --quiet --line-regexp --fixed-strings "${grep_args[@]}" <<<"${equery_output}"; then
            any_flag_enabled=x
            break
        fi
    done
    if [[ -z ${any_flag_enabled} ]]; then
        if [[ -n ${verbose} ]]; then
            "${bdl_info}" "all packages (${pkgs[*]}) has all the desired USE flags already disabled, skipping"
        fi
        return 0
    fi
    unset pkg any_flag_enabled equery_output flag flags_str flags grep_args

    "${bdl_info}" "Merging ${pkg_summaries[*]}"
    sudo mkdir -p "${flag_file%/*}" "${force_flag_file%/*}"
    printf '%s\n' "${flag_file_entries[@]}" | sudo tee "${flag_file}" >/dev/null
    cp -a "${flag_file}" "${force_flag_file}"
    if [[ -n ${verbose} ]]; then
        "${bdl_info}" "contents of ${flag_file@Q}:"
        "${bdl_info}" "$(<"${flag_file}")"
        "${bdl_info}" "${bdl_emerge}" --rebuild-if-unbuilt=n "${args[@]}" "${pkgs[@]}"
    fi
    # rebuild-if-unbuilt is disabled to prevent portage from needlessly
    # rebuilding zlib for some unknown reason, in turn triggering more rebuilds.
    "${bdl_emerge}" \
         --rebuild-if-unbuilt=n \
         "${args[@]}" "${pkgs[@]}"
    sudo rm -f "${flag_file}" "${force_flag_file}"
    unset bdl_call
}
