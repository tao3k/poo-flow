# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
#
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Tests for the single-authority Gerbil dependency pin projection."""

from __future__ import annotations

import importlib.util
import subprocess
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
SCRIPT = ROOT / "packages" / "automation" / "gerbil_dependency_pin.py"


def pin_module():
    spec = importlib.util.spec_from_file_location("gerbil_dependency_pin", SCRIPT)
    assert spec is not None
    assert spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class GerbilDependencyPinTest(unittest.TestCase):
    def test_gerbil_package_is_the_direct_revision_authority(self) -> None:
        module = pin_module()
        pins = module.parse_package_pins((ROOT / "gerbil.pkg").read_text(encoding="utf-8"))
        self.assertGreaterEqual(set(pins), {"asp-gerbil-scheme", "gerbil-parser"})

    def test_repository_dependency_projection_is_closed(self) -> None:
        completed = subprocess.run(
            [sys.executable, str(SCRIPT), "check"],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertIn("gerbil-dependency-contract: ok", completed.stdout)


if __name__ == "__main__":
    unittest.main()
