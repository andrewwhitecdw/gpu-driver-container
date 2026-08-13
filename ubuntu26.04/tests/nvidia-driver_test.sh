#!/usr/bin/env bash
set -u

readonly DRIVER_SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/nvidia-driver"
readonly TMPDIR="$(mktemp -d)"
trap 'rm -rf \"$TMPDIR\"' EXIT

if [ ! -f "$DRIVER_SCRIPT" ]; then
    echo "ERROR: driver script not found at $DRIVER_SCRIPT" >&2
    exit 1
fi

# Extract the function under test from the real driver script.
awk '/^_find_vgpu_driver_version\(\) \{/,/^}/' "$DRIVER_SCRIPT" > "$TMPDIR/vgpu_func.sh"

# Stub vgpu-util so that the default path reports zero vGPU devices.
mkdir -p "$TMPDIR/bin"
cat > "$TMPDIR/bin/vgpu-util" <<'EOF'
#!/usr/bin/env bash
set -u
if [ "${1:-}" = "count" ]; then
    echo "count=0"
    exit 0
fi
echo "unexpected vgpu-util args: $*" >&2
exit 1
EOF
chmod +x "$TMPDIR/bin/vgpu-util"

run_test() {
    local env_setup="$1"
    (
        set -eu
        export TMPDIR
        . "$TMPDIR/vgpu_func.sh"
        export PATH="$TMPDIR/bin:$PATH"
        export DRIVER_VERSION="550.90.07"
        export NUM_VGPU_DEVICES=0
        eval "$env_setup"
        _find_vgpu_driver_version
    )
}

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

# Unset DISABLE_VGPU_VERSION_CHECK must not trigger an unbound-variable error.
output=$(run_test 'unset DISABLE_VGPU_VERSION_CHECK') || fail "unset DISABLE_VGPU_VERSION_CHECK caused an error"
if echo "$output" | grep -q "vgpu version compatibility check is disabled"; then
    fail "unset DISABLE_VGPU_VERSION_CHECK skipped the check"
fi
echo "PASS: unset DISABLE_VGPU_VERSION_CHECK succeeds"

# Explicitly enabling the disable flag must short-circuit and print the message.
output=$(run_test 'export DISABLE_VGPU_VERSION_CHECK=true') || fail "DISABLE_VGPU_VERSION_CHECK=true caused an error"
if ! echo "$output" | grep -q "vgpu version compatibility check is disabled"; then
    fail "disable message not printed"
fi
echo "PASS: DISABLE_VGPU_VERSION_CHECK=true disables the check"
