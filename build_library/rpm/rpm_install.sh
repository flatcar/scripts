#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# RPM package installation functions for Azure Linux packages
#
# ENVIRONMENT VARIABLES:
#   RPM_LOCAL_CACHE - Optional path to local repository cache directory
#                     If set, will be configured as a local repo with priority=1
#                     If not set, falls back to RPM staging directory
#
# REPOSITORY CONFIGURATION:
#   - Local cache repository (if RPM_LOCAL_CACHE is set) - priority 1
#   - Bootstrap base repo (used only to install filesystem + azurelinux-repos)
#   - Azure Linux official repositories (installed via azurelinux-repos RPM)

# =============================================================================
# Helper function to find RPM staging directory
# =============================================================================
rpm_get_staging_dir() {
    local rpm_staging=""
    for candidate in \
        "${RPM_STAGING_DIR}" \
        "/mnt/host/source/src/scripts/__build__/rpm-staging" \
        "${SCRIPT_ROOT}/../__build__/rpm-staging" \
        "__build__/rpm-staging"; do
        if [[ -d "${candidate}" ]]; then
            rpm_staging="${candidate}"
            break
        fi
    done
    echo "${rpm_staging}"
}

RPM_MANIFEST_QUERY_FORMAT='%{NAME}\t%{VERSION}-%{RELEASE}\t%{INSTALLTIME}\t%{BUILDTIME}\t%{VENDOR}\t%{EPOCH}\t%{SIZE}\t%{ARCH}\t%{EPOCHNUM}\t%{SOURCERPM}\n'

# Emit a Syft-compatible RPM manifest for the installed packages in a rootfs.
rpm_query_manifest() {
    local root_fs_dir="$1"
    local dbpath="${root_fs_dir}/var/lib/rpm"

    if [[ ! -f "${dbpath}/rpmdb.sqlite" ]]; then
        error "RPM manifest query failed: RPM database not found at ${dbpath}/rpmdb.sqlite"
        return 1
    fi

    sudo rpm --dbpath="${dbpath}" -qa --queryformat "${RPM_MANIFEST_QUERY_FORMAT}"
}

# Initialize RPM database in target rootfs
rpm_init_database() {
    local root_fs_dir="$1"

    if [[ -d "${root_fs_dir}/var/lib/rpm" ]] && [[ -f "${root_fs_dir}/var/lib/rpm/rpmdb.sqlite" ]]; then
        info "RPM database already initialized in ${root_fs_dir}"
        return 0
    fi

    info "Initializing RPM database in ${root_fs_dir}"
    sudo mkdir -p "${root_fs_dir}/var/lib/rpm"

    sudo rpm --root="${root_fs_dir}" --initdb
    if [[ $? -ne 0 ]]; then
        error "Failed to initialize RPM database"
        return 1
    fi

    return 0
}

# Setup Azure Linux repositories in target rootfs
rpm_setup_repos() {
    local root_fs_dir="$1"
    local releasever="${2:-3.0}"
    local local_repo_dir="${3:-}"  # Optional local repository cache

    local repo_dir="${root_fs_dir}/etc/yum.repos.d"
    sudo mkdir -p "${repo_dir}"

    # Setup GPG directory
    sudo mkdir -p "${root_fs_dir}/etc/pki/rpm-gpg"

    info "Setting up Azure Linux repositories in ${root_fs_dir}"

    # Setup local repository cache if provided and has proper metadata
    if [[ -n "${local_repo_dir}" ]] && [[ -d "${local_repo_dir}" ]]; then
        if [[ -f "${local_repo_dir}/repodata/repomd.xml" ]]; then
            info "  Adding local repository cache: ${local_repo_dir}"
            sudo tee "${repo_dir}/azurelinux-local.repo" > /dev/null <<EOF
[azurelinux-local-cache]
name=Azure Linux Local Package Cache
baseurl=file://${local_repo_dir}
enabled=1
gpgcheck=0
repo_gpgcheck=0
priority=1
EOF
        else
            warn "  Skipping local cache (no repository metadata): ${local_repo_dir}"
            info "  Hint: Run 'createrepo_c ${local_repo_dir}' to create repository metadata"
            exit 1
        fi
    fi

    # Minimal bootstrap repo — just enough to install 'filesystem' and
    # 'azurelinux-repos'.  The azurelinux-repos RPM ships the full set
    # of official .repo files and GPG keys, so we do not duplicate them here.
    # The Microsoft GPG key is baked into the SDK container at
    # /etc/pki/rpm-gpg/MICROSOFT-RPM-GPG-KEY
    # packages.microsoft.com is a public RPM repository — no authentication
    # or special credentials are required to access it.
    info "  Setting up bootstrap repository"

    sudo tee "${repo_dir}/azurelinux-bootstrap.repo" > /dev/null <<EOF
[azurelinux-bootstrap]
name=Azure Linux Bootstrap \$releasever \$basearch
baseurl=https://packages.microsoft.com/azurelinux/\$releasever/prod/base/\$basearch
gpgkey=file:///etc/pki/rpm-gpg/MICROSOFT-RPM-GPG-KEY
gpgcheck=1
repo_gpgcheck=1
enabled=1
skip_if_unavailable=False
sslverify=1
EOF

    return 0
}

# Mount pseudo-filesystems needed for RPM scriptlets
rpm_mount_pseudofs() {
    local root_fs_dir="$1"

    # Mount /dev, /proc, /sys for scriptlets
    sudo mkdir -p "${root_fs_dir}"/{dev,proc,sys}

    if ! mountpoint -q "${root_fs_dir}/dev"; then
        # Use --rbind + --make-rslave so that sub-mounts (pts, shm, etc.)
        # are visible inside the installroot but unmounting them later does
        # not tear down the host's /dev sub-mounts.
        sudo mount --rbind /dev "${root_fs_dir}/dev"
        sudo mount --make-rslave "${root_fs_dir}/dev"
    fi

    if ! mountpoint -q "${root_fs_dir}/proc"; then
        sudo mount -t proc proc "${root_fs_dir}/proc"
    fi

    if ! mountpoint -q "${root_fs_dir}/sys"; then
        sudo mount -t sysfs sysfs "${root_fs_dir}/sys"
    fi
}

