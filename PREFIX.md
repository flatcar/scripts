# Steps to build a prefixed environment

```
git clone https://github.com/chewi/cross-boss.git
sudo emerge sys-apps/bubblewrap
sudo cp -r prefix/staging/usr/local/microsoft/etc/portage/repos.conf /usr/x86_64-cros-linux-gnu/etc/portage/
sudo env EPREFIX=/usr/local/microsoft /path/to/cross-boss/bin/cb-bootstrap ~/trunk/src/scripts/prefix/staging
```
