#!/bin/bash
# Test script to validate systemd health status.
# This script checks for service failures and system degradation.
# Designed to run inside the Azure Container Linux (ACL) VM.

set -euo pipefail

echo "========================================="
echo "Systemd Health Validation Test"
echo "========================================="
echo ""

# Check if systemd is running
if ! command -v systemctl &>/dev/null; then
    echo "❌ FAILED: systemctl command not found"
    exit 1
fi

echo "✓ systemctl command is available"

# Check for failed units
echo ""
echo "Checking for failed units..."
FAILED_UNITS=$(systemctl --failed --no-legend --no-pager 2>/dev/null || true)

# Check overall system state
echo "Checking system state..."
SYSTEM_STATE=$(systemctl is-system-running 2>/dev/null || true)

echo "System State: $SYSTEM_STATE"
echo ""

if [ "$SYSTEM_STATE" = "running" ]; then
    echo "✓ System is in 'running' state"
elif [ "$SYSTEM_STATE" = "initializing" ] || [ "$SYSTEM_STATE" = "starting" ]; then
    echo "⚠ System is still starting up ($SYSTEM_STATE), waiting..."
    sleep 10
    SYSTEM_STATE=$(systemctl is-system-running 2>/dev/null || true)
    echo "System State after waiting: $SYSTEM_STATE"
    if [ "$SYSTEM_STATE" != "running" ]; then
        echo "❌ FAILED: System did not reach 'running' state"
    fi
elif [ "$SYSTEM_STATE" = "degraded" ]; then
    echo "❌ FAILED: System is in 'degraded' state"
else
    echo "❌ FAILED: Unexpected system state: $SYSTEM_STATE"
fi

if [ -z "$FAILED_UNITS" ]; then
    echo "✓ No failed systemd units"
else
    echo "❌ FAILED: The following units have failed:"
    echo ""
    echo "$FAILED_UNITS"
    echo ""

    # Get details for each failed unit
    echo "Detailed failure information:"
    echo "-----------------------------"
    while IFS= read -r line; do
        UNIT_NAME=$(echo "$line" | awk '{print $2}')
        if [ -n "$UNIT_NAME" ]; then
            echo ""
            echo "Unit: $UNIT_NAME"
            systemctl status "$UNIT_NAME" --no-pager 2>/dev/null || true
            echo ""
        fi
    done <<< "$FAILED_UNITS"
fi

# Final summary
echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="

EXIT_CODE=0

if [ "$SYSTEM_STATE" != "running" ]; then
    echo "❌ System state: $SYSTEM_STATE (expected: running)"
    EXIT_CODE=1
else
    echo "✅ System state: running"
fi

if [ -n "$FAILED_UNITS" ]; then
    FAILED_COUNT=$(echo "$FAILED_UNITS" | wc -l)
    echo "❌ Failed units: $FAILED_COUNT"
    EXIT_CODE=1
else
    echo "✅ Failed units: 0"
fi

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ SUCCESS: Systemd is healthy with no failures"
else
    echo "❌ FAILED: Systemd health check failed"
fi

exit $EXIT_CODE
