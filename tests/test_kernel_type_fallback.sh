#!/bin/bash
# Regression test for _resolve_kernel_type falling back when nvidia-installer fails.
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRIVER_SCRIPT="$SCRIPT_DIR/../rhel9/nvidia-driver"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

FUNC_TYPE=$(sed -n '/^_resolve_kernel_type()/,/^}/p' "$DRIVER_SCRIPT")
FUNC_BRANCH=$(sed -n '/^_resolve_kernel_type_from_driver_branch()/,/^}/p' "$DRIVER_SCRIPT")
eval "$FUNC_TYPE"
eval "$FUNC_BRANCH"

nvidia-installer() { return 1; }
DRIVER_BRANCH=570
KERNEL_MODULE_TYPE=auto

(
  set -e
  _resolve_kernel_type
  echo "$KERNEL_TYPE" > "$TMP_DIR/result"
) || true

if [ ! -f "$TMP_DIR/result" ]; then
  echo "FAIL: nvidia-installer failure caused set -e abort before fallback"
  exit 1
fi

result=$(< "$TMP_DIR/result")
if [ "$result" != "kernel-open" ]; then
  echo "FAIL: expected kernel-open, got $result"
  exit 1
fi

echo "PASS"
