#!/bin/bash
# Regression test for init getopt support for -k/--kernel and -t/--tag.

set -eu

DRIVER_SCRIPT="ubuntu24.04/nvidia-driver"

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

[ -f "$DRIVER_SCRIPT" ] || fail "driver script not found at $DRIVER_SCRIPT"

# Verify the getopt invocation for init includes the new options.
getopt_line=$(grep -F 'init) options=$(getopt' "$DRIVER_SCRIPT" || true)
[ -n "$getopt_line" ] || fail "could not locate init getopt invocation"
echo "$getopt_line" | grep -q -- 'kernel:' || fail "getopt invocation missing --kernel"
echo "$getopt_line" | grep -q -- 'tag:' || fail "getopt invocation missing --tag"
echo "$getopt_line" | grep -q -- 'k:' || fail "getopt invocation missing -k"
echo "$getopt_line" | grep -q -- 't:' || fail "getopt invocation missing -t"

# Verify the usage text also documents the new options.
usage_block=$(sed -n '/^usage()/,/^}/p' "$DRIVER_SCRIPT")
echo "$usage_block" | grep -q -- '--kernel' || fail "usage text missing --kernel"
echo "$usage_block" | grep -q -- '--tag' || fail "usage text missing --tag"

echo "PASS: init getopt supports -k/--kernel and -t/--tag"
exit 0
