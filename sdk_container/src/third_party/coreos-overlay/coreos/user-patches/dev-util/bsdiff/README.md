About `0001-convert-to-sais-lite-suffix-sort.patch` - see the message
at the top of the patch.

About `0002-CVE-2020-14315.patch`:

Originally the security issue was published as
[FreeBSD-SA-16:29](https://www.freebsd.org/security/advisories/FreeBSD-SA-16:29.bspatch.asc),
which pointed to a FreeBSD
[patch](https://security.freebsd.org/patches/SA-16:29/bspatch.patch).
However, the patch was a set of huge changes including other unrelated
changes. That's why it was not simple at all to apply the patch to
bsdiff. Both Gentoo and Flatcar have not included the fix.

Fortunately X41 D-SEC
[examined](https://www.x41-dsec.de/security/news/working/research/2020/07/15/bspatch/)
the issue again, and nailed down to a simple patch that can be easily
applied to other trees. We simply take the patch with minimal changes.

See also
[CVE-2020-14315](https://nvd.nist.gov/vuln/detail/CVE-2020-14315).


Neither of the patches are unlikely to be applied to upstream, so we
will carry those indefinitely.
