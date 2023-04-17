#!/bin/bash

# Copyright (c) 2022 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# >>> This file is supposed to be SOURCED from the repository ROOT. <<<
#
# release_build() is currently called with no positional INPUT parameters but uses the signing env vars.

# Release build automation stub.
#   This script will release the image build from bincache to the cloud offers.
#
# PREREQUISITES:
#
#   1. SDK version and OS image version are recorded in sdk_container/.repo/manifests/version.txt
#   2. Scripts repo version tag of OS image version to be built is available and checked out.
#   3. Mantle container docker image reference is stored in sdk_container/.repo/manifests/mantle-container.
#   4. Vendor image and torcx docker tarball + manifest to run tests for are available on buildcache
#         ( images/[ARCH]/[FLATCAR_VERSION]/ )
#   5. SDK container is either
#       - available via ghcr.io/flatcar/flatcar-sdk-[ARCH]:[VERSION] (official SDK release)
#       OR
#       - available via build cache server "/containers/[VERSION]/flatcar-sdk-[ARCH]-[VERSION].tar.gz"
#         (dev SDK)
#
# INPUT:
#
#   (none)
#
# OPTIONAL INPUT:
#
#   1. SIGNER. Environment variable. Name of the owner of the artifact signing key.
#        Defaults to nothing if not set - in such case, artifacts will not be signed.
#        If provided, SIGNING_KEY environment variable should also be provided, otherwise this environment variable will be ignored.
#
#   2. SIGNING_KEY. Environment variable. The artifact signing key.
#        Defaults to nothing if not set - in such case, artifacts will not be signed.
#        If provided, SIGNER environment variable should also be provided, otherwise this environment variable will be ignored.
#
#   3. REGISTRY_USERNAME. Environment variable. The username to use for Docker registry login.
#        Defaults to nothing if not set - in such case, SDK container will not be pushed.
#
#   4. REGISTRY_PASSWORD. Environment variable. The password to use for Docker registry login.
#        Defaults to nothing if not set - in such case, SDK container will not be pushed.
#
#   5. Cloud credentials as secrets via the environment variables AZURE_PROFILE, AZURE_AUTH_CREDENTIALS,
#      AWS_CREDENTIALS, AWS_MARKETPLACE_CREDENTIALS, AWS_MARKETPLACE_ARN, AWS_CLOUDFORMATION_CREDENTIALS,
#      GCP_JSON_KEY, GOOGLE_RELEASE_CREDENTIALS.
#
# OUTPUT:
#
#   1. The cloud images are published with mantle's plume and ore tools
#   2. The AWS AMI text files are pushed to buildcache ( images/[ARCH]/[FLATCAR_VERSION]/ )
#   3. "./ci-cleanup.sh" with commands to clean up temporary build resources,
#        to be run after this step finishes / when this step is aborted.
#   4. If signer key was passed, signatures of artifacts from point 1, pushed along to buildcache.
#   5. DIGESTS of the artifacts from point 1, pushed to buildcache. If signer key was passed, armored ASCII files of the generated DIGESTS files too, pushed to buildcache.

function release_build() {
    # Run a subshell, so the traps, environment changes and global
    # variables are not spilled into the caller.
    (
        set -euo pipefail

        _release_build_impl "${@}"
    )
}

