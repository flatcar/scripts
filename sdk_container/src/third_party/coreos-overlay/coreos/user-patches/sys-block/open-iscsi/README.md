The patch `0001-open-iscsi-startup-automatic.patch` file is because we want
nodes to start automatically. See
https://github.com/flatcar/scripts/commit/8fb48ff69f29e64da3df6a197662904f60af25f5

The patch `0002-fix-security-issues.patch` fixes CVE-2026-44943 and
CVE-2026-44944, and can be dropped when updating to open-iscsi 2.1.12.
