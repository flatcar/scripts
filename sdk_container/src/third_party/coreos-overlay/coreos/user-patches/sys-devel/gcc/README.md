Drop `0001-constexpr.patch` when not applicable any more. It's a weird
issue, because building the same version of the compiler worked fine
before. Maybe some patch from gcc patches is at fault here. Didn't
investigate in hope that the issue is ephemeral. Some newer version of
gcc is already marked as stable for both amd64 and arm64 in Gentoo, so
this patch will most likely be dropped next week.