function _inside_mantle() {
  # Run a subshell for the same reasons as above
  (
    set -euo pipefail

    source sdk_lib/sdk_container_common.sh
    source ci-automation/ci_automation_common.sh
    source sdk_container/.repo/manifests/version.txt
    # Needed because we are not the SDK container here
    source sdk_container/.env
    CHANNEL="$(get_git_channel)"
    VERSION="${FLATCAR_VERSION}"
    azure_profile_config_file=""
    secret_to_file azure_profile_config_file "${AZURE_PROFILE}"
    azure_auth_config_file=""
    secret_to_file azure_auth_config_file "${AZURE_AUTH_CREDENTIALS}"
    aws_credentials_config_file=""
    secret_to_file aws_credentials_config_file "${AWS_CREDENTIALS}"
    aws_marketplace_credentials_file=""
    secret_to_file aws_marketplace_credentials_file "${AWS_MARKETPLACE_CREDENTIALS}"
    gcp_json_key_path=""
    secret_to_file gcp_json_key_path "${GCP_JSON_KEY}"
    google_release_credentials_file=""
    secret_to_file google_release_credentials_file "${GOOGLE_RELEASE_CREDENTIALS}"

    for platform in aws azure; do
      arches_prerelease=(amd64 arm64)
      # TODO: drop when LTS-3033 is not supported any more.
      if [[ "${CHANNEL}" == "lts" ]] && [[ "${platform}" == "azure" ]] && echo "$VERSION" | grep -q "^3033"; then
        arches_prerelease=(amd64)
      fi
      for arch in "${arches_prerelease[@]}"; do
        # Create a folder where plume stores flatcar_production_ami_*txt and flatcar_production_ami_*json
        # for later push to bincache
        rm -rf "${platform}-${arch}"
        mkdir "${platform}-${arch}"
        pushd "${platform}-${arch}"

        # For pre-release we don't use the Google Cloud token because it's not needed
        # and we don't want to upload the AMIs to GCS anymore
        # (change https://github.com/flatcar/mantle/blob/bc6bc232677c45e389feb221da295cc674882f8c/cmd/plume/prerelease.go#L663-L667
        # if you want to add GCP release code in plume pre-release instead of plume release)
        plume pre-release --force \
          --debug \
          --platform="${platform}" \
          --aws-credentials="${aws_credentials_config_file}" \
          --azure-profile="${azure_profile_config_file}" \
          --azure-auth="${azure_auth_config_file}" \
          --gce-json-key=none \
          --board="${arch}-usr" \
          --channel="${CHANNEL}" \
          --version="${FLATCAR_VERSION}" \
          --write-image-list="images.json"
        popd
      done
    done
    for arch in amd64 arm64; do
      # Create a folder where plume stores any temporarily downloaded files
      rm -rf "release-${arch}"
      mkdir "release-${arch}"
      pushd "release-${arch}"

      export product="${CHANNEL}-${arch}"
      pid=$(jq -r ".[env.product]" ../product-ids.json)

      # If the channel is 'stable' and the arch 'amd64', we add the stable-pro-amd64 product ID to the product IDs.
      # The published AMI ID is the same for both offer.
      [[ "${CHANNEL}" == "stable" ]] && [[ "${arch}" == "amd64" ]] && pid="${pid},$(jq -r '.["stable-pro-amd64"]' ../product-ids.json)"

      plume release \
        --debug \
        --aws-credentials="${aws_credentials_config_file}" \
        --aws-marketplace-credentials="${aws_marketplace_credentials_file}" \
        --publish-marketplace \
        --access-role-arn="${AWS_MARKETPLACE_ARN}" \
        --product-ids="${pid}" \
        --azure-profile="${azure_profile_config_file}" \
        --azure-auth="${azure_auth_config_file}" \
        --gce-json-key="${gcp_json_key_path}" \
        --gce-release-key="${google_release_credentials_file}" \
        --board="${arch}-usr" \
        --channel="${CHANNEL}" \
        --version="${VERSION}"
        popd
    done

    # Future: move this to "plume release", in the past this was done in "update-cloudformation-template"
    aws_cloudformation_credentials_file=""
    secret_to_file aws_cloudformation_credentials_file "${AWS_CLOUDFORMATION_CREDENTIALS}"
    export AWS_SHARED_CREDENTIALS_FILE="${aws_cloudformation_credentials_file}"
    rm -rf cloudformation-files
    mkdir cloudformation-files
    for arch in amd64 arm64; do
      generate_templates "aws-${arch}/flatcar_production_ami_all.json" "${CHANNEL}" "${arch}-usr"
    done
    aws s3 cp --recursive --acl public-read cloudformation-files/ "s3://flatcar-prod-ami-import-eu-central-1/dist/aws/"
  )
}

function publish_sdk() {
    local docker_sdk_vernum="$1"
    local sdk_name=""

    # If the registry password or the registry username is not set, we leave early.
    [[ -z "${REGISTRY_PASSWORD}" ]] || [[ -z "${REGISTRY_USERNAME}" ]] && return

    (
      # Don't print the password to stderr when logging in
      set +x
      local container_registry=""
      container_registry=$(echo "${sdk_container_common_registry}" | cut -d / -f 1)
      echo "${REGISTRY_PASSWORD}" | docker login "${container_registry}" -u "${REGISTRY_USERNAME}" --password-stdin
    )

    # Docker images are pushed in the container registry.
    for a in all amd64 arm64; do
      sdk_name="flatcar-sdk-${a}"
      docker_image_from_registry_or_buildcache "${sdk_name}" "${docker_sdk_vernum}"
      docker push "${sdk_container_common_registry}/flatcar-sdk-${a}:${docker_sdk_vernum}"
    done
}

