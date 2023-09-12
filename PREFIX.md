# Steps to build a prefixed environment

```
git clone https://github.com/chewi/cross-boss.git
sudo emerge sys-apps/bubblewrap
sudo emerge -1 ">=dev-python/gpep517-15"
sudo cp -r ~/trunk/src/scripts/prefix/staging/usr/local/microsoft/etc/portage/repos.conf /usr/x86_64-cros-linux-gnu/etc/portage/
sudo env EPREFIX=/usr/local/microsoft /path/to/cross-boss/bin/cb-bootstrap ~/trunk/src/scripts/prefix/staging
sudo env EPREFIX=/usr/local/microsoft /path/to/cross-boss/bin/cb-emerge ~/trunk/src/scripts/prefix/staging <USUAL EMERGE ARGS>
```
