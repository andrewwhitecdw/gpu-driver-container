#!/bin/bash
# Regression tests for the option parsing in rhel8/nvidia-driver.
set -u

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DRIVER_SCRIPT="${SCRIPT_DIR}/../nvidia-driver"

if [ ! -f "${DRIVER_SCRIPT}" ]; then
    echo "ERROR: driver script not found at ${DRIVER_SCRIPT}" >&2
    exit 1
fi

extract_parser() {
    awk '/^if \[ \$# -eq 0 \]; then/{p=1} p' "${DRIVER_SCRIPT}"
}

run_case() {
    local args="$1"
    local expected="$2"
    local description="$3"
    local parser tmpdir output rc

    tmpdir=$(mktemp -d)
    parser="${tmpdir}/parser.sh"

    {
        cat <<'EOF'
#!/bin/bash
set -u

_resolve_rhel_version() { return 0; }
usage() { echo "USAGE"; exit 1; }

build() {
  echo "ACCEPT_LICENSE=${ACCEPT_LICENSE:-}"
  echo "PACKAGE_TAG=${PACKAGE_TAG:-}"
  echo "MAX_THREADS=${MAX_THREADS:-}"
  echo "KERNEL_VERSION=${KERNEL_VERSION:-}"
  echo "PRIVATE_KEY=${PRIVATE_KEY:-}"
}

update() {
  build
}

load() {
  build
}
EOF
        extract_parser
    } > "${parser}"
    chmod +x "${parser}"

    # shellcheck disable=SC2086
    output=$(bash "${parser}" ${args}) || rc=$?
    rc=${rc:-0}

    rm -rf "${tmpdir}"

    if [ "${output}" = "${expected}" ] && [ "${rc}" -eq 0 ]; then
        echo "PASS: ${description}"
        return 0
    else
        echo "FAIL: ${description}"
        echo "  args: ${args}"
        echo "  expected:"
        printf '%s\n' "${expected}" | sed 's/^/    /'
        echo "  got (exit ${rc}):"
        printf '%s\n' "${output}" | sed 's/^/    /'
        return 1
    fi
}

failures=0
default_kernel=$(uname -r)

run_case 'build -t -a' \
"ACCEPT_LICENSE=
PACKAGE_TAG=-a
MAX_THREADS=
KERNEL_VERSION=${default_kernel}
PRIVATE_KEY=" \
'does not treat an option-like tag value as a flag' || failures=$((failures + 1))

run_case 'build -a -t mytag' \
"ACCEPT_LICENSE=yes
PACKAGE_TAG=mytag
MAX_THREADS=
KERNEL_VERSION=${default_kernel}
PRIVATE_KEY=" \
'parses accept-license and tag correctly' || failures=$((failures + 1))

run_case 'update -m 4 -k 5.4.0-test -s mykey' \
"ACCEPT_LICENSE=
PACKAGE_TAG=
MAX_THREADS=4
KERNEL_VERSION=5.4.0-test
PRIVATE_KEY=mykey" \
'parses numeric and string option values correctly' || failures=$((failures + 1))

run_case 'load' \
"ACCEPT_LICENSE=
PACKAGE_TAG=
MAX_THREADS=
KERNEL_VERSION=${default_kernel}
PRIVATE_KEY=" \
'handles commands without options' || failures=$((failures + 1))

if [ "${failures}" -ne 0 ]; then
    echo "${failures} test(s) failed" >&2
    exit 1
fi

echo "All tests passed"
