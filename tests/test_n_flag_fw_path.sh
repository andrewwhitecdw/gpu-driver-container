#!/bin/bash
# Regression test for [[ -n ]] in _load_driver firmware path check.
set -eu

file="${1:-ubuntu22.04/nvidia-driver}"
body=$(sed -n '/^_load_driver() {/,/^}/p' "$file")

if echo "$body" | grep -qF '[[ ! -z '; then
    echo "FAIL: double negative [[ ! -z ]] still present"
    exit 1
fi

if ! echo "$body" | grep -qF '[[ -n $(grep'; then
    echo "FAIL: idiomatic [[ -n ]] not used"
    exit 1
fi

echo "PASS"