function _release_build_impl() {
    source sdk_lib/sdk_container_common.sh
    source ci-automation/ci_automation_common.sh
    source ci-automation/gpg_setup.sh

    source sdk_container/.repo/manifests/version.txt
    # Needed because we are not the SDK container here
    source sdk_container/.env
    local sdk_version="${FLATCAR_SDK_VERSION}"
    local docker_sdk_vernum=""
    docker_sdk_vernum="$(vernum_to_docker_image_version "${sdk_version}")"
    local vernum="${FLATCAR_VERSION}"
    local docker_vernum=""
    docker_vernum="$(vernum_to_docker_image_version "${vernum}")"

    local container_name="flatcar-publish-${docker_vernum}"
    local mantle_ref
    mantle_ref=$(cat sdk_container/.repo/manifests/mantle-container)
    # A job on each worker prunes old mantle images (docker image prune), no need to do it here
    echo "docker rm -f '${container_name}'" >> ./ci-cleanup.sh

    touch sdk_container/.env # This file should already contain the required credentials as env vars
    docker run --pull always --rm --name="${container_name}" --net host \
      -w /work -v "$PWD":/work "${mantle_ref}" bash -c "git config --global --add safe.directory /work && source ci-automation/release.sh && _inside_mantle"
    # Push flatcar_production_ami_*txt and flatcar_production_ami_*json to the right bincache folder
    for arch in amd64 arm64; do
      sudo chown -R "$USER:$USER" "aws-${arch}"
      create_digests "${SIGNER}" "aws-${arch}/flatcar_production_ami_"*txt "aws-${arch}/flatcar_production_ami_"*json
      sign_artifacts "${SIGNER}" "aws-${arch}/flatcar_production_ami_"*txt "aws-${arch}/flatcar_production_ami_"*json
      copy_to_buildcache "images/${arch}/${vernum}/" "aws-${arch}/flatcar_production_ami_"*txt* "aws-${arch}/flatcar_production_ami_"*json*
    done
    if [ "${vernum}" = "${sdk_version}" ]; then
      publish_sdk "${docker_sdk_vernum}"
    fi
    echo "===="
    echo "Done, now you can copy the images to Origin"
    echo "===="
    # Future: trigger copy to Origin in a secure way
    # Future: trigger update payload signing
    # Future: trigger website update
    # Future: trigger release email sending
    # Future: trigger push to nebraska
    # Future: trigger Origin symlink switch
}

