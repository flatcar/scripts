#!/usr/bin/python3
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "azure-storage-blob>=12.27.1",
# ]
# ///
import os
import copy
import json
import argparse
import requests
import logging

from azure.storage.blob import BlobClient, generate_container_sas, BlobSasPermissions
from datetime import datetime, timedelta

logging.basicConfig(level=logging.DEBUG)

# Configuration data (previously in config.toml)
CONFIG = {
    "az_storage": {
        "account_name": "flatcar",
        "container_name": "publish",
        "blob_name_format": "flatcar-linux-{version}-{plan}-{arch}.vhd"
    },
    "offer_metadata": {
        "flatcar-container-linux-corevm": "arm64",
        "flatcar-container-linux-corevm-amd64": "amd64",
        "flatcar-container-linux-free": "amd64",
        "flatcar-container-linux": "amd64",
    },
    "plan_metadata": {
        "alpha": ["flatcar-container-linux-corevm", "flatcar-container-linux-corevm-amd64", "flatcar-container-linux-free", "flatcar-container-linux"],
        "beta": ["flatcar-container-linux-corevm", "flatcar-container-linux-corevm-amd64", "flatcar-container-linux-free", "flatcar-container-linux"],
        "stable": ["flatcar-container-linux-corevm", "flatcar-container-linux-corevm-amd64", "flatcar-container-linux-free", "flatcar-container-linux"],
        "lts2024": ["flatcar-container-linux-free", "flatcar-container-linux", "flatcar-container-linux-corevm-amd64", "flatcar-container-linux-corevm"],
    },
    "test_offer_metadata": {
        "test-release-automation-corevm": "amd64",
        "test-release-automation": "amd64",
    },
    "test_plan_metadata": {
        "release-test-automation": ["test-release-automation-corevm", "test-release-automation"],
    }
}


def generate_partner_center_token(tenant_id, client_id, secret_value):
    data = f"grant_type=client_credentials&client_id={client_id}&client_secret={secret_value}&resource=https://graph.microsoft.com"
    resp = requests.post(
        url=f"https://login.microsoftonline.com/{tenant_id}/oauth2/token",
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        data=data,
    )
    access_token = resp.json().get("access_token")
    return access_token


def generate_az_sas_url(plan, version, arch, **kwargs):
    az_storage_key = os.environ.get("AZ_STORAGE_KEY")
    if az_storage_key is None:
        logging.error("missing env: AZ_STORAGE_KEY")
        return

    az_storage = CONFIG.get("az_storage")
    if not az_storage:
        logging.error("Missing `az_storage` section in config")

    account_name = az_storage.get("account_name")
    if not account_name:
        logging.error("Missing `account_name` section in config")

    container_name = az_storage.get("container_name")
    if not container_name:
        logging.error("Missing `container_name` section in config")

    if kwargs.get("test_plan"):
        plan = kwargs.get("test_plan")

    blob_name_format = az_storage.get("blob_name_format")
    if not blob_name_format:
        logging.error("Missing `blob_name_format` section in config")

    blob_name = blob_name_format.format(version=version, plan=plan, arch=arch)

    sas_query_params = generate_container_sas(
        account_name=account_name,
        account_key=az_storage_key,
        container_name=container_name,
        permission="rl",
        start=datetime.utcnow() - timedelta(days=1),
        expiry=datetime.utcnow() + timedelta(weeks=4),
    )

    if sas_query_params is not None:
        return f"https://{account_name}.blob.core.windows.net/{container_name}/{blob_name}?{sas_query_params}"
    else:
        return None


def get_product_durable_id(access_token, offer):
    resp = requests.get(
        url=f"https://graph.microsoft.com/rp/product-ingestion/product?externalId={offer}",
        headers={"Authorization": f"Bearer {access_token}"},
    )

    return resp.json().get("value", [])[0].get("id")


def get_plan_durable_id(access_token, product_durable_id, plan):
    resp = requests.get(
        url=f"https://graph.microsoft.com/rp/product-ingestion/plan?product={product_durable_id}&externalId={plan}",
        headers={"Authorization": f"Bearer {access_token}"},
    )

    return resp.json().get("value", [])[0].get("id")


def get_image_versions(access_token, product_durable_id, plan_durable_id, corevm=False):
    endpoint = "virtual-machine-plan-technical-configuration"
    if corevm:
        endpoint = "core-virtual-machine-plan-technical-configuration"

    resp = requests.get(
        url=f"https://graph.microsoft.com/rp/product-ingestion/{endpoint}/{product_durable_id}/{plan_durable_id}",
        headers={"Authorization": f"Bearer {access_token}"},
    )

    return resp.json().get("vmImageVersions")


