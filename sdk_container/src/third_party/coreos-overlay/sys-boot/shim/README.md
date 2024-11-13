shim
====

The repo is used to build the shim required for secure boot. The `flatcar/shim-review`
repo hosts a `Dockerfile` that builds the shim ebuild and produces the binary
required for shim-review. The generated `shim.efi` is then submitted for review.

Once the signed shim is received, a release is cut in the `flatcar/shim-review`
repo, which is then used during the build process. It's important to note that
the version of the shim and the shim-signed ebuild should be the same. For
example, if the current version of the shim is `15.8`, the ebuild files should
be `shim-15.8.ebuild` and `shim-signed-15.8.ebuild` respectively.
