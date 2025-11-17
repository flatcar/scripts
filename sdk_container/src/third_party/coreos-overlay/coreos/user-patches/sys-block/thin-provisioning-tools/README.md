The patches make the thin_migrate tool optional, as this seems to be
the thing that pulls in devicemapper crate, which in order requires
bindgen crate, which in turn depends on libclang. Since thin_migrate
tools was never a part of Flatcar yet, we can skip building it for
now. If users will need the tool, we can think about adding it at a
cost of building clang in SDK builds.

The patches were filed to upstream:

https://github.com/device-mapper-utils/thin-provisioning-tools/pull/1

If they get accepted, we can try convincing Gentoo to add
"USE=+migrate" to the ebuild and hide the clang dependency behind the
flag. On Flatcar side we could then disable it.

Until that happens, these patches should be accompanied by a hook
function that will do "export ECARGO_EXTRA_ARGS=--no-default-features"
and "export MAKEOPTS=THIN_MIGRATE_EXCLUDE=x".
