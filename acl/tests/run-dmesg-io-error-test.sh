#!/bin/bash
# Test script to validate that dmesg does not contain I/O errors.
# This script checks the kernel ring buffer for I/O error messages
# that could indicate disk, filesystem, or device problems.
# Designed to run inside the Azure Container Linux (ACL) VM.

set -euo pipefail

echo "========================================="
echo "Dmesg I/O Error Validation Test"
echo "========================================="
echo ""

# Check if dmesg is available
if ! command -v dmesg &>/dev/null; then
    echo "❌ FAILED: dmesg command not found"
    exit 1
fi

echo "✓ dmesg command is available"

# Capture dmesg output
echo ""
echo "Checking kernel ring buffer for I/O errors..."

DMESG_OUTPUT=$(dmesg 2>/dev/null || true)

if [ -z "$DMESG_OUTPUT" ]; then
    echo "⚠ WARNING: dmesg returned no output (may need root privileges)"
    echo "Attempting with sudo..."
    DMESG_OUTPUT=$(sudo dmesg 2>/dev/null || true)
    if [ -z "$DMESG_OUTPUT" ]; then
        echo "❌ FAILED: Unable to read dmesg output"
        exit 1
    fi
fi

# Search for I/O error patterns in dmesg
# Common patterns:
#   "I/O error" - generic block device I/O errors
#   "Buffer I/O error" - buffered I/O failures
#   "blk_update_request: I/O error" - block layer errors
#   "EXT4-fs error" / "ext4_" errors - filesystem errors
#   "SCSI error" - SCSI subsystem errors
#   "ata.*error" - ATA/SATA errors
#   "mmc.*error" - MMC/SD card errors

IO_ERROR_PATTERNS="I/O error|Buffer I/O error|blk_update_request.*I/O|EXT4-fs error|XFS.*I/O error|SCSI error|medium error|hardware error"

IO_ERRORS=$(echo "$DMESG_OUTPUT" | grep -iE "$IO_ERROR_PATTERNS" 2>/dev/null || true)

# Final summary
echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="

EXIT_CODE=0

if [ -n "$IO_ERRORS" ]; then
    ERROR_COUNT=$(echo "$IO_ERRORS" | wc -l)
    echo "❌ I/O errors found: $ERROR_COUNT"
    echo ""
    echo "Error details:"
    echo "-----------------------------"
    echo "$IO_ERRORS"
    echo "-----------------------------"
    EXIT_CODE=1
else
    echo "✅ I/O errors found: 0"
fi

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ SUCCESS: No I/O errors detected in dmesg"
else
    echo "❌ FAILED: I/O errors detected in kernel ring buffer"
fi

exit $EXIT_CODE
