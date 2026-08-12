#!/usr/bin/env python3
"""Static regression tests for rhel9/nvidia-driver shell script."""
import os
import re


REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DRIVER_PATH = os.path.join(REPO_ROOT, "rhel9", "nvidia-driver")


def _read_driver():
    with open(DRIVER_PATH) as f:
        return f.read()


def _extract_function(content, name):
    pattern = r"^" + re.escape(name) + r"\(\) \{(.*?)^\}"
    match = re.search(pattern, content, re.MULTILINE | re.DOTALL)
    if not match:
        raise RuntimeError(f"Could not find {name}() in {DRIVER_PATH}")
    return match.group(0)


def test_unload_order():
    func = _extract_function(_read_driver(), "_unload_driver")
    order = []
    for line in func.splitlines():
        if 'rmmod_args+=(' in line:
            m = re.search(r'rmmod_args\+=\("([^"]+)"\)', line)
            if m:
                order.append(m.group(1))
    assert "nvidia" in order and "nvidia-peermem" in order
    assert order.index("nvidia-peermem") < order.index("nvidia"), (
        f"nvidia-peermem must be scheduled before nvidia, got {order}"
    )


def test_peermem_trap_before_sleep():
    func = _extract_function(_read_driver(), "reload_nvidia_peermem")
    lines = [ln.rstrip() for ln in func.splitlines()]
    for i, line in enumerate(lines):
        if line.strip() == "sleep inf":
            j = i - 1
            while j >= 0 and (not lines[j].strip() or lines[j].strip().startswith("#")):
                j -= 1
            prev = lines[j].strip() if j >= 0 else ""
            assert prev.startswith("trap "), (
                f"trap must be installed before sleep inf; preceding line was: {prev!r}"
            )


if __name__ == "__main__":
    test_unload_order()
