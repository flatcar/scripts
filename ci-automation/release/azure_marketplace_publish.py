#!/usr/bin/python3
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "azure-storage-blob>=12.27.1",
# ]
# ///
import os
import sys
import copy
import json
import argparse
import requests
import logging

from azure.storage.blob import BlobClient, generate_container_sas, BlobSasPermissions
from datetime import datetime, timedelta
from urllib.parse import urlsplit, urlunsplit

logging.basicConfig(level=logging.DEBUG)

# Configuration data (previously in config.toml)
CONFIG = {
    "az_storage": {
        "account_name": "flatcar0001",
        "container_name": "publish",
        "blob_name_format": "flatcar-linux-{version}-{plan}-{arch}.vhd",
    },
    "offer_metadata": {
        "flatcar-container-linux-corevm": "arm64",
        "flatcar-container-linux-corevm-amd64": "amd64",
        "flatcar-container-linux-free": "amd64",
        "flatcar-container-linux": "amd64",
    },
    "plan_metadata": {
        "alpha": [
            "flatcar-container-linux-corevm",
            "flatcar-container-linux-corevm-amd64",
            "flatcar-container-linux-free",
            "flatcar-container-linux",
        ],
        "beta": [
            "flatcar-container-linux-corevm",
            "flatcar-container-linux-corevm-amd64",
            "flatcar-container-linux-free",
            "flatcar-container-linux",
        ],
        "stable": [
            "flatcar-container-linux-corevm",
            "flatcar-container-linux-corevm-amd64",
            "flatcar-container-linux-free",
            "flatcar-container-linux",
        ],
        "lts2024": [
            "flatcar-container-linux-free",
            "flatcar-container-linux",
            "flatcar-container-linux-corevm-amd64",
            "flatcar-container-linux-corevm",
        ],
    },
    "test_offer_metadata": {
        "test-release-automation-corevm": "amd64",
        "test-release-automation": "amd64",
    },
    "test_plan_metadata": {
        "release-test-automation": [
            "test-release-automation-corevm",
            "test-release-automation",
        ],
    },
}


def get_channel_info():
    resp = requests.get("https://flatcar.cdn.cncf.io/channel-info.txt")

    if resp.status_code != 200:
        logging.error(
            "There is some issue with the channel-info.txt file. Please check https://flatcar.cdn.cncf.io/channel-info.txt"
        )
        logging.error(f"Returned status code: {resp.status_code}")
        return {}

    entries = {}
    for line in resp.text.strip().split("\n"):
        key, _, value = line.partition("=")
        entries[key.strip()] = value.strip()

    return entries


def get_active_plans(channel_info):
    plans = [key.replace("_CURRENT", "").lower() for key in channel_info]
    plans = [plan for plan in plans if plan != "lts"]
    # channel-info.txt uses "lts_<year>" (e.g. "lts_2024"), but the plan
    # names registered on Azure Marketplace drop the underscore, e.g. "lts2024".
    plans = [plan.replace("lts_", "lts") for plan in plans]

    return plans


def resolve_lts_plan(channel_info, version):
    """
    This function primarily to search the LTS version for the corresponding plans
    """
    matches = []
    for key, value in channel_info.items():
        if (
            key == "LTS_CURRENT"
            or not key.startswith("LTS_")
            or not key.endswith("_CURRENT")
        ):
            continue
        year = key[len("LTS_") : -len("_CURRENT")]
        if year.isdigit() and value == version:
            matches.append(year)

    if len(matches) != 1:
        logging.error(
            f"Could not LTS year for version {version} in channel-info.txt, matches: {matches}"
        )
        return None

    return f"lts{matches[0]}"


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


def deprecate_oldest_image_version(image_versions, live_threshold=95):
    """Mark the oldest non-deprecated entry in `image_versions` (as returned
    by get_image_versions) as deprecated, in place, but only once the number
    of live (non-deprecated) versions exceeds `live_threshold` (Azure caps a
    SKU at 100 versions). Returns the deprecated entry, or None if nothing
    was deprecated."""
    active_versions = [
        v for v in image_versions if v.get("lifecycleState") != "deprecated"
    ]
    if len(active_versions) <= live_threshold:
        return None

    oldest = min(
        active_versions,
        key=lambda v: tuple(int(part) for part in v["versionNumber"].split(".")),
    )
    oldest["lifecycleState"] = "deprecated"
    return oldest


