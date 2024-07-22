We forked this package for the following reasons:

- We override the udev rules directory. The configure script does not
  provide a way to override it, so we need to hack it, otherwise the
  configure script will figure out the wrong path in our builds. We do
  it by overriding it in Makefile.inc.in. Ideal solution here would be
  to patch btrfs-progs to allow overriding the udev path and then
  override it in the ebuild properly, without the sed hacks.
