The `changelog` directory contains the description of the changes introduced
into the repository.  The changes are essentially divided into 4 categories:
- changes: PRs bringing Changes and/or Enhancements
- bugfixes: PRs fixing existing issues
- security: PRs fixing security issues
- updates: PRs updating packages

## How to add the file

Based on the category the PR falls into create a new file in the respective
directory with the filename format `YYYY-MM-DD-<few-words-about-the-change>.md`
(can be generated via: `$(date '+%Y-%m-%d')-<few-words-about-the-change>.md`).
The file should contain a markdown bullet point entry (`- TEXT...`).

Example for the bugfix section:

```
- The Torcx profile `docker-1.12-no` got fixed to reference the current Docker version instead of 19.03 which wasn't found on the image, causing Torcx to fail to provide Docker [coreos-overlay#1456](https://github.com/flatcar-linux/coreos-overlay/pull/1456)
```

The contents of the file should describe the changes in a concise manner,
and only contain information relevant for the end users.
(use the past tense for the change/bugfix description to avoid confusion with
the imperative voice for actions the user should do as a result). Security
fixes of upstream packages and package updates can be kept short in most cases
and follow a standard format.

As `Updates` refer to the package updates, contents of the file should be of
the following format: `- Package Name ([Version](link to changelog))`. Example:
`- Linux ([5.10.77](https://lwn.net/Articles/874852/))`. Note the leading dash
that will create a bullet list in the rendered markdown.

The security section follows this format:

```
- Package Name ([CVE-NUMBER](NIST-LINK), [CVE-NUMBER](NIST-LINK), ...)
```

E.g., `Linux ([CVE-2021-4002](https://nvd.nist.gov/vuln/detail/CVE-2021-4002), [CVE-2020-27820](https://nvd.nist.gov/vuln/detail/CVE-2020-27820))`.
