The policycoreutils ebuild calls semodule in postinst to update SELinux stores.
It does not, however, tells semodule the correct ROOT to use, so builds that go into /build/[arch]-usr end up updating the SDK's store.
This patch resolves the following error message:
```
$ emerge-amd64-usr policycoreutils
[...]
libsemanage.semanage_commit_sandbox: Error while renaming /var/lib/selinux/targeted/active to /var/lib/selinux/targeted/previous. (Invalid cross-device link)
```
The error is observed when using the SDK Container to build an OS image.
The `semanage` run in policycoreutilsi' `postinst`  now also updates the correct store, which it previously did not.
