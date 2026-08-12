#!/bin/bash
TEST_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
DRIVER_FILE="$TEST_DIR/../nvidia-driver"

# Regression tests for set -e / command-substitution error handling in rhel10/nvidia-driver.

set -u

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Stub common.sh so sourcing the driver definitions does not fail.
mkdir -p "$TMPDIR"
: > "$TMPDIR/common.sh"

# Variables required by the top-level definitions in nvidia-driver.
export SCRIPT_DIR="$TMPDIR"
export TARGETARCH="amd64"
export DRIVER_VERSION="535.104.05"
export DISABLE_VGPU_VERSION_CHECK="false"

# Source only the function/variable definitions; strip the command-dispatch
# tail (everything from usage() onward).
sed '0,/^usage()/d' "$DRIVER_FILE" > "$TMPDIR/defs.sh"
source "$TMPDIR/defs.sh"

# Mock external commands so we can exercise the failure paths.
mkdir -p "$TMPDIR/bin"
cat > "$TMPDIR/bin/nvidia-installer" <<'EOF'
#!/bin/bash
exit 1
EOF
chmod +x "$TMPDIR/bin/nvidia-installer"

cat > "$TMPDIR/bin/vgpu-util" <<'EOF'
#!/bin/bash
exit 1
EOF
chmod +x "$TMPDIR/bin/vgpu-util"

export PATH="$TMPDIR/bin:$PATH"

FAILED=0

# When nvidia-installer fails, _resolve_kernel_type must fall back to the
# driver-branch heuristic instead of exiting due to set -e.
if ! result=$(
    KERNEL_MODULE_TYPE=auto DRIVER_BRANCH=570 \
    _resolve_kernel_type && printf '%s' "$KERNEL_TYPE"
); then
    echo "FAIL: _resolve_kernel_type exited on a failing nvidia-installer"
    FAILED=1
elif [ "$result" != "kernel-open" ]; then
    echo "FAIL: _resolve_kernel_type fallback returned '$result', expected kernel-open"
    FAILED=1
fi

# When vgpu-util count fails, _find_vgpu_driver_version must treat it as
# "no vGPU devices" and return 0 instead of aborting under set -e.
if ! result=$(
    NUM_VGPU_DEVICES=0 \
    _find_vgpu_driver_version && printf '%s' "$NUM_VGPU_DEVICES"
); then
    echo "FAIL: _find_vgpu_driver_version aborted on a failing vgpu-util count"
    FAILED=1
elif [ "$result" != "0" ]; then
    echo "FAIL: _find_vgpu_driver_version returned '$result', expected 0"
    FAILED=1
fi

if [ "$FAILED" -ne 0 ]; then
    exit 1
fi

echo "PASS"
