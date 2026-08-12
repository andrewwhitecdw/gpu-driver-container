#!/bin/bash
# Regression test: commands that take no CLI options must not trigger usage.
set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
DRIVER_SCRIPT="$SCRIPT_DIR/../rhel9/nvidia-driver"

# Provide required environment so argument parsing is actually reached.
export DRIVER_VERSION="535.104.05"
export TARGETARCH="amd64"

failed=0
for cmd in load reload_nvidia_peermem probe_nvidia_peermem; do
    echo "Testing command: $cmd"
    output=$("$DRIVER_SCRIPT" "$cmd" 2>&1) || true
    if echo "$output" | grep -q "Usage:"; then
        echo "FAIL: $cmd printed usage message"
        failed=1
    fi
done

if [ "$failed" -ne 0 ]; then
    exit 1
