#!/usr/bin/env python3
"""Regression test for the _assert_nvswitch_system helper."""

import pathlib
import re
import unittest


ROOT = pathlib.Path(__file__).resolve().parent.parent
DRIVER = ROOT / "rhel10" / "nvidia-driver"


class TestNvswitchDevices(unittest.TestCase):
    def test_no_ls_glob(self):
        """Device presence must not rely on parsing ls output under set -e."""
        content = DRIVER.read_text()
        match = re.search(
            r"^_assert_nvswitch_system\\(\\)\\s*\\{(.*?)^\\}",
            content,
            re.MULTILINE | re.DOTALL,
        )
        self.assertTrue(match, "_assert_nvswitch_system function not found")
        body = match.group(1)
        self.assertNotIn("ls -1 /proc/driver/nvidia-nvswitch/devices/*", body)


