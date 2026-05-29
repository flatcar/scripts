#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Azure validation module for Azure Container Linux (ACL) images.
#
# Provides Azure-specific VM lifecycle functions:
#   - Azure infrastructure provisioning (storage, gallery, image definitions)
#   - VHD upload and gallery image version management
#   - Azure VM creation, start, and removal
#   - Azure serial console and run-command execution
#   - Azure CLI prerequisite checks
#
# Sourced by validate_rpm_image.sh (requires validate_common.sh loaded first).
#

# Guard against double-sourcing
[[ -n "${_VALIDATE_AZURE_LOADED:-}" ]] && return 0
_VALIDATE_AZURE_LOADED=1

# ── Azure-specific globals ─────────────────────────────────────────

AZ_SUB_ID="${AZ_SUB_ID:?Must be set — Azure subscription ID}"
AZ_REGION="${AZ_REGION:-eastus2}"
AZ_STORAGE_RG="${AZ_STORAGE_RG:?Must be set — resource group for storage account}"
AZ_STORAGE_ACC="${AZ_STORAGE_ACC:?Must be set — storage account name}"
AZ_STORAGE_CONTAINER="${AZ_STORAGE_CONTAINER:?Must be set — blob container for VHDs}"
AZ_GALLERY_RG="${AZ_GALLERY_RG:?Must be set — resource group for Azure Compute Gallery}"
AZ_ACG="${AZ_ACG:?Must be set — Azure Compute Gallery name}"
NO_CLEANUP="${NO_CLEANUP:-false}"
BUILD_ID="${BUILD_ID:-}"
RESOURCE_TAGS=("createdBy=$(whoami)")
VM_RG_PREFIX="${VM_RG_PREFIX:-$(whoami)-acl-test-vm-rg}"
VM_RG=""
AZ_VM_ARGS="${AZ_VM_ARGS:-}"

# Backup VM SKUs to try when the primary SKU has capacity restrictions.
# Ordered by preference:
#   AMD64 — v5 D-family (SCSI) first, then cross-family (F/B), then v6 (NVMe,
#           may fail with disk-controller incompatibility on current images).
#   ARM64 — v6 Cobalt 100 SKUs first (only v6 ARM supports TrustedLaunch),
#           then cross-family v6, then v5 last-resort (no TrustedLaunch).
AZ_BACKUP_VM_SIZES_AMD64="${AZ_BACKUP_VM_SIZES_AMD64:-Standard_D2as_v5 Standard_D2ds_v5 Standard_D2ads_v5 Standard_F2s_v2 Standard_B2s_v2 Standard_B2as_v2 Standard_D2s_v6 Standard_D2as_v6 Standard_D2ds_v6}"
AZ_BACKUP_VM_SIZES_ARM64="${AZ_BACKUP_VM_SIZES_ARM64:-Standard_D2pds_v6 Standard_D2pls_v6 Standard_D2plds_v6 Standard_E2ps_v6 Standard_D2ps_v5 Standard_D2pds_v5 Standard_D2pls_v5}"

# Backup regions for VM provisioning when the primary region is exhausted.
# Only regions where the gallery image has been replicated will be tried.
AZ_BACKUP_REGIONS="${AZ_BACKUP_REGIONS:-}"

# Resolve Azure VM size and image definition based on BOARD.
# Must be called after argument parsing so that --board is applied.
resolve_azure_defaults() {
    case "${BOARD:-amd64-usr}" in
        arm64-usr)
            AZ_VM_SIZE="${AZ_VM_SIZE:-Standard_D2ps_v6}"
            AZ_VM_IMAGE_DEF="${AZ_VM_IMAGE_DEF:-$(whoami)-acl-test-vm-img-arm64}"
            ;;
        *)
            AZ_VM_SIZE="${AZ_VM_SIZE:-Standard_D2s_v5}"
            AZ_VM_IMAGE_DEF="${AZ_VM_IMAGE_DEF:-$(whoami)-acl-test-vm-img}"
            ;;
    esac
}

# ── SKU / region fallback ──────────────────────────────────────────