# Unmount pseudo-filesystems
rpm_umount_pseudofs() {
    local root_fs_dir="$1"

    # Kill processes that RPM/dnf5 may have spawned inside the installroot
    # (e.g., gpg-agent and scdaemon from GPG signature verification).
    # These hold file descriptors on /dev and prevent unmounting.
    if mountpoint -q "${root_fs_dir}/dev"; then
        local pids
        pids=$(sudo fuser -m "${root_fs_dir}/dev" 2>/dev/null | tr -s ' ') || true
        if [[ -n "${pids}" ]]; then
            sudo fuser -km "${root_fs_dir}/dev" >/dev/null 2>&1 || true
            sleep 1
        fi
    fi

    if mountpoint -q "${root_fs_dir}/sys"; then
        sudo umount "${root_fs_dir}/sys" 2>/dev/null || warn "Failed to umount ${root_fs_dir}/sys"
    fi

    if mountpoint -q "${root_fs_dir}/proc"; then
        sudo umount "${root_fs_dir}/proc" 2>/dev/null || warn "Failed to umount ${root_fs_dir}/proc"
    fi

    # /dev bind-mount brings along sub-mounts (pts, shm, mqueue, hugepages).
    # Use --recursive so all of them are torn down in one call.
    if mountpoint -q "${root_fs_dir}/dev"; then
        sudo umount --recursive "${root_fs_dir}/dev" 2>/dev/null || warn "Failed to umount --recursive ${root_fs_dir}/dev"
    fi

    # Verify nothing remains mounted under the rootfs
    local leftover
    leftover=$(grep -c "${root_fs_dir}/\(dev\|proc\|sys\)" /proc/mounts 2>/dev/null || true)
    if [[ "${leftover}" -gt 0 ]]; then
        warn "Pseudo-filesystem mounts still present after unmount:"
        grep "${root_fs_dir}/\(dev\|proc\|sys\)" /proc/mounts >&2 || true
        warn "Checking for processes holding mounts open:"
        sudo fuser -vm "${root_fs_dir}/dev" 2>&1 | head -20 >&2 || true
        return 1
    fi
}

# Denylist to force remove RPM packages.
# Uses --nodeps to avoid removing packages that depend on these (e.g., git depends on perl and python3)
# MAY BREAK DEPENDENT PACKAGES - use with caution
remove_denylist_rpm_packages() {
    local root_fs_dir="$1"
    local dbpath_fs="${root_fs_dir}/var/lib/rpm"
    local dbpath_root="/var/lib/rpm"
    local -a denylist_globs=("perl*" "ncurses-term" "texinfo" "rpm" "rpm-libs" "libarchive")

    if [[ "${RPM_PRESERVE_PYTHON:-0}" != "1" ]]; then
        denylist_globs+=("python3" "python3-*")
    fi

    info "RPM mode: Removing denylisted rpm packages"
    if [[ ! -d "${dbpath_fs}" ]]; then
        warn "RPM mode: No RPM database found at ${dbpath_fs}"
        return 0
    fi

    local denylist_packages
    denylist_packages=$(sudo rpm --dbpath="${dbpath_fs}" -qa "${denylist_globs[@]}" 2>/dev/null | sort -u)
    local count_before
    count_before=$(printf '%s\n' "${denylist_packages}" | sed '/^$/d' | wc -l)

    if [[ ${count_before} -eq 0 ]]; then
        info "RPM mode: No denylisted packages found to remove"
        return 0
    fi

    info "RPM mode: Found ${count_before} denylisted packages to remove"

    sudo rpm --root="${root_fs_dir}" --dbpath="${dbpath_root}" -e --nodeps ${denylist_packages} || {
        warn "RPM mode: Some denylisted packages could not be removed (may already be removed)"
    }

    local remaining
    remaining=$(sudo rpm --dbpath="${dbpath_fs}" -qa "${denylist_globs[@]}" 2>/dev/null | sort -u | wc -l)

    info "RPM mode: Removed $((count_before - remaining)) denylisted packages (${remaining} remaining)"
    info "RPM mode: Package cleanup complete"
}

# Remove perl scripts and modules orphaned by force-removing the perl denylist.
# groff and git-core depend on perl, but perl is removed via --nodeps in
# remove_denylist_rpm_packages. The scripts below are non-functional without
# the perl interpreter and must be deleted explicitly.
remove_orphaned_perl_scripts() {
    local root_fs_dir="$1"

    info "RPM mode: Removing orphaned perl scripts and modules"

    # Perl module tree
    sudo rm -rf "${root_fs_dir}/usr/share/perl5"

    # groff perl scripts
    sudo rm -f "${root_fs_dir}/usr/bin/afmtodit"
    sudo rm -f "${root_fs_dir}/usr/bin/chem"
    sudo rm -f "${root_fs_dir}/usr/bin/glilypond"
    sudo rm -f "${root_fs_dir}/usr/bin/gp-display-html"
    sudo rm -f "${root_fs_dir}/usr/bin/gperl"
    sudo rm -f "${root_fs_dir}/usr/bin/gpinyin"
    sudo rm -f "${root_fs_dir}/usr/bin/grog"
    sudo rm -f "${root_fs_dir}/usr/bin/gropdf"
    sudo rm -f "${root_fs_dir}/usr/bin/mmroff"
    sudo rm -f "${root_fs_dir}/usr/bin/pdfmom"

    # git-core perl scripts
    sudo rm -f "${root_fs_dir}/usr/bin/git-cvsserver"
    sudo rm -f "${root_fs_dir}/usr/libexec/git-core/git-archimport"
    sudo rm -f "${root_fs_dir}/usr/libexec/git-core/git-cvsexportcommit"
    sudo rm -f "${root_fs_dir}/usr/libexec/git-core/git-cvsimport"
    sudo rm -f "${root_fs_dir}/usr/libexec/git-core/git-cvsserver"
    sudo rm -f "${root_fs_dir}/usr/libexec/git-core/git-send-email"
    sudo rm -f "${root_fs_dir}/usr/libexec/git-core/git-svn"
    sudo rm -f "${root_fs_dir}/usr/share/git-core/templates/hooks/fsmonitor-watchman.sample"

    # gitweb (perl CGI) and its launcher
    sudo rm -f "${root_fs_dir}/usr/libexec/git-core/git-instaweb"
    sudo rm -rf "${root_fs_dir}/usr/share/gitweb"
}

