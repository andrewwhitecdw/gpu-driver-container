#!/bin/bash
# Regression test for _find_vgpu_driver_version handling a failing vgpu-util.
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRIVER_SCRIPT="$SCRIPT_DIR/../rhel9/nvidia-driver"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

FUNC=$(sed -n '/^_find_vgpu_driver_version()/,/^}/p' "$DRIVER_SCRIPT")
eval "$FUNC"

vgpu-util() { return 1; }
DISABLE_VGPU_VERSION_CHECK=false

(
  set -e
  _find_vgpu_driver_version
  echo "completed" > "$TMP_DIR/done"
) || true

if [ ! -f "$TMP_DIR/done" ]; then
  echo "FAIL: vgpu-util failure caused set -e abort"
  exit 1
fi

