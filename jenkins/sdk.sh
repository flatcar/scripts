#!/bin/bash
set -ex

# The build may not be started without a tag value.
[ -n "${MANIFEST_TAG}" ]

# Catalyst leaves things chowned as root.
[ -d .cache/sdks ] && sudo chown -R "$USER" .cache/sdks

# Set up GPG for verifying tags.
export GNUPGHOME="${PWD}/.gnupg"
rm -rf "${GNUPGHOME}"
trap 'rm -rf "${GNUPGHOME}"' EXIT
mkdir --mode=0700 "${GNUPGHOME}"
gpg --import verify.asc
# Sometimes this directory is not created automatically making further private
# key imports fail, let's create it here as a workaround
mkdir -p --mode=0700 "${GNUPGHOME}/private-keys-v1.d/"

if [[ "${SEED_SDK_VERSION}" == alpha ]]
then
	SEED_SDK_VERSION=$(curl -s -S -f -L "https://alpha.release.flatcar-linux.net/amd64-usr/current/version.txt" | grep -m 1 FLATCAR_SDK_VERSION= | cut -d = -f 2- | tee /dev/stderr)
	if [[ -z "${SEED_SDK_VERSION}" ]]
	then
		echo "Unexpected: Alpha release SDK version not found"
		exit 1
	fi
fi

DOWNLOAD_ROOT=${DOWNLOAD_ROOT:-"gs://flatcar-jenkins"}
# The seed SDK is always a release SDK
DOWNLOAD_ROOT_SDK="gs://flatcar-jenkins/sdk"

# We do not use a nightly SDK as seed for bootstrapping because the next major Alpha SDK release would also have to use the last published Alpha release SDK as seed.
# Also, we don't want compiler bugs to propagate from one nightly SDK to the next even though the commit in question was reverted.
# Having a clear bootstrap path is our last safety line before insanity for that kind of bugs, and is a requirement for reproducibility and security.
# Fore more info, read Ken Thompson's Turing Award Lecture "Reflections on Trusting Trust".
# In rare cases this will mean that a huge compiler update has to be split because first a released SDK with a newer compiler is needed to compile an even newer compiler
# (or linker, libc etc). For experiments one can download the nightly/developer SDK and start the bootstrap from it locally but exposing this functionality in Jenkins would
# cause more confusion than helping to understand what the requirements are to get SDK changes to a releasable state.

bin/cork update \
    --create --downgrade-replace --verify --verify-signature --verbose \
    --sdk-version "${SEED_SDK_VERSION}" \
    --force-sync \
    --json-key "${GOOGLE_APPLICATION_CREDENTIALS}" \
    --manifest-branch "refs/tags/${MANIFEST_TAG}" \
    --sdk-url storage.googleapis.com \
    --sdk-url-path "/flatcar-jenkins/sdk" \
    --manifest-name "${MANIFEST_NAME}" \
    --manifest-url "${MANIFEST_URL}"  -- --dev_builds_sdk="${DOWNLOAD_ROOT_SDK}" --setuponly

if [[ ${FULL_BUILD} == "false" ]]; then
    export FORCE_STAGES="stage4"
fi

enter() {
  # we add the public key to verify the signature with gangue
  sudo ln -f ./verify.asc chroot/opt/verify.asc
  # GCP service account to get access to private bucket during the gangue downloading
  sudo ln -f "${GOOGLE_APPLICATION_CREDENTIALS}" chroot/etc/portage/gangue.json
  bin/cork enter --bind-gpg-agent=false -- "$@"
}

source .repo/manifests/version.txt
export FLATCAR_BUILD_ID

# Set up GPG for signing uploads.
gpg --import "${GPG_SECRET_KEY_FILE}"

# Wipe all of catalyst.
sudo rm -rf src/build

# Fetch DIGEST to prevent re-downloading the same SDK tarball
enter /mnt/host/source/bin/gangue get --verify-key /opt/verify.asc --json-key /etc/portage/gangue.json "${DOWNLOAD_ROOT_SDK}/amd64/${FLATCAR_SDK_VERSION}/flatcar-sdk-amd64-${FLATCAR_SDK_VERSION}.tar.bz2.DIGESTS" /mnt/host/source/.cache/sdks/

enter sudo \
    FLATCAR_DEV_BUILDS_SDK="${DOWNLOAD_ROOT_SDK}" \
    FORCE_STAGES="${FORCE_STAGES}" \
    /mnt/host/source/src/scripts/bootstrap_sdk \
        --sign="${SIGNING_USER}" \
        --sign_digests="${SIGNING_USER}" \
        --upload_root="${UPLOAD_ROOT}" \
        --stage1_overlay_ref="${STAGE1_OVERLAY_REF}" \
        --stage1_portage_ref="${STAGE1_PORTAGE_REF}" \
        --upload

# Update entry for latest nightly build reference (there are no symlinks in GCS and it is also good to keep it deterministic)
if [[ "${FLATCAR_BUILD_ID}" == *-*-nightly-* ]]
then
  # Extract the nightly name like "flatcar-MAJOR-nightly" from "dev-flatcar-MAJOR-nightly-NUMBER"
  NAME=$(echo "${FLATCAR_BUILD_ID}" | grep -o "dev-.*-nightly" | cut -d - -f 2-)
  echo "${FLATCAR_VERSION}" | enter gsutil cp - "${UPLOAD_ROOT}/sdk/amd64/sdk-${NAME}.txt"
fi
