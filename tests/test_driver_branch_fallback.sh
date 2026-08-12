#!/bin/bash
# Regression test for DRIVER_BRANCH default in fallback resolver.
set -eu

file="${1:-ubuntu22.04/nvidia-driver}"
body=$(sed -n '/^_resolve_kernel_type_from_driver_branch() {/,/^}/p' "$file")

if echo "$body" | grep -qF '${DRIVER_BRANCH}" -lt 560'; then
    echo "FAIL: DRIVER_BRANCH is not defaulted in fallback resolver"
    exit 1
fi

if ! echo "$body" | grep -qF '${DRIVER_BRANCH:-0}" -lt 560'; then
    echo "FAIL: DRIVER_BRANCH default not applied in fallback resolver"
    exit 1
fi

echo "PASS"
