# Adapted from cross-boss. Only needed for the dev profile because we don't
# build the SDK with sysroot flags and we don't install build tools to the
# production image.
cros_pre_pkg_preinst_strip_sysroot() {
	local FILES FILE

	# Gather all the non-binary files with the --sysroot or --with-sysroot flag.
	mapfile -t -d '' < <(find "${D}" -type f -exec grep -lZEIe "--sysroot=${ROOT}\b|--with-sysroot=${EROOT}\b" {} +) FILES

	# Only continue if there are any.
	[[ ${#FILES[@]} -eq 0 ]] && return

	einfo "Stripping sysroot flags from:"
	for FILE in "${FILES[@]}"; do
		einfo "  - ${FILE#${D}}"
	done

	# Carefully strip the sysroot flags.
	local sedargs=( -i -r )
	local flag
	for flag in --{,with-}sysroot="${EROOT}"; do
		sedargs+=(
			-e "s:(, *)?\" *${flag} *\"::g"
			-e "s:(, *)?' *${flag} *'::g"
			-e "s:,? ?${flag}\b::g"
		)
	done
	sed "${sedargs[@]}" "${FILES[@]}" || die
}
