#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.."; pwd)"
script_path="${repo_root}/rhel9/nvidia-driver"

if [ ! -f "$script_path" ]; then
    echo "FAIL: $script_path not found"
    exit 1
fi

failures=0

# Test 1: PID file must not be truncated before lock is acquired.
echo "Test 1: PID file is opened without truncating before locking"
if awk '/^_prepare_exclusive\(\) \{/,/^\}/' "$script_path" | grep -q 'exec 3> \${PID_FILE}'; then
    echo "FAIL: _prepare_exclusive truncates PID_FILE before acquiring flock"
    failures=$((failures + 1))
else
    echo "PASS"
fi

# Test 2: nvidia-peermem must be removed before nvidia.
echo "Test 2: nvidia-peermem is unloaded before nvidia"
unload_order=$(awk '/^_unload_driver\(\) \{/,/^\}/' "$script_path" | grep -o 'rmmod_args+=("nvidia[^"]*")' | sed 's/rmmod_args+=("//;s/")$//')
expected_order="nvidia-modeset
nvidia-uvm
nvidia-peermem
nvidia"
if [ "$unload_order" != "$expected_order" ]; then
    echo "FAIL: rmmod order is incorrect"
    echo "Expected:"
    echo "$expected_order"
    echo "Got:"
    echo "$unload_order"
    failures=$((failures + 1))
else
    echo "PASS"
fi

# Test 3: CLI parsing uses positional parameters, not raw getopt string.
echo "Test 3: CLI arguments parsed from positional parameters"
if grep -q 'for opt in \${options}; do' "$script_path"; then
    echo "FAIL: argument parsing iterates over raw getopt options string"
    failures=$((failures + 1))
elif ! grep -q 'case "\$1" in' "$script_path"; then
    echo "FAIL: argument parsing does not use positional parameters (\$1)"
    failures=$((failures + 1))
else
    echo "PASS"
fi

if [ "$failures" -ne 0 ]; then
    echo "$failures test(s) failed"
    exit 1
fi
