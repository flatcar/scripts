The `changelog` directory contains the description of the changes introduced
into the repository.  The changes are essentially divided into 4 categories:
- changes: PRs bringing Changes and/or Enhancements
- bugfixes: PRs fixing existing issues
- security: PRs fixing security issues
- updates: PRs updating packages

## How to add the file

Based on the category the PR falls into create a new file in the respective
directory with the filename format `YYYY-MM-DD-<few-words-about-the-change>.md`
(can be generated via: `$(date '+%Y-%m-%d')-<few-words-about-the-change>.md`)

The contents of the file should describe the changes in an elaborative manner
(use the past tense for the change/bugfix description to avoid confusion with
the imperative voice for actions the user should do as a result). Security
fixes of upstream packages and package updates can be kept short in most cases
and follow a standard format.

As `Updates` refer to the package updates, the description of the file should
be of the following format: `Package Name [Version](link to changelog)`
Example: `Linux ([5.10.77](https://lwn.net/Articles/874852/))`
