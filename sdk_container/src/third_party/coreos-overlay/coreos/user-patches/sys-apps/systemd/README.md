Most of these patches are not really upstreamable:

- `0001-wait-online-set-any-by-default.patch`
  - backward compat stuff
- `0002-needs-update-don-t-require-strictly-newer-usr.patch`
  - trigger updates only when /usr changes
- `0003-core-use-max-for-DefaultTasksMax.patch`
  - increase the too-low limits
- `0004-units-Keep-using-old-journal-file-format.patch`
  - backward compat stuff
- `0005-tmpfiles.d-Fix-DNS-issues-with-default-k8s-configura.patch`
  - workaround for issues with default k8s coredns config
- `0006-units-Make-multi-user.target-the-default-target.patch`
  - change default.target to a suitable symlink for Flatcar

These patches can be dropped after we update to systemd 260:

- `0009-vpick-Don-t-use-openat-directly-but-resolve-symlinks.patch`
- `0010-discover-image-Follow-symlinks-in-a-given-root.patch`
- `0011-sysext-Use-correct-image-name-for-extension-release-.patch`
- `0012-test-Add-tests-for-handling-symlinks-with-systemd-sy.patch`
- `0013-sysext-Create-mutable-directory-with-the-right-mode.patch`
- `0014-sysext-Skip-refresh-if-no-changes-are-found.patch`
- `0015-sysext-Get-verity-user-certs-from-given-root.patch`
- `0016-sysext-introduce-global-config-file.patch`
- `0017-man-sysext.conf-add-systemd-sysext-config-files.patch`
- `0018-sysext-support-ImagePolicy-global-config-option.patch`
- `0019-sysext-Fix-config-file-support-with-root.patch`

This patch can be dropped after updating to systemd 258.5:

- `0020-Drop-machine-id-OSC-event-field-if-etc-machine-id-do.patch`
