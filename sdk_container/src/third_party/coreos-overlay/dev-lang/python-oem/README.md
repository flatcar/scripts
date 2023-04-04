Modifications made:

- Keep using internal expat and libffi, thus dropping dev-libs/libffi
  and dev-libs/expat from the dependencies.

- Drop dev-python/gentoo-common dependency, it provides the
  EXTERNALLY-MANAGED file, but we will provide our own.

- Since this package is installed only for OEM partition as a binary
  package, and the installation there happens after the packages
  database is removed, we unset the RDEPEND variable. The RDEPEND
  variable needs to be empty as it's also used during the binary
  package installation. The contents of RDEPEND are already inside the
  DEPEND variable, so we are safe.

- We modify the configure flags:

  - Add `--prefix=/oem/python` as `/oem` is where the OEM partition is
    mounted.

  - Add `--with-platlibdir="$(get_libdir)"`, this is to make sure that
    consistent library directory gets picked. In our case for both
    amd64 and arm64, it's lib64.

  - Change `--enable-shared` to `--disable-shared`. This will skip
    building dynamic libraries, as we don't need them.

  - Add `--includedir=/discard/include` and change `--mandir` and
    `--infodir` to also use `/discard` to install files there. Makes
    it easy to remove the unnecessary files.

  - We disable loadable sqlite extensions.

  - As we want to use the internal versions of expat and libffi, we
    change `--with-system-{expat,ffi}` to
    `--without-system-{expat,ffi}`.

  - Comment out the `--with-wheel-pkg-dir` as it's some ensurepip
    stuff we are disabling anyway.

- Essentially drop `src_install` and write our own variant, where we
  run `make altinstall`, remove unnecessary files (the original
  `src_install` could be read to find out which files to remove),
  creates a versionless python symlink, adds an EXTERNALLY-MANAGED
  file, and removes the `/discard` directory.