def draft_new_image_versions(
    access_token,
    plan,
    offer,
    version,
    az_sas_url,
    image_versions,
    image_type_arch,
    corevm=False,
):
    new_vm_image = {
        "versionNumber": version,
        "vmImages": [
            {
                "imageType": f"{image_type_arch}Gen2",
                "source": {
                    "sourceType": "sasUri",
                    "osDisk": {"uri": az_sas_url},
                    "dataDisks": [],
                },
            },
        ],
    }

    if image_type_arch != "arm64":
        new_vm_image["vmImages"].append(
            {
                "imageType": f"{image_type_arch}Gen1",
                "source": {
                    "sourceType": "sasUri",
                    "osDisk": {"uri": az_sas_url},
                    "dataDisks": [],
                },
            }
        )

    image_versions.append(new_vm_image)

    schema_url = "https://schema.mp.microsoft.com/schema/virtual-machine-plan-technical-configuration/2022-03-01-preview3"
    if corevm:
        schema_url = "https://schema.mp.microsoft.com/schema/core-virtual-machine-plan-technical-configuration/2022-03-01-preview5"

    sku_id = f"{plan}-gen2"
    if image_type_arch == "arm64":
        sku_id = f"{plan}"

    # Keep shared properties in sync with below
    vm_properties = {
        "supportsExtensions": True,
        "supportsBackup": False,
        "supportsAcceleratedNetworking": True,
        "networkVirtualAppliance": False,
        "supportsNVMe": True,
        "supportsCloudInit": False,
        "supportsAadLogin": False,
        "supportsHibernation": False,
        "supportsRemoteConnection": True,
        "requiresCustomArmTemplate": True,
    }
    if corevm:
        vm_properties = {
            "availableToFreeAccounts": True,
            "networkVirtualAppliance": False,
            "requiresCustomArmTemplate": True,
            "supportsAadLogin": False,
            "supportsBackup": False,
            "supportsCloudInit": False,
            "supportsClientHub": False,
            "supportsExtensions": True,
            "supportsHibernation": False,
            "supportsHubOnOffSwitch": False,
            "supportsNVMe": True,
            "supportsRemoteConnection": True,
            "supportsSriov": True,
        }

    payload = {
        "$schema": "https://schema.mp.microsoft.com/schema/configure/2022-03-01-preview2",
        "resources": [
            {
                "$schema": schema_url,
                "product": {"externalId": f"{offer}"},
                "plan": {"externalId": f"{plan}"},
                "operatingSystem": {"family": "linux", "type": "other"},
                "skus": [
                    {"imageType": f"{image_type_arch}Gen2", "skuId": sku_id},
                ],
                "vmImageVersions": image_versions,
                "vmProperties": vm_properties,
            }
        ],
    }

    if image_type_arch != "arm64":
        payload["resources"][0]["skus"].append(
            {"imageType": f"{image_type_arch}Gen1", "skuId": f"{plan}"}
        )

    if corevm:
        payload["resources"][0]["softwareType"] = "operatingSystem"

    resp = requests.post(
        url=f"https://graph.microsoft.com/rp/product-ingestion/configure",
        headers={
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        data=json.dumps(payload),
    )


def main():
    parser = argparse.ArgumentParser(
        prog="azure-marketlace-ingestion-api",
        description="Program to publish the Azure Marketplace Images",
    )
    parser.add_argument("-p", "--plan")
    parser.add_argument("-v", "--version")
    parser.add_argument("-s", "--az-sas-url")
    parser.add_argument("-t", "--test-mode", action="store_true")
    parser.add_argument("-z", "--test-plan")
    args = parser.parse_args()

    if not all((args.plan, args.version)):
        logging.error("Both version and plan is required")
        return

    plan = args.plan
    if not args.test_mode and plan not in ("alpha", "beta", "stable", "lts2022", "lts2023", "lts2024"):
        logging.error("plan value should be either alpha, beta, stable, lts2024, lts2023 or lts2022")
        return

    test_plan = None
    if args.test_mode:
        test_plan = args.test_plan

    version = args.version

    ## secrets, and other confidential variables
    tenant_id = os.environ.get("AZ_TENANT_ID")
    client_id = os.environ.get("AZ_CLIENT_ID")
    secret_value = os.environ.get("AZ_SECRET_VALUE")

    if not all((tenant_id, client_id, secret_value)):
        logging.error("Required: AZ_TENANT_ID, AZ_CLIENT_ID, AZ_SECRET_VALUE")
        return

    access_token = generate_partner_center_token(tenant_id, client_id, secret_value)

    if args.test_mode:
        OFFER_METADATA = CONFIG.get("test_offer_metadata")
        if not OFFER_METADATA:
            logging.error(
                "test_mode: Missing `test_offer_metadata` section in config"
            )
            return

        PLAN_METADATA = CONFIG.get("test_plan_metadata")
        if not PLAN_METADATA:
            logging.error(
                "test_mode: Missing `test_plan_metadata` section in config"
            )
            return
    else:
        OFFER_METADATA = CONFIG.get("offer_metadata")
        if not OFFER_METADATA:
            logging.error("Missing `offer_metadata` section in config")

        PLAN_METADATA = CONFIG.get("plan_metadata")
        if not PLAN_METADATA:
            logging.error("Missing `plan_metadata` section in config")

    for offer in PLAN_METADATA.get(plan, []):
        az_sas_url = None
        if args.az_sas_url is not None:
            az_sas_url = args.az_sas_url

        corevm = False
        if "corevm" in offer:
            corevm = True

        arch = OFFER_METADATA.get(offer)
        if arch is None:
            continue

        if az_sas_url is None:
            kwargs = {}
            if test_plan:
                kwargs = {"test_plan": test_plan}
            az_sas_url = generate_az_sas_url("lts" if plan.startswith("lts") else plan, version, arch, **kwargs)
            if az_sas_url is None:
                logging.error(
                    f"generate_az_sas_url returned None for {plan}, {version}, {arch}"
                )
                continue

        product_durable_id = get_product_durable_id(access_token, offer)
        plan_durable_id = get_plan_durable_id(access_token, product_durable_id, plan)

        product_durable_id = product_durable_id.split("/")[1]
        plan_durable_id = plan_durable_id.split("/")[2]

        image_versions = get_image_versions(
            access_token, product_durable_id, plan_durable_id, corevm=corevm
        )

        image_type_arch = "x64"
        if OFFER_METADATA[offer] == "arm64":
            image_type_arch = "arm64"

        draft_new_image_versions(
            access_token,
            plan,
            offer,
            version,
            az_sas_url,
            image_versions,
            image_type_arch,
            corevm=corevm,
        )
        print("Done preparing offers, you now have to click the publish button for each offer in https://partner.microsoft.com/en-us/dashboard/marketplace-offers/overview")


if __name__ == "__main__":
    main()
