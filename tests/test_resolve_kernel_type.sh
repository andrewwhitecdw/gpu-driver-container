#!/bin/bash
set -eu

FILE="${1:-ubuntu22.04/nvidia-driver}"

if grep -A1 -F 'kernel_module_type=$(nvidia-installer --print-recommended-kernel-module-type)' "$FILE" | grep -F 'if [ $? -ne 0 ]; then' >/dev/null; then
    echo 'FAIL: _resolve_kernel_type checks $? after command substitution' >&2
    exit 1
fi

if ! grep -F 'if kernel_module_type=$(nvidia-installer --print-recommended-kernel-module-type); then' "$FILE" >/dev/null; then
    echo 'FAIL: _resolve_kernel_type should use if cmdsubst; then' >&2
    exit 1
fi
