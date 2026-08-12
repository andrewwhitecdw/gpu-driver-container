#!/bin/bash
set -eu

script="rhel8/nvidia-driver"

if grep -q 'source \$SCRIPT_DIR/common\.sh' "$script"; then
    echo "FAIL: source command is not quoted"
    exit 1
fi

# Demonstrate that quoting allows the source path to contain spaces.
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
mkdir -p "$dir/with spaces"
echo 'common_func() { :; }' > "$dir/with spaces/common.sh"
SCRIPT_DIR="$dir/with spaces"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/common.sh"
common_func

