#!/bin/bash
set -euo pipefail

# Regression test for _find_vgpu_driver_version error handling under set -e.
# The function wraps vgpu-util calls with 'if ! var=$(cmd)' so that a failed
# command substitution does not abort the script before the error branches run.

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
driver_script="$repo_root/ubuntu26.04/nvidia-driver"
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

extract_function() {
    sed -n '/^_find_vgpu_driver_version() {/,/^}/p' "$driver_script"
}

run_case() {
    local count_rc=$1
    local count_stdout=$2
    local match_rc=$3
    local match_stdout=$4
    local expected_rc=$5
    local expected_msg=$6

    local inner="$tmp_dir/inner.sh"
    cat > "$inner" <<'HEADER'
set -e
DRIVER_VERSION="535.00"
NUM_VGPU_DEVICES=0
DISABLE_VGPU_VERSION_CHECK="false"
vgpu-util() {
    if [ "$1" = "count" ]; then
        echo "$COUNT_STDOUT"
        return "$COUNT_RC"
    fi
    echo "$MATCH_STDOUT"
    return "$MATCH_RC"
}
HEADER

    extract_function >> "$inner"

    cat >> "$inner" <<'FOOTER'
if ! output=$(_find_vgpu_driver_version 2>&1); then
    rc=1
else
    rc=0
fi
echo "RC=$rc"
echo "OUTPUT=$output"
FOOTER

    local result
    result=$(COUNT_STDOUT="$count_stdout" COUNT_RC="$count_rc" MATCH_STDOUT="$match_stdout" MATCH_RC="$match_rc" bash "$inner")

    local actual_rc
    actual_rc=$(printf '%s\n' "$result" | sed -n 's/^RC=//p')
    local output
    output=$(printf '%s\n' "$result" | sed -n 's/^OUTPUT=//p')

    if [ "$actual_rc" -ne "$expected_rc" ]; then
        echo "FAIL: expected rc $expected_rc, got $actual_rc"
        echo "$result"
        exit 1
    fi
    if [ -n "$expected_msg" ] && ! printf '%s\n' "$output" | grep -qF "$expected_msg"; then
        echo "FAIL: expected message '$expected_msg' in output"
        echo "$result"
        exit 1
    fi
}

run_case 1 "" 0 "" 0 "cannot find vgpu devices on host"
run_case 0 "count=0" 0 "" 0 ""
run_case 0 "count=1" 1 "" 1 "cannot find match for compatible vgpu driver"

echo "PASS"
