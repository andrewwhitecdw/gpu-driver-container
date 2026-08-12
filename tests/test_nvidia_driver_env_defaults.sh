#!/bin/bash
# Regression test: optional environment variables have safe defaults.
set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
DRIVER_SCRIPT="$SCRIPT_DIR/../rhel9/nvidia-driver"

check_default() {
    local var=$1
    if ! grep -q "\${${var}:-}" "$DRIVER_SCRIPT"; then
        echo "FAIL: $var is used without a default value"
        exit 1
    fi
}

check_default "DISABLE_VGPU_VERSION_CHECK"

# DRIVER_BRANCH is also covered in this file once a default is added.

echo "PASS"
