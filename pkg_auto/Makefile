all: shellcheck

shellcheck:
	docker run --rm -v "$$PWD:/mnt" koalaman/shellcheck:latest --norc --shell=bash --source-path=SCRIPTDIR --source-path=SCRIPTDIR/impl --source-path=SCRIPTDIR/impl/for-shellcheck --external-sources --check-sourced *.sh impl/*.sh
