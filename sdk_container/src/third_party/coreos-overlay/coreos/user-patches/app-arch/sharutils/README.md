`0000-gettext.patch` is for fixing a build with USE=-nls:

```
uuencode.c: In function 'process_opts':
uuencode.c:204:3: error: implicit declaration of function 'bindtextdomain' [-Wimplicit-function-declaration]
  204 |   bindtextdomain (PACKAGE, LOCALEDIR);
      |   ^~~~~~~~~~~~~~
uuencode.c:205:3: error: implicit declaration of function 'textdomain' [-Wimplicit-function-declaration]
  205 |   textdomain (PACKAGE);
      |   ^~~~~~~~~~
```

Should probably be upstreamed to sharutils and to Gentoo if it works.
