#!/bin/bash
set -eu

# Regression test: module signing on RHEL must use the kernel-devel tree
# at /usr/src/kernels/<version>/scripts, not the Debian-style linux-headers path.

if grep -qE '/usr/src/linux-headers-\$\{KERNEL_VERSION\}/scripts' rhel10/nvidia-driver; then
    echo "FAIL: script uses Debian-style /usr/src/linux-headers path for signing"
    exit 1
fi

grep -qE '/usr/src/kernels/\$\{KERNEL_VERSION\}/scripts' rhel10/nvidia-driver

echo "PASS: script uses RHEL-style /usr/src/kernels path for signing"
