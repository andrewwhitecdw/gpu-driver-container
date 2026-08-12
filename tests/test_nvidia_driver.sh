#!/bin/bash
# Minimal self-contained regression tests for rhel10/nvidia-driver.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
DRIVER_FILE="$ROOT/rhel10/nvidia-driver"

run_in_subshell() {
    local body=$1
    local script
    # Build a script that sources the driver file with a harmless command so
    # function definitions are loaded, then executes the requested body.
    script=$(cat <<EOF
DRIVER_VERSION=535.104.05
TARGETARCH=amd64
KERNEL_VERSION=5.14.0-427.13.1.el10_0.x86_64
lsmod() { :; }
source $DRIVER_FILE probe_nvidia_peermem || true
$body
EOF
    )
    local status=0
    output=$(bash -c "$script" 2>&1) || status=$?
    printf '%s\n' "$output"
    return $status
}

# Test 1: vgpu-util count failure must be handled gracefully.
status=0
output=$(run_in_subshell 'vgpu-util() { return 1; }; DISABLE_VGPU_VERSION_CHECK=false; _find_vgpu_driver_version') || status=$?
if [ "$status" -ne 0 ]; then
    echo "FAIL: _find_vgpu_driver_version should survive a failing vgpu-util count (status=$status)"
    echo "$output"
    exit 1
fi
if [[ "$output" != *"cannot find vgpu devices"* ]]; then
    echo "FAIL: expected vgpu-util count failure message"
    echo "$output"
    exit 1
fi

# Test 2: vgpu-util match failure must be reported.
status=0
output=$(run_in_subshell 'vgpu-util() { if [[ "$*" == *count* ]]; then echo "count=2"; return 0; else return 1; fi; }; DISABLE_VGPU_VERSION_CHECK=false; _find_vgpu_driver_version') || status=$?
if [ "$status" -ne 1 ]; then
    echo "FAIL: _find_vgpu_driver_version should return 1 when vgpu-util match fails (status=$status)"
    echo "$output"
    exit 1
fi
if [[ "$output" != *"cannot find match for compatible vgpu driver"* ]]; then
    echo "FAIL: expected vgpu-util match failure message"
    echo "$output"
    exit 1
fi

# Test 3: nvidia-installer failure must fall back to driver branch.
status=0
output=$(run_in_subshell 'KERNEL_MODULE_TYPE=auto; DRIVER_BRANCH=570; nvidia-installer() { return 1; }; _resolve_kernel_type; echo "KERNEL_TYPE=$KERNEL_TYPE"') || status=$?
if [ "$status" -ne 0 ]; then
    echo "FAIL: _resolve_kernel_type should fall back instead of aborting (status=$status)"
    echo "$output"
    exit 1
fi
if [[ "$output" != *"falling back to using the driver branch"* ]]; then
    echo "FAIL: expected fallback message from _resolve_kernel_type"
    echo "$output"
    exit 1
fi
if [[ "$output" != *"KERNEL_TYPE=kernel-open"* ]]; then
    echo "FAIL: expected KERNEL_TYPE=kernel-open for driver branch 570"
    echo "$output"
    exit 1
fi

# Test 4: _remove_prerequisites must not contain a literal no-op.
if awk '/^_remove_prerequisites\(\)/{found=1} found && /^}/ {exit} found {if (/^[[:space:]]*true$/) {exit 1}}' "$DRIVER_FILE"; then
    : # pass
else
    echo "FAIL: _remove_prerequisites contains a no-op 'true' command"
    exit 1
fi

echo "PASS"
