#!/bin/bash
set -eu
FILE=rhel9/nvidia-driver
if sed -n '/^_remove_prerequisites() {/,/^}/p' $FILE | grep -q '^[[:space:]]*true[[:space:]]*$'; then
  echo FAIL: dead true remains in _remove_prerequisites; exit 1
fi
echo PASS
