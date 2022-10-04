# Common gpg setup code to be sourced by other scripts in this
# directory. It will set up GnuPG home directory, possibly with a key
# from SIGNING_KEY environment variable.
#
# After this file is sourced, SIGNER is always defined and exported,
# even if empty. SIGNING_KEY is clobbered.

: ${SIGNING_KEY:=''}
: ${SIGNER:=''}

if [[ "${HOME}/.gnupg" -ef "${PWD}/.gnupg" ]]; then
    echo 'Do not source ${BASH_SOURCE} directly in your home directory - it will clobber your GnuPG directory!' >&2
    exit 1
fi

export GNUPGHOME="${PWD}/.gnupg"
rm -rf "${GNUPGHOME}"
trap 'rm -rf "${GNUPGHOME}"' EXIT
mkdir --mode=0700 "${GNUPGHOME}"
# Sometimes this directory is not automatically created thus making
# further private key imports to fail. Let's create it here as a
# workaround.
mkdir -p --mode=0700 "${GNUPGHOME}/private-keys-v1.d/"
if [[ -n "${SIGNING_KEY}" ]] && [[ -n "${SIGNER}" ]]; then
    gpg --batch --import "${SIGNING_KEY}"
else
    SIGNER=''
fi
export SIGNER
# Clobber signing key variable, we don't need it any more.
export SIGNING_KEY=''
