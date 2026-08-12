#!/bin/bash
# Regression test for [ -n ] in _update_ca_certificates.
set -eu

file="${1:-ubuntu22.04/nvidia-driver}"
body=$(sed -n '/^_update_ca_certificates() {/,/^}/p' "$file")

if echo "$body" | grep -qF '[ ! -z '; then
    echo "FAIL: double negative [ ! -z ] still present"
    exit 1
fi

if ! echo "$body" | grep -qF '[ -n '; then
    echo "FAIL: idiomatic [ -n ] not used"
    exit 1
fi

echo "PASS"
