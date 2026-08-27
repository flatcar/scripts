#!/bin/bash
#
# Validate the golden document against SPDX 2.2 and the NTIA minimum elements.
#
# Deliberately not in CI because it requires third-party Python packages, and
# test_generate_package_manifest.sh, which is in CI, already validates that the
# generator reproduces the golden document byte for byte. This, however, says
# nothing about whether that document is a valid one, so this script is run
# whenever it is regenerated.
#
# The NTIA minimum elements are the published floor for identifying a component
# well enough to map it to a vulnerability database.
# -- https://www.ntia.gov/sites/default/files/publications/sbom_minimum_elements_report_0.pdf
#
# Usage: validate_golden_manifest.sh [workdir]

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFORMANCE="${TESTS_DIR}/test_generate_package_manifest.sh"

REQUIREMENTS="${TESTS_DIR}/requirements.txt"

if [[ $# -ge 1 ]]; then
    WORK_DIR="${1}"
else
    WORK_DIR="$(mktemp -d)"
    trap 'rm -rf "${WORK_DIR}"' EXIT
fi
mkdir -p "${WORK_DIR}"

# Validating the generated document rather than the golden file itself, because
# the golden is normalized to drop the generator's source digest and so is not
# the shape that ships. This also fails first if the two have diverged.
"${CONFORMANCE}" "${WORK_DIR}"

MANIFEST="${WORK_DIR}/package-manifest.spdx.json"
VENV="${WORK_DIR}/.venv"

echo "=== Provisioning validators ==="
python3 -m venv "${VENV}"
"${VENV}/bin/pip" install \
    --quiet \
    --disable-pip-version-check \
    --requirement "${REQUIREMENTS}"

# pyspdxtools prints the individual validation messages. ntia-checker re-runs
# the same spdx-tools validation internally but reports only a pass/fail
# verdict, so running pyspdxtools first is what makes a failure diagnosable.
echo "=== SPDX 2.2 validation ==="
"${VENV}/bin/pyspdxtools" --infile="${MANIFEST}"

# Both flags are already the defaults, pinned so a new release cannot move
# them: --comply cannot be fsct3-min since that needs per-package licences we
# do not have, and --sbom-spec must be spdx2 since that is what was built.
echo "=== NTIA minimum elements ==="
"${VENV}/bin/ntia-checker" --comply=ntia --sbom-spec=spdx2 "${MANIFEST}"

echo "=== PASS ==="
