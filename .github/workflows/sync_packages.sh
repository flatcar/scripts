#!/bin/bash

set -euo pipefail

SCRIPTS_REPO=${1}; shift
SCRIPTS_BASE_BRANCH=${1}; shift
GENTOO_REPO=${1}; shift

today_date=$(date +%Y-%m-%d)
branch_name=buildbot/weekly-portage-stable-package-updates-${today_date}
"${SCRIPTS_REPO}/pkg_auto/generate_config.sh" -o "${SCRIPTS_BASE_BRANCH}" -r reports -s scripts -x trap config
"${SCRIPTS_REPO}/pkg_auto/sync_packages.sh" -w wd config "${branch_name}" "${GENTOO_REPO}"
old_head=$(git -C scripts rev-parse "${SCRIPTS_BASE_BRANCH}")
new_head=$(git -C scripts rev-parse "${branch_name}")

if [[ ${new_head} == "${old_head}" ]]; then
    echo 'UPDATED=0' >>"${GITHUB_OUTPUT}"
    exit 0
fi

body_file=./pr_body
cat <<EOF >"${body_file}"
CI: TODO

--

TODO: Changes.

--
EOF

shopt -s nullglob

for report in reports/*; do
    if [[ ! -f ${report} ]]; then
        continue
    fi
    name=${report#reports/}
    cat <<EOF >>"${body_file}"

from ${name@Q}:

```
$(cat "${report}")
```

--
EOF
done

cat <<EOF >>"${body_file}"

- [ ] changelog
- [ ] image diff
EOF

echo "UPDATED=1" >>"${GITHUB_OUTPUT}"
echo "TODAY_DATE=${today_date}" >>"${GITHUB_OUTPUT}"
echo "BRANCH=${branch_name}" >>"${GITHUB_OUTPUT}"
echo "BODY_PATH=${body_file}" >>"${GITHUB_OUTPUT}"
