#!/bin/bash
# Regression test for missing NVSwitch devices under set -e.
# The helper below uses the same ls idiom as _assert_nvswitch_system()
# in rhel10/nvidia-driver, but with a configurable base directory so it
# can be exercised without real /proc hardware.

set -euo pipefail

_assert_nvswitch_system() {
    local base=$1
    [ -d "${base}" ] || return 1
    entries=$(ls -1 ${base}/devices/* 2>/dev/null) || true
    if [ -z "${entries}" ]; then
        return 1
    fi
    return 0
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fail=0

# Missing base directory should return 1, not abort.
_assert_nvswitch_system "${tmp}/nvswitch" && {
    echo "FAIL: missing directory should return 1"
    fail=1
}

# Existing directory with no devices should return 1, not abort.
mkdir -p "${tmp}/empty/devices"
_assert_nvswitch_system "${tmp}/empty" && {
    echo "FAIL: empty device directory should return 1"
    fail=1
}

# Existing directory with devices should return 0.
mkdir -p "${tmp}/present/devices"
touch "${tmp}/present/devices/device0" "${tmp}/present/devices/device1"
_assert_nvswitch_system "${tmp}/present" || {
    echo "FAIL: populated device directory should return 0"
    fail=1
}

if [ "${fail}" -ne 0 ]; then
    exit 1
fi

echo "OK: missing NVSwitch devices are tolerated under set -e"
