#!/usr/bin/env bash
set -euo pipefail

srcdir="$(dirname "$0")"
driver_file="${srcdir}/../rhel8/nvidia-driver"
testdir=$(mktemp -d)
trap 'rm -rf "$testdir"' EXIT

func=$(sed -n '/^_get_module_params() {/,/^}$/p' "$driver_file")
func=$(printf '%s\n' "$func" | sed "s#/drivers#$testdir#g")

eval "$func"

# No config files
NVIDIA_MODULE_PARAMS=()
NVIDIA_UVM_MODULE_PARAMS=()
NVIDIA_MODESET_MODULE_PARAMS=()
NVIDIA_PEERMEM_MODULE_PARAMS=()

if ! _get_module_params; then
    echo "FAIL: non-zero exit with no config files"
    exit 1
fi

if [ "${#NVIDIA_MODULE_PARAMS[@]}" -ne 1 ] || [ "${NVIDIA_MODULE_PARAMS[0]}" != "NVreg_CoherentGPUMemoryMode=driver" ]; then
    echo "FAIL: default nvidia parameter missing"
    exit 1
fi

# Partial config files
NVIDIA_MODULE_PARAMS=()
NVIDIA_UVM_MODULE_PARAMS=()
NVIDIA_MODESET_MODULE_PARAMS=()
NVIDIA_PEERMEM_MODULE_PARAMS=()

echo "uvm-option" > "$testdir/nvidia-uvm.conf"

if ! _get_module_params; then
    echo "FAIL: non-zero exit with partial config files"
    exit 1
fi

if [ "${#NVIDIA_UVM_MODULE_PARAMS[@]}" -ne 1 ] || [ "${NVIDIA_UVM_MODULE_PARAMS[0]}" != "uvm-option" ]; then
    echo "FAIL: uvm parameter not read"
    exit 1
fi

echo "PASS"
