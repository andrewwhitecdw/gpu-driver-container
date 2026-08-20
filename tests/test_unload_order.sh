#!/usr/bin/env bash
set -euo pipefail

srcdir="$(dirname "$0")"
driver_file="${srcdir}/../rhel8/nvidia-driver"
testdir=$(mktemp -d)
trap 'rm -rf "$testdir"' EXIT

sysmodule="$testdir/sys/module"
for mod in nvidia nvidia_modeset nvidia_uvm nvidia_peermem; do
    mkdir -p "$sysmodule/$mod"
done

echo 3 > "$sysmodule/nvidia/refcnt"
echo 0 > "$sysmodule/nvidia_modeset/refcnt"
echo 0 > "$sysmodule/nvidia_uvm/refcnt"
echo 0 > "$sysmodule/nvidia_peermem/refcnt"

func=$(sed -n '/^_unload_driver() {/,/^}$/p' "$driver_file")
func=$(printf '%s\n' "$func" | sed "s#/sys/module#$sysmodule#g; s#/var/run#$testdir#g")

rmmod_log="$testdir/rmmod.log"
rmmod() {
    echo "$*" >> "$rmmod_log"
}

eval "$func"

if ! _unload_driver; then
    echo "FAIL: _unload_driver returned non-zero"
    exit 1
fi

expected="nvidia-modeset nvidia-uvm nvidia-peermem nvidia"
actual=$(cat "$rmmod_log")
if [ "$actual" != "$expected" ]; then
    echo "FAIL: unexpected rmmod order: $actual"
    exit 1
fi

echo "PASS"