# Remove Python scripts orphaned by force-removing the python denylist.
# Several packages ship optional helper scripts that depend on python3, but
# python3 is removed via --nodeps in remove_denylist_rpm_packages for the base
# image. The scripts below are non-functional without the python interpreter and
# must be deleted explicitly.
remove_orphaned_python_scripts() {
    local root_fs_dir="$1"
    info "RPM mode: Removing optional python helper scripts"

    # nfs-utils helpers that are not required for core NFS client/server usage.
    sudo rm -f "${root_fs_dir}/usr/sbin/rpcctl"
    sudo rm -f "${root_fs_dir}/usr/sbin/nfsiostat"
    sudo rm -f "${root_fs_dir}/usr/sbin/nfsdclnts"
    sudo rm -f "${root_fs_dir}/usr/sbin/nfsdclddb"
    sudo rm -f "${root_fs_dir}/usr/sbin/mountstats"

    # git helper that is not required for core git usage.
    sudo rm -f "${root_fs_dir}/usr/libexec/git-core/git-p4"

    # cifs-utils helpers; core CIFS mount support remains via mount.cifs/mount.smb3.
    sudo rm -f "${root_fs_dir}/usr/bin/smb2-quota"
    sudo rm -f "${root_fs_dir}/usr/bin/smbinfo"

    # usbutils upstream drops this when Python support is disabled.
    sudo rm -f "${root_fs_dir}/usr/bin/lsusb.py"

    # xfsprogs periodic scrub wrapper and its cron hook are optional helpers.
    sudo rm -f "${root_fs_dir}/usr/sbin/xfs_scrub_all"
    sudo rm -f "${root_fs_dir}/usr/share/xfsprogs/xfs_scrub_all.cron"

    # nghttp2 helper script; not required for the shipped runtime/library usage.
    sudo rm -f "${root_fs_dir}/usr/share/nghttp2/fetch-ocsp-response"

    # ACL keeps glib-devel as dependency because Azure Linux puts some required GLib
    # binaries there, remove these python helpers that are not required.
    # TODO: move gdbus-codegen and friends out of glib-devel or split into subpackage
    sudo rm -f "${root_fs_dir}/usr/bin/gdbus-codegen"
    sudo rm -f "${root_fs_dir}/usr/bin/glib-genmarshal"
    sudo rm -f "${root_fs_dir}/usr/bin/glib-mkenums"
    sudo rm -f "${root_fs_dir}/usr/bin/gtester-report"
}

# Check whether a package name is available in the configured RPM repos.
# Uses dnf5 repoquery which is fast and doesn't modify the system.
# Returns 0 if found, 1 otherwise.
# Usage: _rpm_package_exists <root_fs_dir> <package_name>
_rpm_package_exists() {
    local root_fs_dir="$1"
    local pkg_name="$2"

    local dnf_args=(
        --installroot="${root_fs_dir}"
        --releasever=3.0
        -q
    )
    if [[ ${BOARD:-} == "arm64-usr" ]]; then
        dnf_args+=(--forcearch="aarch64")
    fi

    # repoquery exits 0 with output if package exists, 0 with no output if not
    local result
    result=$(sudo /usr/bin/dnf5 repoquery "${dnf_args[@]}" "${pkg_name}" 2>/dev/null)
    [[ -n "${result}" ]]
}

