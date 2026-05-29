%global debug_package %{nil}

%global goarch %{_arch}
%ifarch x86_64
%global goarch amd64
%endif
%ifarch aarch64
%global goarch arm64
%endif

%global commit 0f8ef1aa86c59fc6d54eadaffb248feaccd1018b
%global shortcommit %(c=%{commit}; echo ${c:0:7})

Summary:        Proxy sd_notify messages between systemd and processes in different cgroups
Name:           sdnotify-proxy
Version:        0.1.0
Release:        1%{?dist}
License:        Apache-2.0
Vendor:         Microsoft Corporation
Distribution:   Azure Linux
Group:          System Environment/Base
URL:            https://github.com/flatcar/sdnotify-proxy
Source0:        https://github.com/flatcar/sdnotify-proxy/archive/%{commit}.tar.gz#/%{name}-%{shortcommit}.tar.gz

BuildRequires:  golang

%description
sdnotify-proxy solves the problem of Docker containers running under systemd
and wishing to make use of the sd_notify facility. Because Docker containers
end up running as child processes of the Docker daemon, they are in a cgroup
different from that of the service. systemd will thus not process sd_notify
events from them.

This utility proxies events between a Docker container and systemd. It is
launched with the name of a proxy socket and a command to execute.

%prep
%setup -q -n %{name}-%{commit}

%build
cd %{_builddir}/%{name}-%{commit}
go mod init github.com/coreos/sdnotify-proxy
mkdir -p %{_builddir}/bin
go build -o %{_builddir}/bin/sdnotify-proxy .

%install
install -d %{buildroot}%{_libexecdir}
install -p -m 0755 %{_builddir}/bin/sdnotify-proxy %{buildroot}%{_libexecdir}/sdnotify-proxy

%files
%license LICENSE
%doc README.md
%{_libexecdir}/sdnotify-proxy

%changelog
* Tue Feb 10 2026 Microsoft Corporation <azurelinux@microsoft.com> - 0.1.0-1
- Initial ACL package. Proxies sd_notify for Docker-containerized etcd.
