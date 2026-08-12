#!/usr/bin/env bash
# Regression test for _unload_driver module removal order in rhel8/nvidia-driver.
#
# The nvidia module cannot be removed while nvidia-modeset, nvidia-uvm or
# nvidia-peermem are still loaded. This test verifies that _unload_driver
# calls rmmod with nvidia last.

set -euo pipefail

readonly DRIVER_SCRIPT="$(cd "$(dirname "$0")" && pwd)/../rhel8/nvidia-driver"
readonly TMPDIR="$(mktemp -d)"
readonly TEST_SYS="${TMPDIR}/sys/module"
readonly RMMOD_LOG="${TMPDIR}/rmmod.log"

cleanup() { rm -rf "${TMPDIR}"; }
trap cleanup EXIT

mkdir -p "${TEST_SYS}/"{nvidia,nvidia_modeset,nvidia_uvm,nvidia_peermem}
for m in nvidia nvidia_modeset nvidia_uvm nvidia_peermem; do
    echo 0 > "${TEST_SYS}/${m}/refcnt"
done

# Stubs for commands used by _unload_driver.
rmmod() {
    printf '%s\n' "$*" >> "${RMMOD_LOG}"
    for mod in "$@"; do
        local deps_loaded=()
        for dep in nvidia-modeset nvidia-uvm nvidia-peermem; do
            [[ -f "${TEST_SYS}/${dep}/refcnt" ]] && deps_loaded+=("${dep}")
        done
        if [[ "${mod}" == "nvidia" && ${#deps_loaded[@]} -gt 0 ]]; then
            echo "rmmod: nvidia is still in use by ${deps_loaded[*]}" >&2
            return 1
        fi
        rm -f "${TEST_SYS}/${mod}/refcnt"
    done
    return 0
}
kill() { return 0; }
seq() {
    local last="${1:-0}"
    local i
    for ((i=1; i<=last; i++)); do
        echo "${i}"
    done
}
sleep() { :; }

# Extract _unload_driver from the real script and rewrite /sys/module paths
# to use our test directory.
func_src=$(
    sed -n '/^_unload_driver() {/,/^}/p' "${DRIVER_SCRIPT}" \
        | sed "s#/sys/module/#${TEST_SYS}/#g"
)
eval "${func_src}"

set +e
_unload_driver
status=$?
set -e

if [[ $status -ne 0 ]]; then
    echo "FAIL: _unload_driver returned ${status}"
    exit 1
fi

expected="nvidia-modeset nvidia-uvm nvidia-peermem nvidia"
actual="$(cat "${RMMOD_LOG}")"

if [[ "${actual}" != "${expected}" ]]; then
    echo "FAIL: unexpected rmmod invocation order"
    echo "  expected: ${expected}"
    echo "  actual:   ${actual}"
    exit 1
fi

echo "PASS"
