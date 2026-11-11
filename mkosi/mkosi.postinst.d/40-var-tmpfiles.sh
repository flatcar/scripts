#!/usr/bin/env bash
# Tmpfiles rules that recreate /var at boot, and the first-boot flag.
. "${SRCDIR}/lib/postinst.sh"

# finish_image()'s two gen_tmpfiles.py passes: the first skips dirs owned by
# users flatcar-tmpfiles doesn't copy, the second records the rest.
ignores=() allowed_users=() allowed_groups=()
mapfile -t ignores < <(awk '/^[dDfFL]/ {print "--ignore=" $2}' \
                           "${root_fs_dir}"/usr/lib/tmpfiles.d/*.conf)
mapfile -t allowed_users < <(grep '^COPY_USERS=' "${root_fs_dir}/sbin/flatcar-tmpfiles" | sed -e 's/.*="\([^"]*\)"/\1/' | tr '|' '\n' | sed -e 's/^/--allow-user=/')
mapfile -t allowed_groups < <(grep '^COPY_GROUPS=' "${root_fs_dir}/sbin/flatcar-tmpfiles" | sed -e 's/.*="\([^"]*\)"/\1/' | tr '|' '\n' | sed -e 's/^/--allow-group=/')
"${SDK_SCRIPTS}/build_library/gen_tmpfiles.py" --root="${root_fs_dir}" \
    --output="${root_fs_dir}/usr/lib/tmpfiles.d/base_image_var.conf" \
    "${ignores[@]}" "${allowed_users[@]}" "${allowed_groups[@]}" "${root_fs_dir}/var"

mapfile -t ignores < <(awk '/^[dDfFL]/ {print "--ignore=" $2}' \
                           "${root_fs_dir}"/usr/lib/tmpfiles.d/*.conf)
"${SDK_SCRIPTS}/build_library/gen_tmpfiles.py" --root="${root_fs_dir}" \
    --output="${root_fs_dir}/usr/lib/tmpfiles.d/base_image_var_late.conf" \
    "${ignores[@]}" "${root_fs_dir}/var"

cat > "${root_fs_dir}/boot/flatcar/first_boot" <<EOF
If this file exists, Ignition will run and then delete the file.
EOF
