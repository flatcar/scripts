The `0001-cmd-link-stop-forcing-binutils-gold-dependency-on-aa.patch`
drops the use of the gold linker. Track the following to see when it
needs to be dropped:

- https://go-review.googlesource.com/c/go/+/391115
- https://github.com/golang/go/issues/22040