# Install RPM packages to image using dnf5
# Usage: rpm_install_package [--nogpgcheck] <root_fs_dir> <package> [package ...]
rpm_install_package() {
    local nogpgcheck=false
    if [[ "${1:-}" == "--nogpgcheck" ]]; then
        nogpgcheck=true
        shift
    fi
    local root_fs_dir="$1"; shift
    local packages=("$@")

    if [[ ${#packages[@]} -eq 0 ]]; then
        return 0
    fi

    info "Installing ${#packages[@]} RPM packages using dnf5: ${packages[*]}"

    # Build dnf5 command arguments (always use --nodocs to minimize image size)
    local dnf_args=(
        --installroot="${root_fs_dir}"
        --releasever=3.0
        --nodocs
        -y
    )

    if [[ ${BOARD:-} == "arm64-usr" ]]; then
        dnf_args+=(--forcearch="aarch64")
    fi

    if [[ "${nogpgcheck}" == "true" ]]; then
        dnf_args+=(--nogpgcheck)
    fi

    # Mount pseudo-filesystems for scriptlets
    rpm_mount_pseudofs "${root_fs_dir}"

    # Disable errexit around dnf5 + unmount to guarantee pseudofs cleanup
    set +e
    info "Running: dnf5 install ${dnf_args[*]} ${packages[*]}"
    sudo /usr/bin/dnf5 install "${dnf_args[@]}" "${packages[@]}" 2>&1 | sudo tee /tmp/rpm-install.log
    local dnf_exit_code=${PIPESTATUS[0]}

    # Always unmount pseudo-filesystems after dnf5 finishes
    rpm_umount_pseudofs "${root_fs_dir}"
    set -e

    # Check for errors in output
    if grep -q "Error: transaction check" /tmp/rpm-install.log || \
       grep -q "error: transaction check" /tmp/rpm-install.log || \
       grep -q "Error:" /tmp/rpm-install.log || \
       [[ $dnf_exit_code -ne 0 ]]; then
        error "Failed to install RPM packages"
        error "DNF install command failed with exit code: $dnf_exit_code"
        error "Full output:"
        cat /tmp/rpm-install.log | while IFS= read -r line; do
            error "  $line"
        done
        return 1
    fi

    remove_denylist_rpm_packages "${root_fs_dir}"

    remove_orphaned_perl_scripts "${root_fs_dir}"

    remove_orphaned_python_scripts "${root_fs_dir}"

    # Remove documentation and locale directories that Portage mode excludes via INSTALL_MASK (see make.defaults)
    info "RPM mode: Removing documentation and locale directories (INSTALL_MASK parity)"
    sudo rm -rf "${root_fs_dir}/usr/share/doc"
    sudo rm -rf "${root_fs_dir}/usr/share/man"
    sudo rm -rf "${root_fs_dir}/usr/share/info"
    sudo rm -rf "${root_fs_dir}/usr/share/gtk-doc"
    sudo rm -rf "${root_fs_dir}/usr/share/bash-completion"
    sudo rm -rf "${root_fs_dir}/usr/share/zsh"
    sudo rm -rf "${root_fs_dir}/usr/share/locale"

    # Remove /var/log/README symlink and patch legacy.conf so systemd-tmpfiles
    # won't recreate it at boot. The target (usr/share/doc/systemd/README.logs)
    # was removed above with /usr/share/doc
    sudo rm -f "${root_fs_dir}/var/log/README"
    if [[ -f "${root_fs_dir}/usr/lib/tmpfiles.d/legacy.conf" ]]; then
        sudo sed -i '\|/var/log/README|d' "${root_fs_dir}/usr/lib/tmpfiles.d/legacy.conf"
    fi

    # Remove debug info
    info "RPM mode: Removing debug info files"
    sudo rm -rf "${root_fs_dir}/usr/lib/debug"

    # Remove dangling ignition-delete-config.service symlink from sysinit.target.wants.
    # The coreos-init RPM installs this symlink but the target unit doesn't exist.
    sudo rm -f "${root_fs_dir}/usr/lib/systemd/system/sysinit.target.wants/ignition-delete-config.service"

    info "Successfully installed ${#packages[@]} RPM packages"

    # Append explicitly installed packages to build log
    local pkg_log="${BUILD_DIR}/.rpm-packages-explicit"
    printf '%s\n' "${packages[@]}" >> "${pkg_log}"

    return 0
}

# Import Microsoft GPG key into a root filesystem's RPM database for signature verification.
# The key is baked into the SDK container at /etc/pki/rpm-gpg/MICROSOFT-RPM-GPG-KEY.
#
# Usage: rpm_import_gpg_key <root_fs_dir>
rpm_import_gpg_key() {
    local root_fs_dir="$1"

    local gpg_key="/etc/pki/rpm-gpg/MICROSOFT-RPM-GPG-KEY"
    if [[ -f "${gpg_key}" ]]; then
        info "Importing Microsoft GPG key into ${root_fs_dir} RPM database"
        sudo rpm --root="${root_fs_dir}" --import "${gpg_key}"
    else
        die "Microsoft GPG key not found at ${gpg_key} — it must be baked into the SDK container"
    fi
}

# Install local RPM files directly to a root filesystem with GPG verification
# This is used for installing packages to BOARD_ROOT without dependency resolution
# (e.g., bootloader packages that only need binaries, not runtime dependencies)
#
# Note: Call rpm_import_gpg_key first to enable signature verification
#
# Usage: rpm_install_local_packages <root_fs_dir> <rpm_file> [rpm_file ...]
rpm_install_local_packages() {
    local root_fs_dir="$1"; shift
    local rpm_files=("$@")

    if [[ ${#rpm_files[@]} -eq 0 ]]; then
        warn "rpm_install_local_packages: no RPM files specified"
        return 0
    fi

    info "Installing ${#rpm_files[@]} local RPM(s) to ${root_fs_dir} with GPG signature verification"
    local rpm_args=(
        --root="${root_fs_dir}"
        --install
        --verbose
        --replacepkgs
        --nodeps
    )

    if [[ ${BOARD:-} == "arm64-usr" ]]; then
        rpm_args+=(--ignorearch)
    fi

    sudo rpm "${rpm_args[@]}" "${rpm_files[@]}"

    if [[ $? -ne 0 ]]; then
        error "Failed to install local RPM packages to ${root_fs_dir}"
        return 1
    fi

    info "Successfully installed ${#rpm_files[@]} local RPM(s) to ${root_fs_dir}"
    return 0
}

# This handles: database init, repository setup
rpm_install_init() {
    local root_fs_dir="$1"; shift

    # Initialize RPM database if needed
    rpm_init_database "${root_fs_dir}" || return 1

    # Setup repositories
    local rpm_staging
    rpm_staging=$(rpm_get_staging_dir 2>/dev/null || echo "")
    local local_cache="${RPM_LOCAL_CACHE:-${rpm_staging}}"
    rpm_setup_repos "${root_fs_dir}" "3.0" "${local_cache}"
}

# Query installed RPM packages
rpm_query_packages() {
    local root_fs_dir="$1"
    local dbpath="${root_fs_dir}/var/lib/rpm"

    if [[ ! -d "${dbpath}" ]]; then
        return 0
    fi

    # Use --dbpath only and simple -qa (default format is NVRA which is what we want)
    sudo rpm --dbpath="${dbpath}" -qa 2>/dev/null | sort
}

# Get RPM package metadata
rpm_get_metadata() {
    local root_fs_dir="$1"
    local package="$2"
    local key="$3"
    local dbpath="${root_fs_dir}/var/lib/rpm"

    local format=""
    case "$key" in
        LICENSE) format="%{LICENSE}" ;;
        HOMEPAGE) format="%{URL}" ;;
        VERSION) format="%{VERSION}" ;;
        RELEASE) format="%{RELEASE}" ;;
        ARCH) format="%{ARCH}" ;;
        SUMMARY) format="%{SUMMARY}" ;;
        DESCRIPTION) format="%{DESCRIPTION}" ;;
        CONTENTS)
            # For RPM, list files in the package
            sudo rpm --dbpath="${dbpath}" -ql "${package}" 2>/dev/null | sed 's/^/obj /'
            return
            ;;
        SRC_URI)
            # RPM doesn't have SRC_URI, return URL instead
            format="%{URL}"
            ;;
        *) format="%{${key}}" ;;
    esac

    # Use --dbpath only (not --root which doesn't work correctly)
    local result
    result=$(sudo rpm --dbpath="${dbpath}" -q "${package}" --qf "${format}" 2>/dev/null)
    # Sanitize output - remove control characters that break JSON
    echo "$result" | tr -d '\000-\011\013-\037'
}

