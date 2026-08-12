#!/bin/bash
set -eu

FILE="${1:-ubuntu22.04/nvidia-driver}"

wrong=$(grep -c 'if _kernel_requires_package; then' "$FILE" || true)
right=$(grep -c 'if ! _kernel_requires_package; then' "$FILE" || true)

if [ "$wrong" -ne 0 ]; then
    echo "FAIL: found $wrong unnegated _kernel_requires_package checks" >&2
    exit 1
fi

if [ "$right" -ne 2 ]; then
    echo "FAIL: expected 2 negated _kernel_requires_package checks, found $right" >&2