def image_version_exists(image_versions, version):
    return any(v.get("versionNumber") == version for v in image_versions)


def delete_draft_image_version(image_versions, version):
    """Mark the entry in `image_versions` matching `version` as deleted, in
    place. Only draft entries that were never published can be deleted this
    way (the API rejects deletion of anything already live). Returns the
    deleted entry, or None if no entry matched `version`."""
    match = next((v for v in image_versions if v.get("versionNumber") == version), None)
    if match is None:
        return None

    match["lifecycleState"] = "deleted"
    return match


def _redact_sas_uri(url):
    """Strip the SAS query string (the actual credential) from a blob URL, keeping the path for debugging."""
    parsed = urlsplit(url)
    if not parsed.query:
        return url
    return urlunsplit(
        (parsed.scheme, parsed.netloc, parsed.path, "REDACTED", parsed.fragment)
    )


def _redact_payload_uris(payload):
    payload = copy.deepcopy(payload)
    for resource in payload.get("resources", []):
        for image_version in resource.get("vmImageVersions", []):
            for vm_image in image_version.get("vmImages", []):
                os_disk = vm_image.get("source", {}).get("osDisk", {})
                if "uri" in os_disk:
                    os_disk["uri"] = _redact_sas_uri(os_disk["uri"])
    return payload


