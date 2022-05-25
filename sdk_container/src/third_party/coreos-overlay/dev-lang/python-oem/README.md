Modifications made:

- Drop `pgo` and `lto` USE flags, so flags passed to configure are
  `--without-lto` and `--disable-optimizations`. Also drop `pgo` code
  in `src_configure` and `src_compile`.

- We are not running any tests, so drop the `test` use flag and
  `src_test` function. Drop also `pkg_pretend` and `pkg_setup`
  functions as they were only doing some stuff if `test` use flag was
  enabled.

- Fix a path to a patchset that was using a `${PN}` variable, but
  expected it to be `python` while our package is actually
  `python-oem`.

- Drop the following use flags and simplify the ebuild assuming that
  they were disabled: `bluetooth examples gdbm ncurses readline sqlite
  ssl tk wininst`.

- Drop the following use flags and simplify the ebuild assuming that
  they were enabled: `build`.

- Drop `xml` use flag. Drop the dependency on expat, but instead keep
  the internal copy of expat, so we keep `_elementtree` and `pyexpat`
  modules enabled. Finally tell the configure script to use the
  internal stuff (by passing the `--without-system-expat` flag).

- Drop the dependency on libffi, instead keep using internal libffi
  and tell the configure script to use internal stuff (by passing the
  `--without-system-ffi` flag).

- Rename `RDEPEND` to `DEPEND`, so `RDEPEND` remains empty. OEM
  packages are installed after production images are pruned of the
  previously installed package database.

- Make the following changes in configure flags:

  - Add `--prefix=/usr/share/oem/python` to the `myeconfargs` variable.

  - To make sure that python library ends up where we want (for
    example, in `lib64` instead of `lib`, because in this prefix, we
    have no symlinks from `lib` to `lib64`), add
    `--with-platlibdir=$(get_libdir)` to the `myeconfargs` variable.

  - Change `--enable-shared` to `--disable-shared`.

  - Set `--mandir`, `--infodir` and `--includedir` to some subdirectory of
    `/discard`, so during installation this could be easily removed.

  - Drop `--enable-loadable-sqlite-extensions` flag.

- Export some configure variables for the cross-compilation:
  `ac_cv_file__dev_ptc` and `ac_cv_file__dev_ptmx`. If not done, build
  will fail with a message saying that these should be set to either
  yes or no.

- Drop pax stuff (search for `pax-utils` and `pax-mark`) - it's noop
  on Flatcar.

- Simplify `src_install`:

  - Replace the hardcoded `${ED}/usr` with `${ED}/usr/share/oem/python`.

  - Drop sed stuff mucking with `LDFLAGS`.

  - Drop collision fixes.

  - Drop `ABIFLAGS` hack.

  - Do not install ACKS, HISTORY and NEWS files.

  - Drop gdb autoload stuff.

  - Drop `pydoc.{conf,init}` stuff.

  - Drop `epython.py` stuff.

  - Drop python-exec stuff.

    - Just everything below that involves `${scriptdir}`.

  - Create versionless links (python and python3) to python executable.

  - Remove installed stuff in `/discard`.
