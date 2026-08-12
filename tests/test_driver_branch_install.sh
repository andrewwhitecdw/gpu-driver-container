#!/bin/bash
# Regression test for DRIVER_BRANCH default in _install_driver.
set -eu

file="${1:-ubuntu22.04/nvidia-driver}"
body=$(sed -n '/^_install_driver() {/,/^}/p' "$file")

if echo "$body" | grep -qF '${DRIVER_BRANCH}" -ge "550"'; then
    echo "FAIL: DRIVER_BRANCH is not defaulted in _install_driver"
    exit 1
fi

if ! echo "$body" | grep -qF '${DRIVER_BRANCH:-0}" -ge "550"'; then
    echo "FAIL: DRIVER_BRANCH default not applied in _install_driver"
    exit 1
fi

echo "PASS"
