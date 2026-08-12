#!/bin/bash
set -eu

script="rhel8/nvidia-driver"

if grep -q '\[\[ ! -z \$(grep' "$script"; then
    echo "FAIL: firmware path check still uses a double-negative command substitution"
    exit 1
fi

# Verify the simplified grep -q check behaves correctly.
file=$(mktemp)
trap 'rm -f "$file"' EXIT

# A file containing only whitespace must be considered empty.
if grep -q '[^[:space:]]' "$file" 2>/dev/null; then
    echo "FAIL: whitespace-only file reported as non-empty"
    exit 1
fi

# A file containing non-whitespace text must be considered occupied.
echo "path" > "$file"
grep -q '[^[:space:]]' "$file"
