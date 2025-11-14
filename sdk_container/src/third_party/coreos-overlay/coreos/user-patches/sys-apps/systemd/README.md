Most of these patches are not really upstreamable.

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
