#!/bin/bash
set -euo pipefail

# Get the cluster name from /etc/eks/cluster.conf
. /etc/eks/cluster.conf
if [[ -z "${CLUSTER_NAME}" ]]; then
  echo "No cluster name found. Aborting"
  exit 1
fi

# Query the Kubernetes version of the cluster
mkdir -p /opt/eks
shopt -s expand_aliases
alias aws="docker run --rm --network host -v /opt/eks:/eks amazon/aws-cli"
CLUSTER_VERSION=$(aws eks describe-cluster --name "${CLUSTER_NAME}" --output text --query cluster.version)

if [[ -z "${CLUSTER_VERSION}" ]]; then
  echo "No cluster version found. Aborting"
  exit 1
fi

# Select the right path depending on the Kubernetes version.
# https://github.com/awslabs/amazon-eks-ami/blob/master/Makefile
case $CLUSTER_VERSION in
  1.21)
    S3_PATH="1.21.2/2021-07-05"
    ;;
  1.20)
    S3_PATH="1.20.4/2021-04-12"
    ;;
  1.19)
    S3_PATH="1.19.6/2021-01-05"
    ;;
  1.18)
    S3_PATH="1.18.9/2020-11-02"
    ;;
  1.17)
    S3_PATH="1.17.12/2020-11-02"
    ;;
  1.16)
    S3_PATH="1.16.15/2020-11-02"
    ;;
  1.15)
    S3_PATH="1.15.12/2020-11-02"
    ;;
  *)
    echo "Unsupported Kubernetes version"
    exit 1
    ;;
esac

# Sync the contents of the corresponding EKS bucket
aws s3 sync s3://amazon-eks/${S3_PATH}/bin/linux/amd64/ /eks/

# Install AWS CNI
mkdir -p /opt/cni/bin /etc/cni/net.d
tar -C /opt/cni/bin -zxvf /opt/eks/cni-amd64-v0.6.0.tgz
tar -C /opt/cni/bin -zxvf /opt/eks/cni-plugins-linux-amd64-v0.8.6.tgz

# Make binaries executable
chmod +x /opt/eks/kubelet
chmod +x /opt/eks/aws-iam-authenticator