# Get all dependencies for a package using emerge --pretend
# Returns list of category/package names that would be installed
# Usage: get_portage_dependencies "/path/to/root" "coreos-base/coreos"
get_portage_dependencies() {
    local root_fs_dir="$1"
    local package="$2"

    # Determine the correct config root
    # For sysext builds, use the board config; for image builds, use BUILD_DIR/configroot
    local config_root="/build/${BOARD:-amd64-usr}"
    if [[ -d "${BUILD_DIR}/configroot" ]]; then
        config_root="${BUILD_DIR}/configroot"
    fi

    local emerge_output
    info "Resolving dependencies for ${package}"
    emerge_output=$(emerge-amd64-usr --pretend --verbose --tree "${package}" 2>&1) || true

    # Parse [binary N] or [ebuild N] lines
    # Format: [ebuild  N     ] category/package-version:slot/subslot::repo  USE="..." SIZE
    # We want to extract just "category/package"
    local parsed_pkgs
    parsed_pkgs=$(echo "$emerge_output" | \
        grep -E '^\[(binary|ebuild)' | \
        sed -E 's/^\[[^]]+\]\s+//' | \
        sed -E 's/-[0-9]+(\.[0-9]+)*.*$//' | \
        sort -u) || true

    if [[ -z "$parsed_pkgs" ]]; then
        warn "No packages found in emerge output for ${package}. Checking for errors..."
        # Check for common issues
        if echo "$emerge_output" | grep -q "USE changes are necessary"; then
            warn "USE flag changes required - check package.use configuration"
        fi
        if echo "$emerge_output" | grep -q "blocked by"; then
            warn "Package blockers detected"
        fi
        info Emerge output:
        info "$emerge_output"
        info "End of emerge output."

        die "Failed to resolve dependencies for ${package} - no packages found in emerge output"
    fi

    echo "$parsed_pkgs"
}

