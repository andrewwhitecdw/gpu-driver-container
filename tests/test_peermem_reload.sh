#!/bin/bash
# Regression test: reload_nvidia_peermem must install signal handlers before
# entering the indefinite wait and must use the portable 'sleep infinity'.
set -euo pipefail

driver_file="ubuntu22.04/nvidia-driver"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

# Extract reload_nvidia_peermem function body.
awk '/^reload_nvidia_peermem\(\) \{/,/^\}$/' "$driver_file" > "$tmp"

# The original code used 'sleep inf' and set the trap after the sleep.
if grep -q "sleep inf" "$tmp"; then
    echo "FAIL: reload_nvidia_peermem uses 'sleep inf' instead of 'sleep infinity'"
    exit 1
fi

# Every 'sleep infinity' inside the function must be preceded (within two lines)
# by the signal trap.
awk '
    /^reload_nvidia_peermem\(\) \{/{in_func=1}
    in_func && /trap "echo .Caught signal.; exit 1" HUP INT QUIT PIPE TERM/{trap_line=NR}
    in_func && /sleep infinity/{
        if (trap_line == 0 || NR - trap_line > 2) {
            print "FAIL: sleep infinity at line " NR " is not protected by a trap"
            exit 1
        }
        trap_line=0
    }
    in_func && /^\}$/{exit}
' "$tmp"

