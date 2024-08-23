# Copyright (c) 2021 Kinvolk GmbH
# Distributed under the terms of the Apache License 2.0

# This package is heavily based on the files distributed in
# https://github.com/awslabs/amazon-eks-ami, the files have been adapted to fit
# Flatcar Container Linux instead of Amazon Linux.

EAPI=8

DESCRIPTION="Configuration for EKS worker nodes"
HOMEPAGE="https://www.flatcar.org"
S="${WORKDIR}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 arm64"

src_prepare() {
	# The bootstrap.sh file has been downloaded from:
	# https://raw.githubusercontent.com/awslabs/amazon-eks-ami/master/files/bootstrap.sh
	# We keep our patches separate to facilitate sychronizing changes
	cp "${FILESDIR}/bootstrap.sh" "${WORKDIR}/"
	eapply "${FILESDIR}/bootstrap.patch"
	default
}

src_install() {
	exeinto /usr/share/amazon/eks
	insinto /usr/share/amazon/eks
	doexe "${WORKDIR}/bootstrap.sh"

	# These files are based on the ones found on the amazon-eks-ami repository,
	# but adapted to fit Flatcar needs. Since they are a lot simpler, we don't
	# use the patching technique, but rather just edit them as needed.
	doins "${FILESDIR}/kubelet-kubeconfig"
	doins "${FILESDIR}/kubelet.service"

	# These files are taken verbatim from the amazon-eks-ami repository:
	# https://raw.githubusercontent.com/awslabs/amazon-eks-ami/master/files/kubelet-config.json
	# https://raw.githubusercontent.com/awslabs/amazon-eks-ami/master/files/docker-daemon.json
	# https://raw.githubusercontent.com/awslabs/amazon-eks-ami/master/files/eni-max-pods.txt
	doins "${FILESDIR}/kubelet-config.json"
	doins "${FILESDIR}/docker-daemon.json"
	doins "${FILESDIR}/eni-max-pods.txt"

	# This downloading script has been created specially for Flatcar. It gets
	# the current EKS Cluster Kubernetes version and downloads all the
	# necessary files to run the kubelet on the node.
	doexe "${FILESDIR}/download-kubelet.sh"
}
