#!/bin/bash
set -ex
BASE=$(dirname $(readlink -f "$0"))
git -C manifest config user.name "${GIT_AUTHOR_NAME}"
git -C manifest config user.email "${GIT_AUTHOR_EMAIL}"

COREOS_OFFICIAL=0

finish() {
        local tag="$1"
        git -C manifest tag -v "${tag}"
        git -C manifest push "${BUILDS_PUSH_URL}" "refs/tags/${tag}:refs/tags/${tag}"
        tee manifest.properties << EOF
MANIFEST_URL = ${BUILDS_CLONE_URL}
MANIFEST_REF = refs/tags/${tag}
MANIFEST_NAME = release.xml
COREOS_OFFICIAL = ${COREOS_OFFICIAL:-0}
EOF
}

# Set up GPG for verifying tags.
export GNUPGHOME="${PWD}/.gnupg"
rm -rf "${GNUPGHOME}"
trap 'rm -rf "${GNUPGHOME}"' EXIT
mkdir --mode=0700 "${GNUPGHOME}"
gpg --import verify.asc
# Sometimes this directory is not created automatically making further private
# key imports fail, let's create it here as a workaround
mkdir -p --mode=0700 "${GNUPGHOME}/private-keys-v1.d/"

# Branches are of the form remote-name/branch-name.  Tags are just tag-name.
# If we have a release tag use it, for branches we need to make a tag.
if [[ "${GIT_BRANCH}" != */* ]]
then
        COREOS_OFFICIAL=1
        finish "${GIT_BRANCH}"
        exit
fi

MANIFEST_BRANCH="${GIT_BRANCH##*/}"
MANIFEST_ID="${MANIFEST_BRANCH}"
case "${OVERRIDE_BUILD_ID:-no}" in
    no)
        :
        ;;
    scripts-ref)
        MANIFEST_ID="${SCRIPTS_REF}"
        ;;
    overlay-ref)
        MANIFEST_ID="${OVERLAY_REF}"
        ;;
    portage-ref)
        MANIFEST_ID="${PORTAGE_REF}"
        ;;
    nightly)
        MANIFEST_ID="${SCRIPTS_REF}-nightly"
        ;;
    *)
        echo "Invalid value of OVERRIDE_BUILD_ID: ${OVERRIDE_BUILD_ID}"
        exit 1
        ;;
esac

MANIFEST_NAME="${MANIFEST_NAME}.xml"
[[ -f "manifest/${MANIFEST_NAME}" ]]

source manifest/version.txt

if [[ "${SDK_VERSION}" == sdk-*-nightly ]]
then
	# Get the SDK version from GCS - we use gsutil to get access to the bucket since it's private.
	SDK_VERSION=$(docker run --rm -v "${GOOGLE_APPLICATION_CREDENTIALS}:/opt/release.json:ro" google/cloud-sdk:alpine bash -c "gcloud auth activate-service-account --key-file /opt/release.json && gsutil cat gs://flatcar-jenkins/developer/sdk/amd64/${SDK_VERSION}.txt" | tee /dev/stderr)
	if [[ -z "${SDK_VERSION}" ]]
	then
		echo "No SDK found, retrigger the manifest job with default SDK_VERSION and SDK_URL_PATH values."
		exit 1
	fi
fi

export FLATCAR_BUILD_ID="${BUILD_ID_PREFIX}${MANIFEST_ID}-${BUILD_NUMBER}"
# Nightlies and dev builds have the current date as Flatcar version
if [[ "${MANIFEST_BRANCH}" = flatcar-master ]]
then
        FLATCAR_VERSION_ID="$(date '+%Y.%m.%d')"
fi

if [[ "${SDK_VERSION}" = sdk-new ]]
then
	# Use the version of the current developer build for DOWNSTREAM=all(-full), requires a seed SDK to be set
	# (releases use git tags where all this code here is not executed because the manifest
	# and version.txt should not be modified, the Alpha release version.txt has to refer to
	# the release to be build for its SDK version)
	SDK_VERSION="${FLATCAR_VERSION_ID}+${FLATCAR_BUILD_ID}"
fi

if [[ -n "${SDK_VERSION}" ]]
then
        export FLATCAR_SDK_VERSION="${SDK_VERSION}"
fi

# Ensure that each XML tag occupies exactly one line each by first removing all line breaks and then adding
# a line break after each tag.
# This way set_manifest_ref can find the right tag by matching for "/$reponame".
cat manifest/"${MANIFEST_NAME}" | tr '\n' ' ' | sed 's#/>#/>\n#g' > "manifest/${FLATCAR_BUILD_ID}.xml"

set_manifest_ref() {
        local reponame="$1"
        local reference="$2"
        # Select lines with "/$reponame" (kept as first group) and "revision" (kept as second group) and replace the value
        # of "revision" (third group, not kept) with the new reference.
        sed -i -E "s#(/$reponame.*)(revision=\")([^\"]*)#\1\2$reference#g" "manifest/${FLATCAR_BUILD_ID}.xml"
}

setup_manifest_ref() {
    local reponame="${1}"
    local ref="${2}"
    local full_ref="refs/heads/${ref}"

    if [[ -z "${ref//[0-9]}" ]]; then
        full_ref="refs/pull/${ref}/head"
    fi
    set_manifest_ref "${reponame}" "${full_ref}"
    "${BASE}/post-github-status.sh" --repo "flatcar-linux/${reponame}" --ref "${full_ref}" --status pending
}

if [[ -n "${SCRIPTS_REF}" ]]
then
        setup_manifest_ref scripts "${SCRIPTS_REF}"
fi
if [[ -n "${OVERLAY_REF}" ]]
then
        setup_manifest_ref coreos-overlay "${OVERLAY_REF}"
fi
if [[ -n "${PORTAGE_REF}" ]]
then
        setup_manifest_ref portage-stable "${PORTAGE_REF}"
fi

ln -fns "${FLATCAR_BUILD_ID}.xml" manifest/default.xml
ln -fns "${FLATCAR_BUILD_ID}.xml" manifest/release.xml

tee manifest/version.txt << EOF
FLATCAR_VERSION=${FLATCAR_VERSION_ID}+${FLATCAR_BUILD_ID}
FLATCAR_VERSION_ID=${FLATCAR_VERSION_ID}
FLATCAR_BUILD_ID=${FLATCAR_BUILD_ID}
FLATCAR_SDK_VERSION=${FLATCAR_SDK_VERSION}
EOF
# Note: You have to keep FLATCAR_VERSION in sync with the value used in the "sdk-new" case.

# Set up GPG for signing tags.
gpg --import "${GPG_SECRET_KEY_FILE}"

# Tag a development build manifest.
git -C manifest add "${FLATCAR_BUILD_ID}.xml" default.xml release.xml version.txt
git -C manifest commit \
    -m "${FLATCAR_BUILD_ID}: add build manifest" \
    -m "Based on ${GIT_URL} branch ${MANIFEST_BRANCH}" \
    -m "${BUILD_URL}"
git -C manifest tag -u "${SIGNING_USER}" -m "${FLATCAR_BUILD_ID}" "${FLATCAR_BUILD_ID}"

finish "${FLATCAR_BUILD_ID}"