# Get the list of regions an ACG image version has been replicated to.
# Accepts either a full ARM resource ID or a short version string.
# Prints normalized region names (lowercase, no spaces), one per line.
# Results are cached to avoid redundant API calls.
_CACHED_IMAGE_REGIONS=""
get_image_replicated_regions() {
    local image_version_or_id="$1"

    if [[ -n "${_CACHED_IMAGE_REGIONS}" ]]; then
        echo "${_CACHED_IMAGE_REGIONS}"
        return 0
    fi

    local raw_regions
    if [[ "$image_version_or_id" == /subscriptions/* ]]; then
        raw_regions=$(az rest --method GET \
            --url "${image_version_or_id}?api-version=2023-07-03" \
            --query "properties.publishingProfile.targetRegions[].name" \
            -o tsv 2>/dev/null) || return 1
    else
        raw_regions=$(az sig image-version show \
            --resource-group "$AZ_GALLERY_RG" \
            --gallery-name "$AZ_ACG" \
            --gallery-image-definition "$AZ_VM_IMAGE_DEF" \
            --gallery-image-version "$image_version_or_id" \
            --query "publishingProfile.targetRegions[].name" \
            -o tsv 2>/dev/null) || return 1
    fi

    # Normalize: lowercase, remove spaces (e.g. "West US 2" → "westus2")
    local normalized=""
    local region
    while IFS= read -r region; do
        [[ -z "$region" ]] && continue
        local norm="${region,,}"
        norm="${norm// /}"
        normalized+="${norm}"$'\n'
    done <<< "$raw_regions"

    _CACHED_IMAGE_REGIONS="$normalized"
    echo "$normalized"
}

# Check whether an ACG image version has been replicated to a given region.
# Returns 0 if the image is available in the region, 1 otherwise.
check_image_replicated_to_region() {
    local image_version_or_id="$1"
    local target_region="$2"

    local regions
    regions=$(get_image_replicated_regions "$image_version_or_id") || return 1

    local target_lower="${target_region,,}"
    echo "$regions" | grep -qxF "$target_lower"
}

# ── Azure console ─────────────────────────────────────────────────

connect_vm_console_azure() {
    local vm_rg_name="$1"
    local vm_name="$2"
    info "Connecting to Azure VM serial console..."
    info "Press Ctrl+] followed by 'q' to disconnect from console"
    sleep 1
    az serial-console connect \
        --resource-group "$vm_rg_name" \
        --name "$vm_name"
}

# ── Azure run-command execution ────────────────────────────────────

run_command_vm_azure() {
    local vm_rg_name="$1"
    local vm_name="$2"
    local command="$3"
    local timeout="${4:-60}"

    info "Running command on Azure VM: $command"

    local escaped_command
    escaped_command=$(printf '%s' "$command" | sed 's/\\/\\\\/g; s/"/\\"/g')

    local script_content="#!/bin/bash\nset -e\n$command\necho \"SCRIPT_EXIT_CODE:\$?\""

    local result=0
    local output
    if output=$(az vm run-command invoke \
        --resource-group "$vm_rg_name" \
        --name "$vm_name" \
        --command-id RunShellScript \
        --scripts "$script_content" \
        --query 'value[0].message' \
        --output tsv 2>&1); then
        echo "$output"
        if echo "$output" | grep -q "SCRIPT_EXIT_CODE:0"; then
            info "✓ Command completed successfully"
        else
            error "Command failed or returned non-zero exit code"
            result=1
        fi
    else
        error "Failed to execute command on Azure VM: $output"
        result=1
    fi

    return $result
}

# ── Azure infrastructure ──────────────────────────────────────────

check_azure_infra() {
    info "Checking that required Azure infrastructure exists..."

    if [[ "$(az group exists -n "$AZ_STORAGE_RG")" == "false" ]]; then
        info "Creating storage resource group: $AZ_STORAGE_RG"
        az group create --name "$AZ_STORAGE_RG" --location "$AZ_REGION"
    fi

    if [[ "$(az group exists -n "$AZ_GALLERY_RG")" == "false" ]]; then
        info "Creating gallery resource group: $AZ_GALLERY_RG"
        az group create --name "$AZ_GALLERY_RG" --location "$AZ_REGION"
    fi

    local storage_account_resource_id="/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$AZ_STORAGE_RG/providers/Microsoft.Storage/storageAccounts/$AZ_STORAGE_ACC"
    if ! az storage account show --ids "$storage_account_resource_id" &>/dev/null; then
        info "Creating storage account: $AZ_STORAGE_ACC"
        if [[ "$(az storage account check-name --name "$AZ_STORAGE_ACC" --query nameAvailable)" == "false" ]]; then
            error "Storage account name $AZ_STORAGE_ACC is not available"
            exit 1
        fi
        az storage account create \
            --resource-group "$AZ_STORAGE_RG" \
            --name "$AZ_STORAGE_ACC" \
            --location "$AZ_REGION" \
            --allow-shared-key-access false \
            --sku Standard_LRS
    fi

    local container_exists
    container_exists=$(az storage container exists --account-name "$AZ_STORAGE_ACC" --name "$AZ_STORAGE_CONTAINER" --auth-mode login --query exists -o tsv)
    if [[ "$container_exists" != "true" ]]; then
        info "Creating storage container: $AZ_STORAGE_CONTAINER"
        az storage container create \
            --account-name "$AZ_STORAGE_ACC" \
            --name "$AZ_STORAGE_CONTAINER" \
            --auth-mode login
    fi

    if ! az sig show -r "$AZ_ACG" -g "$AZ_GALLERY_RG" &>/dev/null; then
        info "Creating shared image gallery: $AZ_ACG"
        az sig create \
            --resource-group "$AZ_GALLERY_RG" \
            --gallery-name "$AZ_ACG" \
            --location "$AZ_REGION"
    fi

    local image_def_exists
    local publisher="$(whoami)-ACL"
    local offer="$AZ_VM_IMAGE_DEF"
    local sku="$(whoami)-TestBase"

    image_def_exists=$(az sig image-definition list -r "$AZ_ACG" -g "$AZ_GALLERY_RG" --query "[?name=='$AZ_VM_IMAGE_DEF' && identifier.publisher=='$publisher' && identifier.offer=='$offer' && identifier.sku=='$sku'] | length(@)" -o tsv)
    if [[ "$image_def_exists" -eq 0 ]]; then
        info "Creating image definition: $AZ_VM_IMAGE_DEF"
        local create_sig_image_def_args=(
            --gallery-image-definition "$AZ_VM_IMAGE_DEF"
            --publisher "$publisher"
            --offer "$offer"
            --sku "$sku"
            --gallery-name "$AZ_ACG"
            --resource-group "$AZ_GALLERY_RG"
            --location "$AZ_REGION"
            --os-type Linux
            --features SecurityType=TrustedLaunchSupported
            --hyper-v-generation V2
        )

        if [[ $BOARD == "arm64-usr" ]]; then
            create_sig_image_def_args+=(--architecture Arm64)
        fi

        az sig image-definition create "${create_sig_image_def_args[@]}"

    else
        info "Image definition already exists: $AZ_VM_IMAGE_DEF"
    fi

    info "Azure infrastructure ready"
}

upload_vhd_to_storage() {
    local vhd_path="$1"
    local blob_name="$2"
    info "Uploading VHD to Azure storage..."
    info "  Local file:  $vhd_path"
    info "  Blob name:   $blob_name"
    info "  Storage account: $AZ_STORAGE_ACC"
    info "  Container:       $AZ_STORAGE_CONTAINER"
    az storage blob upload \
        --account-name "$AZ_STORAGE_ACC" \
        --container-name "$AZ_STORAGE_CONTAINER" \
        --name "$blob_name" \
        --file "$vhd_path" \
        --auth-mode login \
        --overwrite
    info "✓ VHD uploaded successfully"
}

get_next_image_version() {
    if [[ -n "${BUILD_ID}" ]]; then
        echo "1.0.${BUILD_ID}"
        return
    fi
    local latest_version
    latest_version=$(az sig image-version list \
        --resource-group "$AZ_GALLERY_RG" \
        --gallery-name "$AZ_ACG" \
        --gallery-image-name "$AZ_VM_IMAGE_DEF" \
        --query '[].name' -o tsv | \
        sort -t "." -k1,1n -k2,2n -k3,3n | \
        tail -1)
    if [[ -z "$latest_version" ]]; then
        echo "1.0.0"
    else
        echo "$latest_version" | awk -F. '{print $1"."$2"."$3+1}'
    fi
}

# Return the latest Succeeded gallery image version, or empty string if none.
get_latest_image_version() {
    az sig image-version list \
        --resource-group "$AZ_GALLERY_RG" \
        --gallery-name "$AZ_ACG" \
        --gallery-image-definition "$AZ_VM_IMAGE_DEF" \
        --query "[?provisioningState=='Succeeded'].name" -o tsv 2>/dev/null | \
        sort -t "." -k1,1n -k2,2n -k3,3n | \
        tail -1
}

# Check whether a gallery image version already exists and is in a usable
# provisioning state (Succeeded).  Returns 0 if the version can be reused.
gallery_image_version_exists() {
    local image_version="$1"
    local state
    state=$(az sig image-version show \
        --resource-group "$AZ_GALLERY_RG" \
        --gallery-name "$AZ_ACG" \
        --gallery-image-definition "$AZ_VM_IMAGE_DEF" \
        --gallery-image-version "$image_version" \
        --query 'provisioningState' -o tsv 2>/dev/null) || return 1
    [[ "${state}" == "Succeeded" ]]
}

create_gallery_image_version() {
    local image_version="$1"
    local blob_name="$2"
    info "Creating gallery image version: $image_version"
    local storage_account_resource_id="/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$AZ_STORAGE_RG/providers/Microsoft.Storage/storageAccounts/$AZ_STORAGE_ACC"
    local blob_url="https://$AZ_STORAGE_ACC.blob.core.windows.net/$AZ_STORAGE_CONTAINER/$blob_name"

    # The --location for az sig image-version create must match the region of
    # the source VHD blob (storage account), so the intermediate managed disk
    # is co-located.  When the storage account or gallery are in a different
    # region from AZ_REGION (the VM target), we add extra target regions and
    # switch to Full replication.
    local storage_location
    storage_location=$(az storage account show -n "$AZ_STORAGE_ACC" --query location -o tsv)
    local gallery_location
    gallery_location=$(az sig show -r "$AZ_ACG" -g "$AZ_GALLERY_RG" --query location -o tsv)

    if [[ "${storage_location,,}" != "${gallery_location,,}" ]]; then
        error "Storage account '$AZ_STORAGE_ACC' is in '${storage_location}' but gallery '$AZ_ACG' is in '${gallery_location}'. They must be in the same region."
        exit 1
    fi

    # Build unique set of target regions (gallery home + VM target).
    local image_location="$storage_location"
    local replication_mode="Shallow"
    local target_regions="$image_location"
    if [[ "${image_location,,}" != "${AZ_REGION,,}" ]]; then
        warn "Storage/gallery region '${image_location}' differs from VM target region '${AZ_REGION}'; adding '${AZ_REGION}' as extra target (Full replication, slower)"
        target_regions="$image_location $AZ_REGION"
        replication_mode="Full"
    fi

    # Check for ephemeral UKI signing cert next to the VHD. When present, we
    # must use the REST API to enroll it in the image's Secure Boot db (az CLI
    # does not expose securityProfile on image-version create).
    local signing_cert="${_VM_IMAGE_DIR}/uki-signing-ca.pem"
    if [[ -f "${signing_cert}" ]]; then
        info "Found UKI signing cert: ${signing_cert} — using REST API with Secure Boot profile"
        local cert_b64
        cert_b64=$(grep -v '^-----' "${signing_cert}" | tr -d '\n\r')
        local version_resource_id="/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${AZ_GALLERY_RG}/providers/Microsoft.Compute/galleries/${AZ_ACG}/images/${AZ_VM_IMAGE_DEF}/versions/${image_version}"

        # Build targetRegions JSON array from computed target_regions.
        local target_regions_json=""
        for region in $target_regions; do
            [[ -n "$target_regions_json" ]] && target_regions_json+=","
            target_regions_json+="{\"name\": \"${region}\", \"regionalReplicaCount\": 1, \"storageAccountType\": \"Standard_LRS\"}"
        done

        az rest --method PUT \
            --url "${version_resource_id}?api-version=2023-07-03" \
            --body "{
              \"location\": \"${image_location}\",
              \"properties\": {
                \"storageProfile\": {
                  \"osDiskImage\": {
                    \"source\": {
                      \"uri\": \"${blob_url}\",
                      \"storageAccountId\": \"${storage_account_resource_id}\"
                    }
                  }
                },
                \"publishingProfile\": {
                  \"targetRegions\": [${target_regions_json}],
                  \"replicationMode\": \"${replication_mode}\"
                },
                \"securityProfile\": {
                  \"uefiSettings\": {
                    \"signatureTemplateNames\": [\"MicrosoftUefiCertificateAuthorityTemplate\"],
                    \"additionalSignatures\": {
                      \"db\": [{\"type\": \"x509\", \"value\": [\"${cert_b64}\"]}]
                    }
                  }
                }
              }
            }"

        # az rest doesn't handle long-running operations — poll until provisioned.
        info "Waiting for image version provisioning to complete..."
        local state
        for attempt in $(seq 1 60); do
            state=$(az rest --method GET \
                --url "${version_resource_id}?api-version=2023-07-03" \
                --query "properties.provisioningState" -o tsv 2>/dev/null || echo "Unknown")
            if [[ "${state}" == "Succeeded" ]]; then
                info "✓ Image version provisioning succeeded (attempt ${attempt})"
                break
            elif [[ "${state}" == "Failed" ]]; then
                error "Image version provisioning failed"
                az rest --method GET --url "${version_resource_id}?api-version=2023-07-03" || true
                exit 1
            fi
            info "  Provisioning state: ${state} (attempt ${attempt}/60, waiting 30s...)"
            sleep 30
        done
        if [[ "${state}" != "Succeeded" ]]; then
            error "Image version provisioning timed out after 30 minutes"
            exit 1
        fi
    else
        az sig image-version create \
            --resource-group "$AZ_GALLERY_RG" \
            --gallery-name "$AZ_ACG" \
            --gallery-image-definition "$AZ_VM_IMAGE_DEF" \
            --gallery-image-version "$image_version" \
            --os-vhd-uri "$blob_url" \
            --os-vhd-storage-account "$storage_account_resource_id" \
            --location "$image_location" \
            --target-regions $target_regions \
            --replica-count 1 \
            --storage-account-type Standard_LRS \
            --replication-mode "$replication_mode"
    fi
    info "✓ Gallery image version created: $image_version"
}

# ── Azure VM creation ─────────────────────────────────────────────

# Attempt a single az vm create.  Returns 0 on success or 1 on failure.
# On SkuNotAvailable, prints "SKU_NOT_AVAILABLE" to stdout so the caller
# can distinguish capacity errors from other failures.
_try_vm_create() {
    local vm_rg_name="$1"
    local vm_name="$2"
    local image_id="$3"
    local vm_size="$4"
    local region="$5"
    shift 5
    local -a extra_tags=("$@")

    local vm_create_args=(
        --resource-group "$vm_rg_name"
        --name "$vm_name"
        --size "$vm_size"
        --os-disk-size-gb 60
        --admin-username "$VM_SSH_USER"
        --ssh-key-values "@${VM_SSH_KEY}.pub"
        --security-type TrustedLaunch
        --enable-vtpm true
        --image "$image_id"
        --location "$region"
        --public-ip-address ""
        --tags "${extra_tags[@]}"
    )

    if [[ "$SECURE_BOOT_ENABLED" == "true" ]]; then
        vm_create_args+=(--enable-secure-boot true)
    else
        vm_create_args+=(--enable-secure-boot false)
    fi

    if [[ -n "$AZ_VM_ARGS" ]]; then
        vm_create_args+=($AZ_VM_ARGS)
    fi

    local output
    if output=$(az vm create "${vm_create_args[@]}" 2>&1); then
        echo "$output"
        return 0
    else
        local rc=$?
        # Detect errors that mean "this SKU won't work here" so the caller
        # can move on to the next candidate instead of aborting.
        #   - SkuNotAvailable        → capacity restriction in this region
        #   - InvalidParameter/vmSize → disk-controller incompatibility
        #   - TrustedLaunch           → SKU does not support TrustedLaunch security type
        if echo "$output" | grep -qiE \
            "SkuNotAvailable|\"target\":\\s*\"vmSize\"|TrustedLaunch"; then
            # Log the error details to stderr so they appear in pipeline logs
            echo "$output" | grep -iE \
                'SkuNotAvailable|Capacity|InvalidParameter|vmSize|TrustedLaunch|BadRequest' >&2 || true
            echo "SKU_NOT_AVAILABLE"
            return 1
        fi
        # Non-SKU error — print the full output so the caller sees it, then fail
        echo "$output" >&2
        return 2
    fi
}

create_vm_azure() {
    local vm_rg_name="$1"
    local image_version_or_id="$2"

    local image_id
    if [[ -n "${ACG_IMAGE_VERSION_ID}" ]]; then
        image_id="${image_version_or_id}"
    else
        image_id="/subscriptions/$AZ_SUB_ID/resourceGroups/$AZ_GALLERY_RG/providers/Microsoft.Compute/galleries/$AZ_ACG/images/$AZ_VM_IMAGE_DEF/versions/$image_version_or_id"
    fi

    # Build ordered list of SKUs to try: primary first, then backups
    local backup_skus
    case "${BOARD:-amd64-usr}" in
        arm64-usr) backup_skus="${AZ_BACKUP_VM_SIZES_ARM64}" ;;
        *)         backup_skus="${AZ_BACKUP_VM_SIZES_AMD64}" ;;
    esac
    local all_skus=("${AZ_VM_SIZE}" ${backup_skus})

    # Deduplicate (primary may appear in backup list)
    local -A seen_skus=()
    local unique_skus=()
    for s in "${all_skus[@]}"; do
        if [[ -z "${seen_skus[$s]:-}" ]]; then
            seen_skus[$s]=1
            unique_skus+=("$s")
        fi
    done

    # Build ordered list of regions to try: primary first, then backups
    local all_regions=("${AZ_REGION}")
    if [[ -n "${AZ_BACKUP_REGIONS}" ]]; then
        read -ra _backup_regions <<< "${AZ_BACKUP_REGIONS}"
        all_regions+=("${_backup_regions[@]}")
    fi

    local all_tags=("${RESOURCE_TAGS[@]}" "purpose=VM-testing" "creationTime=$(date +%s)")
    local original_sku="${AZ_VM_SIZE}"
    local original_region="${AZ_REGION}"
    local current_rg_region=""
    local tried_combos=()

    info "VM SKU fallback candidates:"
    info "  SKUs:    ${unique_skus[*]}"
    info "  Regions: ${all_regions[*]}"

    for region in "${all_regions[@]}"; do
        # For non-primary regions, verify the gallery image is replicated there
        if [[ "$region" != "${original_region}" ]]; then
            info "Checking image replication to ${region}..."
            if ! check_image_replicated_to_region "$image_id" "$region"; then
                warn "Image not replicated to ${region} — skipping region"
                continue
            fi
            info "✓ Image available in ${region}"
        fi

        # Create or recreate resource group if we're in a new region
        if [[ "$region" != "$current_rg_region" ]]; then
            if [[ -n "$current_rg_region" ]]; then
                # Changing region — delete the old RG (async) and create new one
                info "Switching from ${current_rg_region} to ${region} — recreating resource group"
                az group delete -n "$vm_rg_name" -y --no-wait 2>/dev/null || true
                vm_rg_name=$(get_vm_rg_name)
                VM_RG="$vm_rg_name"
            fi
            info "Creating VM RG: $vm_rg_name (location: $region)"
            az group create \
                --name "$vm_rg_name" \
                --location "$region" \
                --tags "${all_tags[@]}"

            local public_ip_name="${VM_NAME}PublicIP"
            info "Creating public IP with policy-compliant tags: $public_ip_name"
            az network public-ip create \
                --name "$public_ip_name" \
                --resource-group "$vm_rg_name" \
                --location "$region" \
                --allocation-method Static \
                --sku Standard \
                --ip-tags FirstPartyUsage=/NonProd \
                --tags "${all_tags[@]}"

            current_rg_region="$region"
        fi

        for sku in "${unique_skus[@]}"; do
            tried_combos+=("${sku}@${region}")
            info "Attempting VM creation: SKU=${sku} Region=${region}..."

            # The || captures the exit code without triggering set -e (errexit).
            # Without this, a non-zero return from _try_vm_create would kill the
            # shell before the retry logic ever runs.
            local result rc
            result=$(_try_vm_create "$vm_rg_name" "$VM_NAME" "$image_id" "$sku" "$region" "${all_tags[@]}") && rc=0 || rc=$?

            if [[ $rc -eq 0 ]]; then
                echo "$result"  # Print the az vm create JSON output
                if [[ "$sku" != "$original_sku" || "$region" != "$original_region" ]]; then
                    warn "VM created using fallback: SKU=${sku} Region=${region} (primary was SKU=${original_sku} Region=${original_region})"
                fi
                AZ_VM_SIZE="$sku"
                AZ_REGION="$region"

                info "Attaching public IP to VM NIC..."
                local nic_id
                nic_id=$(az vm show -g "$vm_rg_name" -n "$VM_NAME" \
                    --query 'networkProfile.networkInterfaces[0].id' -o tsv)
                local nic_name
                nic_name=$(az network nic show --ids "$nic_id" --query 'name' -o tsv)
                local ip_config_name
                ip_config_name=$(az network nic show --ids "$nic_id" \
                    --query 'ipConfigurations[0].name' -o tsv)
                az network nic ip-config update \
                    --nic-name "$nic_name" \
                    --resource-group "$vm_rg_name" \
                    --name "$ip_config_name" \
                    --public-ip-address "$public_ip_name"

                info "Enabling boot diagnostics..."
                az vm boot-diagnostics enable \
                    --name "$VM_NAME" \
                    --resource-group "$vm_rg_name"
                return 0
            elif [[ $rc -eq 1 && "$result" == "SKU_NOT_AVAILABLE" ]]; then
                warn "✗ SKU incompatible or unavailable: ${sku} in ${region} — trying next candidate"
                # Delete the failed VM resource (deployment may have left artifacts)
                az vm delete -g "$vm_rg_name" -n "$VM_NAME" -y --no-wait 2>/dev/null || true
                continue
            else
                # Non-SKU failure — fatal
                error "VM creation failed with a non-recoverable error (exit code: ${rc})"
                return 1
            fi
        done
    done

    error "No available VM SKU found across all candidate regions"
    error "  Tried: ${tried_combos[*]}"
    return 1
}

get_vm_rg_name() {
    local suffix
    suffix=$(tr -dc 'a-z0-9' </dev/urandom | head -c 8)
    printf '%s-%s\n' "$VM_RG_PREFIX" "$suffix"
}

# ── Start Azure VM ────────────────────────────────────────────────

start_vm_azure() {
    local vm_image_path="$1"
    section "Starting Azure VM for board '${BOARD}'"

    local vm_rg_name=$(get_vm_rg_name)
    VM_RG="$vm_rg_name"

    info "Azure VM Configuration:"
    info "  Subscription:      ${AZ_SUB_ID}"
    info "  Storage RG:        ${AZ_STORAGE_RG}"
    info "  Location:          ${AZ_REGION}"
    info "  VM Resource Group: ${vm_rg_name}"
    info "  VM Name:           ${VM_NAME}"
    info "  Gallery:           ${AZ_ACG}"
    info "  Image Definition:  ${AZ_VM_IMAGE_DEF}"
    info "  Board:             ${BOARD}"
    info "  VM Size:           ${AZ_VM_SIZE}"
    echo

    info "Setting Azure subscription..."
    az account set --subscription "$AZ_SUB_ID"

    if [[ -n "${ACG_IMAGE_VERSION_ID}" ]]; then
        info "Using pre-existing ACG image version: ${ACG_IMAGE_VERSION_ID}"
        create_vm_azure "$vm_rg_name" "${ACG_IMAGE_VERSION_ID}"
    elif [[ "${REUSE_IMAGE}" == "true" ]]; then
        check_azure_infra
        local image_version
        image_version=$(get_latest_image_version)
        if [[ -z "$image_version" ]]; then
            die "--reuse-image: no existing gallery image version found in ${AZ_ACG}/${AZ_VM_IMAGE_DEF}"
        fi
        info "Reusing latest gallery image version: ${image_version} — skipping VHD upload"
        create_vm_azure "$vm_rg_name" "$image_version"
    else
        check_azure_infra
        _VM_IMAGE_DIR="$(cd "$(dirname "${vm_image_path}")" && pwd)"
        local image_version
        image_version=$(get_next_image_version)

        # When BUILD_ID is set the version is deterministic (1.0.<BUILD_ID>),
        # so the same image may already have been published by a prior run.
        if [[ -n "${BUILD_ID}" ]] && gallery_image_version_exists "$image_version"; then
            info "Gallery image version ${image_version} already exists and is ready — skipping VHD upload"
        else
            local blob_name="$(date +%y%m%d.%H%M%S)-${BUILD_ID:+${BUILD_ID}-}${IMG_NAME}.vhd"
            upload_vhd_to_storage "$vm_image_path" "$blob_name"
            create_gallery_image_version "$image_version" "$blob_name"
        fi
        create_vm_azure "$vm_rg_name" "$image_version"
    fi

    # create_vm_azure may have changed VM_RG if it switched regions
    vm_rg_name="$VM_RG"

    export VM_IP=$(az vm show -d -g "$vm_rg_name" -n "$VM_NAME" --query "publicIps" -o tsv)
    while [ "$(az vm show -d -g "$vm_rg_name" -n "$VM_NAME" --query provisioningState -o tsv)" != "Succeeded" ]; do sleep 1; done

    info "✓ Azure VM '${VM_NAME}' started successfully!"
    info " IP Address:     ${VM_IP}"
}

# ── Remove Azure VM ───────────────────────────────────────────────

remove_vm_azure() {
    if [[ "$NO_CLEANUP" == "true" ]]; then
        info "--no-cleanup specified, so skipping cleanup of VM resources"
        return 0
    fi
    remove_vm_state
    info "Scheduling deletion of VM resources matching tags: ${RESOURCE_TAGS[*]}"
    local query_filter=""
    for tag in "${RESOURCE_TAGS[@]}"; do
        local key="${tag%%=*}"
        local value="${tag#*=}"
        [[ -n "$query_filter" ]] && query_filter+=" && "
        query_filter+="tags.${key}=='${value}'"
    done
    local matching_rgs
    matching_rgs=$(az group list --query "[?${query_filter}].name" -o tsv)

    if [[ -z "$matching_rgs" ]]; then
        info "No resource groups found for cleanup"
        return 0
    fi

    local rg_count=0
    local failed_count=0
    while IFS= read -r rg_name; do
        [[ -z "$rg_name" ]] && continue
        info "Scheduling deletion of RG: $rg_name"
        local err
        set +e
        if err=$(az group delete -n "$rg_name" -y --no-wait 2>&1 >/dev/null); then
            ((rg_count++))
        else
            warn "Failed to schedule deletion of RG: $rg_name"
            warn "  az error: $err"
            ((failed_count++))
        fi
        set -e
    done <<< "$matching_rgs"

    info "Scheduled deletion of $rg_count resource group(s)"
    if [[ $failed_count -gt 0 ]]; then
        info "$failed_count resource group(s) couldn't be scheduled (likely already deleting)"
    fi
    return 0
}

# ── Azure prerequisites ───────────────────────────────────────────

check_azure_prereqs() {
    info "Checking Azure prerequisites..."
    if ! command -v az &>/dev/null; then
        error "Azure CLI (az) not found"
        return 1
    fi
    if ! az account show &>/dev/null; then
        error "Not logged into Azure. Please run: az login"
        return 1
    fi
    if ! az group list --query "[]" -o tsv &>/dev/null; then
        error "Azure authentication token has expired or is invalid"
        return 1
    fi
    info "✓ Azure prerequisites met"
}
