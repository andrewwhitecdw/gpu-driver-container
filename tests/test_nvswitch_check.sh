#!/bin/bash
# Regression test for _assert_nvswitch_system safely handling an empty devices dir.
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRIVER_SCRIPT="$SCRIPT_DIR/../rhel9/nvidia-driver"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Extract the function from the real script and point it at a temp directory.
FUNC=$(
  sed -n '/^_assert_nvswitch_system()/,/^}/p' "$DRIVER_SCRIPT" \
    | sed "s|/proc/driver/nvidia-nvswitch|$TMP_DIR|g"
)
eval "$FUNC"

run_check() {
  (
    set -e
    if _assert_nvswitch_system; then
      echo "ok" > "$TMP_DIR/done"
    else
      echo "ok" > "$TMP_DIR/done"
    fi
  )
}

mkdir -p "$TMP_DIR/devices"
run_check || true
if [ ! -f "$TMP_DIR/done" ]; then
  echo "FAIL: empty devices directory caused set -e abort"
  exit 1
fi

rm -f "$TMP_DIR/done"
touch "$TMP_DIR/devices/0"
run_check || true
if [ ! -f "$TMP_DIR/done" ]; then
  echo "FAIL: populated devices directory caused unexpected abort"
  exit 1
fi

echo "PASS"