def submit_image_versions(
    access_token,
    plan,
    offer,
    image_versions,
    image_type_arch,
    corevm=False,
    dry_run=False,
):
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

    if dry_run:
        print(f"[dry-run] Would POST configure for {offer}/{plan}:")
        print(json.dumps(_redact_payload_uris(payload), indent=2))
        return True

    resp = requests.post(
        url=f"https://graph.microsoft.com/rp/product-ingestion/configure",
        headers={
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        data=json.dumps(payload),
    )

    if resp.status_code != 202:
        logging.error(
            f"submit_image_versions failed for {offer}/{plan}: "
            f"status={resp.status_code} body={resp.text}"
        )
        return False

    return True


def draft_new_image_versions(
    access_token,
    plan,
    offer,
    version,
    az_sas_url,
    image_versions,
    image_type_arch,
    corevm=False,
    dry_run=False,
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

    return submit_image_versions(
        access_token,
        plan,
        offer,
        image_versions,
        image_type_arch,
        corevm=corevm,
        dry_run=dry_run,
    )


def main():
    parser = argparse.ArgumentParser(
        prog="azure-marketlace-ingestion-api",
        description="Program to publish the Azure Marketplace Images",
    )
    parser.add_argument(
        "-p",
        "--plan",
        help="Channel/plan to publish, e.g. alpha, beta, stable, lts, lts2024",
    )
    parser.add_argument(
        "-v",
        "--version",
        help="Flatcar version to publish, e.g. 4081.3.10. Required unless --deprecate-only is set",
    )
    parser.add_argument(
        "-s",
        "--az-sas-url",
        help="SAS URL of the VHD blob to publish; generated automatically when omitted",
    )
    parser.add_argument(
        "-t",
        "--test-mode",
        action="store_true",
        help="Publish to the test offer/plan instead of the real ones",
    )
    parser.add_argument(
        "-z",
        "--test-plan",
        help="Plan name to use for the blob lookup in test mode",
    )
    parser.add_argument(
        "-d",
        "--deprecate-only",
        action="store_true",
        help="Deprecate the oldest image version for the plan's offers and exit, without publishing a new version",
    )
    parser.add_argument(
        "-x",
        "--delete-draft-version",
        action="store_true",
        help="Delete the draft (not-yet-published) image version given by --version, across the plan's offers, and exit",
    )
    parser.add_argument(
        "-n",
        "--dry-run",
        action="store_true",
        help="Perform all read-only lookups but skip the actual submit/publish API calls, printing what would be sent instead",
    )
    args = parser.parse_args()

    if not args.plan or (
        not args.deprecate_only and not args.delete_draft_version and not args.version
    ):
        logging.error(
            "plan is required, and version is required unless --deprecate-only or --delete-draft-version is set"
        )
        return

    if args.delete_draft_version and not args.version:
        logging.error("--version is required when --delete-draft-version is set")
        return

    channel_info = get_channel_info()
    active_plans = get_active_plans(channel_info)
    plan = args.plan
    if not args.test_mode and plan == "lts":
        lts_version = args.version or channel_info.get("LTS_CURRENT")
        if not lts_version:
            logging.error(
                "--plan lts requires --version, or channel-info.txt must contain LTS_CURRENT"
            )
            return
        plan = resolve_lts_plan(channel_info, lts_version)
        if plan is None:
            return

    if not args.test_mode and plan not in active_plans:
        logging.error(f"plan value should be either {', '.join(active_plans)}")
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
            logging.error("test_mode: Missing `test_offer_metadata` section in config")
            return

        PLAN_METADATA = CONFIG.get("test_plan_metadata")
        if not PLAN_METADATA:
            logging.error("test_mode: Missing `test_plan_metadata` section in config")
            return
    else:
        OFFER_METADATA = CONFIG.get("offer_metadata")
        if not OFFER_METADATA:
            logging.error("Missing `offer_metadata` section in config")

        PLAN_METADATA = CONFIG.get("plan_metadata")
        if not PLAN_METADATA:
            logging.error("Missing `plan_metadata` section in config")

    failed_offers = []
    for offer in PLAN_METADATA.get(plan, []):
        corevm = False
        if "corevm" in offer:
            corevm = True

        arch = OFFER_METADATA.get(offer)
        if arch is None:
            continue

        az_sas_url = None
        if not args.deprecate_only and not args.delete_draft_version:
            az_sas_url = args.az_sas_url
            if az_sas_url is None:
                kwargs = {}
                if test_plan:
                    kwargs = {"test_plan": test_plan}
                az_sas_url = generate_az_sas_url(
                    "lts" if plan.startswith("lts") else plan, version, arch, **kwargs
                )
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

        if args.delete_draft_version:
            deleted = delete_draft_image_version(image_versions, version)
            if deleted is None:
                print(f"No draft version {version} found for {offer}")
                continue
            success = submit_image_versions(
                access_token,
                plan,
                offer,
                image_versions,
                image_type_arch,
                corevm=corevm,
                dry_run=args.dry_run,
            )
            if not success:
                failed_offers.append(offer)
                continue
            verb = "Would delete" if args.dry_run else "Deleted"
            print(f"{verb} draft image version {version} for {offer}")
            continue

        if not args.deprecate_only and image_version_exists(image_versions, version):
            print(f"Version {version} already exists for {offer}, skipping")
            continue

        deprecated = deprecate_oldest_image_version(image_versions)
        if deprecated is not None:
            verb = "Would deprecate" if args.dry_run else "Deprecating"
            print(
                f"{verb} oldest image version {deprecated['versionNumber']} for {offer}"
            )

        if args.deprecate_only:
            if deprecated is None:
                print(f"Nothing to deprecate for {offer}")
                continue
            success = submit_image_versions(
                access_token,
                plan,
                offer,
                image_versions,
                image_type_arch,
                corevm=corevm,
                dry_run=args.dry_run,
            )
            if not success:
                failed_offers.append(offer)
            continue

        success = draft_new_image_versions(
            access_token,
            plan,
            offer,
            version,
            az_sas_url,
            image_versions,
            image_type_arch,
            corevm=corevm,
            dry_run=args.dry_run,
        )
        if not success:
            failed_offers.append(offer)
            continue
        if not args.dry_run:
            print(
                f"Done preparing {offer}, you now have to click the publish button for it in https://partner.microsoft.com/en-us/dashboard/marketplace-offers/overview"
            )

    if failed_offers:
        logging.error(f"Submission failed for offers: {', '.join(failed_offers)}")
        sys.exit(1)


if __name__ == "__main__":
    main()
