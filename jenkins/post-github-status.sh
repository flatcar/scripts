#!/bin/bash

SHFLAGS=$(dirname $(readlink -f "$0"))/../lib/shflags/shflags
. "${SHFLAGS}" || exit 1

DEFINE_string repo "" "Name of the repository to which to post status"
DEFINE_string ref "" "Reference from which to figure out commit"
DEFINE_string github_token "${GITHUB_TOKEN}" "Github Personal Access Token used to submit the commit status"
DEFINE_string status "pending" "Status to submit for commit. [failure,pending,success,error]"
DEFINE_string context "ci/jenkins" "Context to use for commit status."
DEFINE_boolean verbose "${FLAGS_FALSE}" "Show curl output"

# Parse command line
FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"

if [ -z "${FLAGS_repo}" ]; then
  echo >&2 "Error: --repo is required"
  exit 1
fi
if [ -z "${FLAGS_ref}" ]; then
  echo >&2 "Error: --ref is required"
  exit 1
fi
if [ -z "${FLAGS_github_token}" ]; then
  echo >&2 "Error: --github_token is required"
  exit 1
fi

CURLOPTS="-sS"
if [[ "${FLAGS_verbose}" -eq "${FLAGS_true}" ]]; then
  CURLOPTS=""
fi

GITHUB_API="https://api.github.com"
# BUILD_URL = JENKINS_URL + JOB_NAME + BUILD_NUMBER
target_url="${BUILD_URL}cldsv"
commit=$(git ls-remote "https://github.com/${FLAGS_repo}" "${FLAGS_ref}"| cut -f1)
if [ -z "${commit}" ]; then
  echo >&2 "Can't figure out commit for repo ${FLAGS_repo} ref ${FLAGS_ref}"
  exit 2
fi

curl ${CURLOPTS} "${GITHUB_API}/repos/${FLAGS_repo}/statuses/${commit}" \
    -H "Content-Type: application/json" \
    -H "Authorization: token ${FLAGS_github_token}" \
    -X POST -d @- <<EOF
{
  "state":"${FLAGS_status}",
  "context": "${FLAGS_context}",
  "target_url":"${target_url}"
}
EOF
