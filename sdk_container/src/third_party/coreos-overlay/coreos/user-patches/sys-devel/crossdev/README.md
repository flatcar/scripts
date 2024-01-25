Upstream PR: https://github.com/gentoo/crossdev/pull/17.

We could fix it by adding "--dcat dev-debug" parameters to crossdev
invocation in build_library/toolchain_util.sh. But we add a user patch
instead, because it will fail to be applied when it stops being
necessary. That way we will know exactly when to remove the
workaround.