# Get dependencies for multiple packages
# Usage: get_all_dependencies "/path/to/root" "pkg1" "pkg2" ...
get_all_dependencies() {
    local root_fs_dir="$1"; shift
    local packages=("$@")
    local all_deps=()

    for pkg in "${packages[@]}"; do
        # Check if package is already in RPM catalog with RPM status
        local pkg_status=$(get_package_status "$pkg")

        if [[ "$pkg_status" == "RPM" ]]; then
            # Package has RPM mapping - add it directly without resolving Portage deps
            info "Package $pkg is in RPM catalog - skipping dependency resolution"
            all_deps+=("$pkg")
        else
            # Package not in RPM catalog - resolve Portage dependencies
            info "Resolving Portage dependencies for $pkg (status: $pkg_status)"
            local deps
            deps=$(get_portage_dependencies "${root_fs_dir}" "${pkg}")
            while IFS= read -r dep; do
                [[ -n "$dep" ]] && all_deps+=("$dep")
            done <<< "$deps"
        fi
    done

    # Return unique sorted list
    if [[ ${#all_deps[@]} -gt 0 ]]; then
        printf '%s\n' "${all_deps[@]}" | sort -u
    fi
}

# Full RPM mode installation workflow:
# For each package, first attempt direct RPM installation (the name may already
# be a valid RPM package).  If the name is not found in the repos, fall back to
# the portage-to-RPM catalog translation and dependency resolution.
rpm_install_package_using_portage_name() {
    local root_fs_dir="$1"; shift
    local packages=("$@")

    info "Requested packages: ${packages[*]}"

    local direct_rpms=()
    local catalog_pkgs=()

    # Triage: check which names are directly available as RPMs.
    # Names containing '/' are portage-style (e.g. "sys-apps/foo") and go
    # straight to the catalog without probing RPM repos.
    for pkg in "${packages[@]}"; do
        if [[ "${pkg}" == */* ]]; then
            info "Package '${pkg}' is portage-style — routing to catalog"
            catalog_pkgs+=("${pkg}")
        elif _rpm_package_exists "${root_fs_dir}" "${pkg}"; then
            info "Package '${pkg}' found in RPM repos — will install directly"
            direct_rpms+=("${pkg}")
        else
            info "Package '${pkg}' not in RPM repos — falling back to catalog"
            catalog_pkgs+=("${pkg}")
        fi
    done

    # Install any packages that are directly available as RPMs
    if [[ ${#direct_rpms[@]} -gt 0 ]]; then
        info "Installing ${#direct_rpms[@]} direct RPM package(s): ${direct_rpms[*]}"
        rpm_install_package "${root_fs_dir}" "${direct_rpms[@]}" || {
            error "Failed to install direct RPM packages: ${direct_rpms[*]}"
            return 1
        }
    fi

    # Nothing left to resolve via catalog
    if [[ ${#catalog_pkgs[@]} -eq 0 ]]; then
        # Skipping backup of installed package list for now. That logic is only
        # used for the base image, and base image is only created using Portage
        # packages. We should revisit this over time.
        return 0
    fi

    # --- Catalog-based resolution for remaining packages ---
    info "Resolving ${#catalog_pkgs[@]} package(s) via catalog..."

    # Step 1: Get complete dependency tree
    local all_deps
    all_deps=$(get_all_dependencies "${root_fs_dir}" "${catalog_pkgs[@]}")

    local dep_count=$(echo "$all_deps" | grep -c . || echo 0)
    info "Total dependencies found: ${dep_count}"

    # Step 2: Categorize and report
    info "Step 2: Categorizing packages by source..."
    local rpm_pkgs=()
    local portage_pkgs=()
    local unrecognized_pkgs=()
    local skip_count=0

    while IFS= read -r dep; do
        [[ -z "$dep" ]] && continue

        local source=$(get_package_status "$dep")
        case "$source" in
            RPM)
                local rpm_name=$(get_rpm_package_name "$dep")
                [[ -n "$rpm_name" ]] && rpm_pkgs+=("$rpm_name")
                ;;
            PORTAGE)
                portage_pkgs+=("$dep")
                ;;
            SKIP)
                # Don't install, dependency satisfied elsewhere or not needed
                info "DEBUG: Skipping package: $dep"
                skip_count=$((skip_count + 1))
                ;;
            *)
                unrecognized_pkgs+=("$dep")
        esac
    done <<< "$all_deps"

    info "Categorization complete:"
    info "  Will install from RPM: ${#rpm_pkgs[@]} packages"
    info "  Will install from Portage: ${#portage_pkgs[@]} packages"
    info "  Skipped: ${skip_count} packages"

    if [[ ${#unrecognized_pkgs[@]} -gt 0 ]]; then
        error "Unrecognized packages: ${unrecognized_pkgs[*]}"
        die "Found ${#unrecognized_pkgs[@]} unrecognized package(s), catalog them first."
    fi

    if [[ ${#portage_pkgs[@]} -gt 0 ]]; then
        die "Installation of Portage packages is disabled. Extend the package catalog accordingly."
    fi

    # Step 3: Install RPM packages (base layer)
    if [[ ${#rpm_pkgs[@]} -gt 0 ]]; then
        info "Step 3: Installing RPM packages..."
        # Remove duplicates
        local unique_rpm_pkgs=($(printf '%s\n' "${rpm_pkgs[@]}" | sort -u))
        rpm_install_package "${root_fs_dir}" "${unique_rpm_pkgs[@]}" || {
            error "Failed to install RPM packages during RPM mode installation"
            error "Root filesystem: ${root_fs_dir}"
            error "Attempted to install: ${unique_rpm_pkgs[*]}"
            return 1
        }

        # Backup the installed RPM package list for later use by write_packages
        # This is needed because the RPM database may be in a different location
        # or inaccessible when write_packages runs
        # Skip for sysext builds (they don't need the backup and it causes permission issues)
        if [[ -n "${BUILD_DIR:-}" && ! "${BUILD_DIR}" =~ sysext-build ]]; then
            local backup_file="${BUILD_DIR}/.rpm_packages_installed.txt"
            info "Backing up RPM package list to ${backup_file}"
            # Use sudo to remove any existing file (may be owned by root from previous run)
            sudo rm -f "${backup_file}" 2>/dev/null || true
            # Query packages - use default format (no second argument to avoid format issues)
            rpm_query_packages "${root_fs_dir}" | sudo tee "${backup_file}" > /dev/null 2>/dev/null || true
            # Make it readable and writable by the current user for cleanup
            sudo chown "$(id -u):$(id -g)" "${backup_file}" 2>/dev/null || true
            sudo chmod 644 "${backup_file}" 2>/dev/null || true
            local backup_count=$(wc -l < "${backup_file}" 2>/dev/null || echo 0)
            info "  Backed up ${backup_count} packages to ${backup_file}"
        fi
    else
        info "Step 3: No RPM packages to install (skipped)"
    fi

    info "=== RPM mode installation complete ==="
    return 0
}

# =============================================================================
# Download RPM packages to a local staging directory
# =============================================================================
# Downloads named packages (and their dependencies) from Azure Linux repos
# into a local directory, then updates repository metadata so the directory
# can be used as a local dnf/rpm cache.
#
# Usage:  rpm_download_packages <dest_dir> <root_fs_dir> <package> [package ...]
#
# <root_fs_dir> must contain /etc/yum.repos.d/ with .repo files
# (installed by the azurelinux-repos RPM).
# -----------------------------------------------------------------------------
rpm_download_packages() {
    local dest_dir="$1"; shift
    local root_fs_dir="$1"; shift
    local packages=("$@")

    if [[ ${#packages[@]} -eq 0 ]]; then
        warn "rpm_download_packages: no packages specified"
        return 0
    fi

    mkdir -p "${dest_dir}"

    local repo_dir="${root_fs_dir}/etc/yum.repos.d"
    if [[ ! -d "${repo_dir}" ]] || ! ls "${repo_dir}"/*.repo &>/dev/null 2>&1; then
        die "rpm_download_packages: no repo files found in ${repo_dir} – is azurelinux-repos installed?"
    fi

    info "Downloading ${#packages[@]} packages to ${dest_dir}: ${packages[*]}"

    # Use --nogpgcheck for downloads since:
    # 1. Packages come from trusted Azure Linux repos configured in /etc/yum.repos.d
    # 2. They'll be verified during rpm_install_package (which uses --installroot with GPG check)
    # 3. Using --installroot here causes dnf5 to write state files inside target FS (permission issues)
    # Note: Not using --resolve to only download requested packages (dependencies installed separately)
    local download_args=(
        --setopt=reposdir="${repo_dir}"
        --releasever=3.0
        --destdir="${dest_dir}"
        --nogpgcheck
    )

    if [[ ${BOARD:-} == "arm64-usr" ]]; then
        download_args+=(--forcearch="aarch64")
    fi

    dnf5 download "${download_args[@]}" "${packages[@]}"
}

# Remove the bootstrap repo after azurelinux-repos has been installed,
# and import the GPG key into the installroot's RPM keyring.
#
# The Microsoft GPG key is already present on the SDK host (baked into the
# container image at /etc/pki/rpm-gpg/MICROSOFT-RPM-GPG-KEY), so librepo and
# RPM can resolve gpgkey=file:///etc/pki/rpm-gpg/MICROSOFT-RPM-GPG-KEY for
# both repo_gpgcheck and package gpgcheck.
rpm_use_official_repos() {
    local root_fs_dir="$1"
    local repo_dir="${root_fs_dir}/etc/yum.repos.d"
    local bootstrap_repo="${repo_dir}/azurelinux-bootstrap.repo"

    if [[ -f "${bootstrap_repo}" ]]; then
        info "Removing bootstrap repository (replaced by azurelinux-repos)"
        sudo rm -f "${bootstrap_repo}"
    fi

    # Add Nvidia repository — azurelinux-repos does not include it
    info "Adding Nvidia repository"
    sudo tee "${repo_dir}/azurelinux-nvidia.repo" > /dev/null <<'EOF'
[azurelinux-official-nvidia]
name=Azure Linux Official Nvidia $releasever $basearch
baseurl=https://packages.microsoft.com/azurelinux/$releasever/prod/nvidia/$basearch
gpgkey=file:///etc/pki/rpm-gpg/MICROSOFT-RPM-GPG-KEY
gpgcheck=1
repo_gpgcheck=1
enabled=1
skip_if_unavailable=True
sslverify=1
EOF
}

rpm_configure_selinux() {
    local root_fs_dir="$1"

    info "RPM mode: Setting SELinux policy Booleans"
    # Semanage is not in the image, so this must be done manually by writing to the local
    # booleans file; therefore, it won't take effect until the policy is rebuilt by
    # semodule (below) or 'semodule -B'.
    sudo tee "${root_fs_dir}/var/lib/selinux/targeted/active/booleans.local" > /dev/null << EOF
container_mounton_non_security=1
container_use_host_all_caps=1
cron_read_generic_user_content=1
tmpfiles_manage_all_non_security=1
user_all_users_send_syslog=1
EOF

    info "RPM mode: Installing SELinux policy hotfixes."
    local policy_hotfix="/tmp/hotfix.cil"
    sudo tee "${root_fs_dir}/${policy_hotfix}" > /dev/null << EOF
(allow kernel_t unlabeled_t (service (status start stop)))
(allow kernel_t node_t (icmp_socket (node_bind)))
(allow kernel_t self (perf_event (kernel open cpu read)))
(allow kernel_t file_type (service (start status stop)))

;
; Ported Flatcar rules
;
(allow corenet_unconfined_type node_t (icmp_socket (node_bind)))
(allow kernel_t container_domain (process2 (nnp_transition nosuid_transition)))
(typetransition kernel_t etc_t dir "cni" container_file_t)
(allow kernel_t kernel_t (capability2 (audit_read)))
(allow kernel_t kernel_t (perf_event (open cpu kernel read)))
(allow kernel_t unlabeled_t (system (module_load)))
(typetransition kernel_t var_run_t dir "flannel" container_file_t)
(allow local_login_t local_login_t (process (setpgid)))
(allow ping_t node_t (icmp_socket (node_bind)))
(allow traceroute_t node_t (icmp_socket (node_bind)))
(filecon "/usr/share/containerd(/.*)?" any (system_u object_r container_config_t ((s0)(s0))))

(allow container_domain self (bpf (map_create))) ; kubeadm.v<VERSION>.cilium.base
(allow container_domain container_file_t (file (mounton)))
(allow container_domain container_file_t (chr_file (append create getattr ioctl link lock open read rename setattr unlink write)))
(allow container_domain devpts_t (chr_file (setattr)))
(allow container_domain etc_t (file (watch))) ; kubeadm.v<VERSION>.<CNI>.base
(allow container_domain kernel_t (fd (use)))
(allow container_domain kernel_t (process (sigchld)))
(allow container_domain kernel_t (fifo_file (getattr ioctl read write open append)))
(allow container_domain kernel_t (system (module_request)))
(allow container_domain proc_kmsg_t (file (getattr read open)))
(allow container_domain tmp_t (file (read))) ; docker.base, docker.network and docker.userns
(allow container_domain tmpfs_t (dir (add_name create ioctl link lock read remove_name rename reparent rmdir setattr unlink write)))
(allow container_domain tmpfs_t (file (append create getattr ioctl link lock open read rename setattr unlink write)))
(allow container_domain tmpfs_t (lnk_file (append create getattr ioctl link lock open read rename setattr unlink write)))
(allow container_domain tmpfs_t (chr_file (append create getattr ioctl link lock open read rename setattr unlink write)))
(allow container_domain tmpfs_t (fifo_file (append create getattr ioctl link lock open read rename setattr unlink write)))
(allow container_domain tmpfs_t (filesystem (remount)))
(allow container_domain tty_device_t (chr_file (append getattr ioctl link lock open read write)))
(allow container_domain usr_t (file (watch execute execute_no_trans map))) ; kubeadm.v<VERSION>.calico.base, kubeadm.v<VERSION>.<CNI>.base
(allow container_domain var_lib_t (file (getattr ioctl open read entrypoint execute execute_no_trans)))
(allow container_domain var_lib_t (lnk_file (getattr ioctl read)))

;
; Container backports and hotfixes:
;
(typeattributeset container_engine_system_domain kernel_t)
(dontaudit container_domain self (io_uring (override_creds sqpoll cmd)))
(allow container_domain self (netlink_netfilter_socket (create read write setopt bind getattr)))
(allow container_domain container_runtime_t (dir (add_name create ioctl link lock read remove_name rename reparent rmdir setattr unlink write)))
(allow container_domain container_runtime_t (file (append create getattr ioctl link lock map open read rename setattr unlink write)))
(allow container_domain container_runtime_t (lnk_file (append create getattr ioctl link lock map open read rename setattr unlink write)))
(allow container_domain container_var_lib_t (dir (add_name create ioctl link lock read remove_name rename reparent rmdir setattr unlink write)))
(allow container_domain container_var_lib_t (file (append create getattr ioctl link lock map open read rename setattr unlink write)))
(allow container_domain container_var_lib_t (lnk_file (append create getattr ioctl link lock map open read rename setattr unlink write)))
(allow container_domain proc_psi_t (file (read getattr open)))
(allow container_domain sysctl_vm_t (file (read getattr open)))
(allow spc_t self (capability2 (checkpoint_restore)))
(allow spc_t self (perf_event (tracepoint write)))
(allow spc_t file_type (service (start status stop reload)))
(allow spc_t unlabeled_t (service (start status stop reload)))
(allow spc_t unlabeled_t (system (module_load)))

; /etc/cni/net.d/10-flannel.conflist:
(allow container_domain unlabeled_t (dir (add_name search write)))
(allow container_domain unlabeled_t (file (watch getattr write open read create)))
; /opt/cni/bin/flannel:
(allow container_domain usr_t (dir (watch add_name write)))
(allow container_domain usr_t (file (create write)))

; AKS fixes
(allow unconfined_domain_type domain (io_uring (override_creds sqpoll cmd)))
EOF
    sudo chroot "${root_fs_dir}" semodule -X 200 -i "${policy_hotfix}"
    sudo rm -f "${root_fs_dir}/${policy_hotfix}"

    # Remove unnecessary SELinux policy modules (minimize the policy)
    info "RPM mode: Minimizing SELinux policy".
    sudo chroot "${root_fs_dir}" semodule -X 100 -r \
        abrt accountsd acct acpi afs aide aisexec alsa amanda amavis amtu anaconda \
        apache apcupsd apt aptcacher arpwatch asterisk auditadm automount avahi \
        awstats backup bacula bind bird bitlbee blueman bluetooth boinc brctl \
        bugzilla cachefilesd calamaris canna cdrecord certbot certmaster certmonger \
        certwatch cfengine cgmanager cgroup chkrootkit chromium chronyd clamav \
        cloudinit cobbler cockpit collectd colord comsat condor consolesetup \
        container_compat corosync couchdb courier cpucontrol cpufreqselector crio \
        cryfs ctdb cups cvs cyphesis cyrus daemontools dante dbadm dbskk ddclient \
        devicekit dhcp dictd dirmngr distcc djbdns dkim dmidecode dnsmasq docker \
        dovecot dphysswapfile dpkg drbd eg25manager entropyd evolution exim fail2ban \
        fakehwclock fapolicyd fcoe fetchmail finger firewalld firstboot fprintd ftp \
        games gatekeeper gdomap geoclue git gitosis glance glusterfs gnome gnomeclock \
        gpg gpm gpsd gssproxy guest hadoop haproxy hddtemp hostapd hwloc hypervkvp \
        i18n_input icecast ifplugd iiosensorproxy inetd inn iodine ipsec irc ircd \
        irqbalance iscsi isns jabber java kdump kerberos kerneloops keystone kismet \
        knot ksmtuned kubernetes l2tp ldap libmtp lightsquid likewise lircd livecd \
        lldpad loadkeys logadm logrotate logwatch lowmemorymonitor lpd lsm mailman \
        man2html mandb matrixd mcelog mediawiki memcached memlockd milter minidlna \
        minissdpd modemmanager mojomojo mon mongodb monit mono monop mozilla mpd \
        mplayer mrtg munin mysql nagios ncftool nessus netlabel networkmanager nis \
        node_exporter nsd nslcd ntop ntp numad nut nx obex obfs4proxy oddjob oident \
        openarc openca openct openhpi openoffice opensm openvpn openvswitch pacemaker pads \
        passenger pcscd pegasus perdition pingd pkcs pki plymouthd podman portmap \
        portreserve portslave postfix postfixpolicyd postgresql postgrey \
        powerprofiles ppp prelink prelude privoxy procmail psad publicfile \
        pulseaudio puppet pwauth pxe pyzor qemu qmail qpid quantum quota rabbitmq \
        radius radvd rasdaemon razor rdisc realmd redis remotelogin resmgr rhsmcertd \
        rkhunter rlogin rngd rootlesskit rpc rpcbind rpm rshd rssh rtkit rwho samba \
        samhain sanlock sasl sblim screen secadm sendmail sensord setroubleshoot \
        seunshare shibboleth shorewall shutdown sigrok slocate slpd slrnpull smartmon \
        smokeping smstools snmp snort sosreport soundserver spamassassin squid stubby \
        stunnel sudo svnserve switcheroo sxid sympa syncthing sysstat systemtap \
        tboot tcpd tcsd telepathy telnet tftp tgtd thunderbird thunderbolt timidity \
        tmpreaper tomcat tor tpm2 transproxy tripwire tuned tvtime tzdata ucspitcp \
        ulogd uml updfstab uptime usbguard usbmodules usbmuxd userhelper usernetctl \
        uucp uuidd uwimap varnishd vbetool vdagent vhostmd virt vlock vmware vnstatd \
        vpn watchdog wdmd webadm webalizer wine wireguard wireshark wm xen xfs \
        xguest xscreensaver xserver zabbix zarafa zebra zfs zosremote \
        > /dev/null

    info "RPM mode: Adding SELinux policy compatibility fixes"
    # Add policy name compatibility symlink.  The Gentoo MCS policy is
    # equivalent to the RHEL/CentOS/AzureLinux targeted policy.
    sudo ln -sf targeted "${root_fs_dir}/etc/selinux/mcs"

    # Add temporary workaround for host processes running in kernel_t:
    sudo tee -a "${root_fs_dir}/etc/selinux/targeted/contexts/default_contexts" > /dev/null << EOF
system_r:kernel_t:s0		system_r:kernel_t:s0
EOF

    sudo tee "${root_fs_dir}/etc/selinux/targeted/seusers" > /dev/null << EOF
__default__:system_u:s0
EOF

    info "RPM mode: Setting SELinux to enforcing"
    sudo sed -r -i -e '/^SELINUX=/s/permissive/enforcing/' "${root_fs_dir}/etc/selinux/config"
}

# Unmount any pseudo-filesystems under BUILD_DIR before rm -rf.
# Call this before removing build output directories to avoid
# "Device or resource busy" errors from stale /dev bind-mounts.
rpm_cleanup_build_dir() {
    local build_dir="$1"
    if [[ ! -d "${build_dir}" ]]; then
        return 0
    fi
    # Look for any rootfs dirs that might have pseudofs mounted
    local rootfs_dir
    for rootfs_dir in "${build_dir}"/*-rootfs "${build_dir}"/rootfs; do
        if [[ -d "${rootfs_dir}" ]]; then
            rpm_umount_pseudofs "${rootfs_dir}" 2>/dev/null || true
        fi
    done
}

# Export functions
export -f rpm_install_package_using_portage_name
export -f rpm_get_staging_dir
export -f rpm_install_init
export -f rpm_install_package
export -f rpm_query_packages
export -f rpm_get_metadata
export -f rpm_download_packages
export -f rpm_use_official_repos
export -f rpm_cleanup_build_dir
export -f rpm_umount_pseudofs
export -f rpm_configure_selinux