TEMPLATE='
{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Description": "Flatcar Linux on EC2: https://kinvolk.io/docs/flatcar-container-linux/latest/installing/cloud/aws-ec2/",
  "Mappings" : {
      "RegionMap" : {
###AMIS###
      }
  },
  "Parameters": {
    "InstanceType" : {
      "Description" : "EC2 HVM instance type (m3.medium, etc).",
      "Type" : "String",
      "Default" : "m3.medium",
      "ConstraintDescription" : "Must be a valid EC2 HVM instance type."
    },
    "ClusterSize": {
      "Default": "3",
      "MinValue": "3",
      "MaxValue": "12",
      "Description": "Number of nodes in cluster (3-12).",
      "Type": "Number"
    },
    "DiscoveryURL": {
      "Description": "An unique etcd cluster discovery URL. Grab a new token from https://discovery.etcd.io/new?size=<your cluster size>",
      "Type": "String"
    },
    "AdvertisedIPAddress": {
      "Description": "Use 'private' if your etcd cluster is within one region or 'public' if it spans regions or cloud providers.",
      "Default": "private",
      "AllowedValues": ["private", "public"],
      "Type": "String"
    },
    "AllowSSHFrom": {
      "Description": "The net block (CIDR) that SSH is available to.",
      "Default": "0.0.0.0/0",
      "Type": "String"
    },
    "KeyPair" : {
      "Description" : "The name of an EC2 Key Pair to allow SSH access to the instance.",
      "Type" : "String"
    }
  },
  "Resources": {
    "FlatcarSecurityGroup": {
      "Type": "AWS::EC2::SecurityGroup",
      "Properties": {
        "GroupDescription": "Flatcar Linux SecurityGroup",
        "SecurityGroupIngress": [
          {"IpProtocol": "tcp", "FromPort": "22", "ToPort": "22", "CidrIp": {"Ref": "AllowSSHFrom"}}
        ]
      }
    },
    "Ingress4001": {
      "Type": "AWS::EC2::SecurityGroupIngress",
      "Properties": {
        "GroupName": {"Ref": "FlatcarSecurityGroup"}, "IpProtocol": "tcp", "FromPort": "4001", "ToPort": "4001", "SourceSecurityGroupId": {
          "Fn::GetAtt" : [ "FlatcarSecurityGroup", "GroupId" ]
        }
      }
    },
    "Ingress2379": {
      "Type": "AWS::EC2::SecurityGroupIngress",
      "Properties": {
        "GroupName": {"Ref": "FlatcarSecurityGroup"}, "IpProtocol": "tcp", "FromPort": "2379", "ToPort": "2379", "SourceSecurityGroupId": {
          "Fn::GetAtt" : [ "FlatcarSecurityGroup", "GroupId" ]
        }
      }
    },
    "Ingress2380": {
      "Type": "AWS::EC2::SecurityGroupIngress",
      "Properties": {
        "GroupName": {"Ref": "FlatcarSecurityGroup"}, "IpProtocol": "tcp", "FromPort": "2380", "ToPort": "2380", "SourceSecurityGroupId": {
          "Fn::GetAtt" : [ "FlatcarSecurityGroup", "GroupId" ]
        }
      }
    },
    "FlatcarServerAutoScale": {
      "Type": "AWS::AutoScaling::AutoScalingGroup",
      "Properties": {
        "AvailabilityZones": {"Fn::GetAZs": ""},
        "LaunchConfigurationName": {"Ref": "FlatcarServerLaunchConfig"},
        "MinSize": "3",
        "MaxSize": "12",
        "DesiredCapacity": {"Ref": "ClusterSize"},
        "Tags": [
            {"Key": "Name", "Value": { "Ref" : "AWS::StackName" }, "PropagateAtLaunch": true}
        ]
      }
    },
    "FlatcarServerLaunchConfig": {
      "Type": "AWS::AutoScaling::LaunchConfiguration",
      "Properties": {
        "ImageId" : { "Fn::FindInMap" : [ "RegionMap", { "Ref" : "AWS::Region" }, "AMI" ]},
        "InstanceType": {"Ref": "InstanceType"},
        "KeyName": {"Ref": "KeyPair"},
        "SecurityGroups": [{"Ref": "FlatcarSecurityGroup"}],
        "UserData" : { "Fn::Base64":
          { "Fn::Join": [ "", [
            "#cloud-config\n\n",
            "coreos:\n",
            "  etcd2:\n",
            "    discovery: ", { "Ref": "DiscoveryURL" }, "\n",
            "    advertise-client-urls: http://$", { "Ref": "AdvertisedIPAddress" }, "_ipv4:2379\n",
            "    initial-advertise-peer-urls: http://$", { "Ref": "AdvertisedIPAddress" }, "_ipv4:2380\n",
            "    listen-client-urls: http://0.0.0.0:2379,http://0.0.0.0:4001\n",
            "    listen-peer-urls: http://$", { "Ref": "AdvertisedIPAddress" }, "_ipv4:2380\n",
            "  units:\n",
            "    - name: etcd2.service\n",
            "      command: start\n",
            "    - name: fleet.service\n",
            "      command: start\n"
            ] ]
          }
        }
      }
    }
  }
}
'
function generate_templates() {
    local IFILE="$1"
    local CHANNEL="$2"
    local BOARD="$3"
    local TMPFILE=""
    local ARCHTAG=""

    local REGIONS=("eu-central-1"
                   "ap-northeast-1"
                   "ap-northeast-2"
                   # "ap-northeast-3" #  Disabled for now because we do not have access
                   "af-south-1"
                   "ca-central-1"
                   "ap-south-1"
                   "sa-east-1"
                   "ap-southeast-1"
                   "ap-southeast-2"
                   "ap-southeast-3"
                   "us-east-1"
                   "us-east-2"
                   "us-west-2"
                   "us-west-1"
                   "eu-west-1"
                   "eu-west-2"
                   "eu-west-3"
                   "eu-north-1"
                   "eu-south-1"
                   "ap-east-1"
                   "me-south-1")

    if [ "${BOARD}" = "amd64-usr" ]; then
      ARCHTAG=""
    elif [ "${BOARD}" = "arm64-usr" ]; then
      ARCHTAG="-arm64"
    else
      echo "No architecture tag defined for board \"${BOARD}\""
      exit 1
    fi

    TMPFILE=$(mktemp)

    >${TMPFILE}
    for region in "${REGIONS[@]}"; do
        echo "         \"${region}\" : {" >> ${TMPFILE}
        echo -n '             "AMI" : ' >> ${TMPFILE}
        cat "${IFILE}" | jq ".[] | map(select(.name == \"${region}\")) | .[0] | .\"hvm\"" >> ${TMPFILE}
        echo "         }," >> ${TMPFILE}
    done

    truncate -s-2 ${TMPFILE}

    echo "${TEMPLATE}" | perl -i -0pe "s/###AMIS###/$(cat -- ${TMPFILE})/g" > "cloudformation-files/flatcar-${CHANNEL}${ARCHTAG}-hvm.template"

    rm "${TMPFILE}"
}
