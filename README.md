<h1>
  <img src="https://raw.githubusercontent.com/microsoft/azurelinux/refs/tags/3.0.20260517-3.0/assets/azurelinux-logo-48.png" alt="Azure Container Linux logo" align="left" height="44" /> &nbsp;
Azure Container Linux (ACL): Immutable, Optimized Container Host OS for AKS  
</h1>

Azure Container Linux (ACL) is a hardened, immutable, container host operating system built for Azure Kubernetes Service (AKS). It focuses on a minimal footprint, strong security defaults, and predictable node behavior so teams can run container workloads efficiently and securely.

ACL is closely related to both Azure Linux and Flatcar Container Linux: it is built from Azure Linux packages and follows Azure Linux lifecycle and CVE servicing commitments, while inheriting core design principles and image composition SDK from the Flatcar Container Linux project. By leveraging Azure Linux packages, ACL aligns with Azure's FedRAMP approval, including the Azure Linux offerings. In short, ACL combines Azure-native servicing and support with a Flatcar-inspired immutable design tailored for AKS.

## Getting started

The links below will help you get started with Azure Container Linux:
| | |
|---|---|
| **Product documentation** | <https://aka.ms/azurecontainerlinux> |
| **Release information** | [GitHub Releases](https://github.com/microsoft/azure-container-linux/releases) |
| **File a bug / feedback** | [GitHub Issues](https://github.com/microsoft/azure-container-linux/issues) |
| **Ask a question / get help** | [SUPPORT.md](SUPPORT.md) |
| **Contribution guidelines** | [CONTRIBUTING.md](CONTRIBUTING.md) |
| **Report a security issue** | [SECURITY.md](SECURITY.md) |

## Engagement & support

- **Bugs and feature requests:** file a
  [GitHub issue](https://github.com/microsoft/azure-container-linux/issues). Please search existing issues first to avoid duplicates. Share as much as you can with us regarding what you tried and what you're seeing.
- **Questions and discussion:** see [SUPPORT.md](SUPPORT.md) for the full set of channels.
- **Security vulnerabilities:** do **not** open a public issue. Follow the process in [SECURITY.md](SECURITY.md) to report privately to the Microsoft Security Response Center.
- **Pull requests:** see [CONTRIBUTING.md](CONTRIBUTING.md) for the patch-series workflow, commit-message conventions, and review expectations.
- **Community calls:** Azure Linux hosts community calls where users can connect with our product and support teams, discuss new features, share feedback, and learn how others are using Azure Linux and Azure Container Linux. Each session also includes a featured demo. The schedule for upcoming community calls (US Pacific time; PDT/PST depending on daylight saving time) is as follows:
  - 2026-07-23 08:00–09:00 PT ([Join the call][community-call-join])
  - 2026-09-24 08:00–09:00 PT ([Join the call][community-call-join])
  - 2026-11-19 08:00–09:00 PT ([Join the call][community-call-join])
  - 2027-01-28 08:00–09:00 PT ([Join the call][community-call-join])
  - 2027-03-25 08:00–09:00 PT ([Join the call][community-call-join])
  - 2027-05-27 08:00–09:00 PT ([Join the call][community-call-join])

[community-call-join]: https://teams.microsoft.com/l/meetup-join/19%3ameeting_ZDcyZjRkYWMtOWQxYS00OTk3LWFhNmMtMTMwY2VhMTA4OTZi%40thread.v2/0?context=%7b%22Tid%22%3a%2272f988bf-86f1-41af-91ab-2d7cd011db47%22%2c%22Oid%22%3a%2271a6ce92-58a5-4ea0-96f4-bd4a0401370a%22%7d

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information, see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions
or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general). Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos is subject to those third parties' policies.

## Acknowledgments

Any Linux distribution, including Azure Container Linux, benefits from contributions by the open-source software community. We gratefully acknowledge all contributions made from the broader community.

We specifically want to thank [the Flatcar Container Linux Project](https://www.flatcar.org/) for providing us with a strong foundation of an immutable container host and community. We are proud to participate and contribute to this community.

## License

Unless otherwise specified, the content of the Azure Container Linux distribution and this repository are distributed under an [MIT license](LICENSE).

This repository contains files derived from the [Flatcar Container Linux](https://www.flatcar.org/) project, which are licensed under the BSD 3-Clause license. These files retain their original license and copyright notices.

For convenience, the original BSD 3-Clause license text is included in [LICENSE-BSD-3-CLAUSE](LICENSE-BSD-3-CLAUSE).

Individual packages within the distribution are distributed under licenses specified in their package spec files and sources.
