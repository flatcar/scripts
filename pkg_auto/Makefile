# ignoring SC2034 (VARIABLE_NAME appears unused), too many false
# positives
#
# ignoring SC2178 (Variable was used as an array but is now assigned a
# string.) - buggy for local variables, happens very often for
# references
SHELLCHECK_OPTS := -e SC2034 -e SC2178

all: shellcheck

shellcheck:
	docker run --rm -v "$$PWD:/mnt" koalaman/shellcheck:latest --norc --shell=bash --source-path=SCRIPTDIR --source-path=SCRIPTDIR/impl --source-path=SCRIPTDIR/impl/for-shellcheck --external-sources --check-sourced $(SHELLCHECK_OPTS) *.sh impl/*.sh
