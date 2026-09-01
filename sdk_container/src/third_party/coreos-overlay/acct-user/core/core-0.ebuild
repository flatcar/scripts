# Copyright 2026 Flatcar Maintainers
# Distributed under the terms of the GNU General Public License v2

# Can't be 9 - tmpfiles eclass does not support it yet.
EAPI=8

TMPFILES_OPTIONAL=yes
inherit acct-user tmpfiles

ACCT_USER_ID=500
ACCT_USER_ENFORCE_ID=yes
ACCT_USER_COMMENT="Flatcar Admin"
ACCT_USER_HOME="/home/core"
ACCT_USER_SHELL="/bin/bash"
ACCT_USER_GROUPS=( core docker wheel systemd-journal portage )

acct-user_add_deps

declare -A CORE_BASH_SYMLINKS
CORE_BASH_SYMLINKS=(
	['.bash_logout']='/usr/share/flatcar/etc/skel/.bash_logout'
	['.bash_profile']='/usr/share/flatcar/etc/skel/.bash_profile'
	['.bashrc']='/usr/share/flatcar/etc/skel/.bashrc'
)

src_compile() {
	# Generate the tmpfiles config file for bash symlinks in
	# core's home directory.
	(
		for name in "${!CORE_BASH_SYMLINKS[@]}"; do
			target=${CORE_BASH_SYMLINKS["${name}"]}
			target=$(realpath --relative-to="${ACCT_USER_HOME}" --canonicalize-missing --no-symlinks "${target}" || die)
			echo "L ${ACCT_USER_HOME}/${name} - core core - ${target}" || die
		done
	) | LC_ALL=C sort >"${T}/home-core-bash-symlinks.conf" || die
}

src_install() {
	acct-user_src_install
	dotmpfiles "${T}/home-core-bash-symlinks.conf"
}

pkg_postinst() {
	acct-user_pkg_postinst
	local t n i name
	read -r t n i <"${EROOT}/usr/lib/sysusers.d/acct-group-core.conf" || die
	for name in "${!CORE_BASH_SYMLINKS[@]}"; do
		target=${CORE_BASH_SYMLINKS["${name}"]}
		link="${ACCT_USER_HOME}/${name}"
		ln -sfT "${target}" "${EROOT}${link}" || die
		chown --no-dereference ${ACCT_USER_ID}:${i} "${EROOT}${link}" || die
	done
	# we are putting things into the home directory, drop the
	# keepdir artifact
	rm -f "${EROOT}${ACCT_USER_HOME}/.keep_acct-user_core-"* || die
}
