#!/bin/bash
set -euo pipefail

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/devices"

eval "$(sed -n '/^_assert_nvswitch_system()/,/^}/p' rhel9/nvidia-driver | sed "s|/proc/driver/nvidia-nvswitch|$tmp_dir|g")"

if _assert_nvswitch_system; then
    echo "FAIL: expected _assert_nvswitch_system to return 1"
    exit 1
else
    echo "PASS: _assert_nvswitch_system returned 1 without aborting the shell"
