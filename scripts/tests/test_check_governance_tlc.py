# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
#
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

import importlib.util
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "check_governance_tlc.py"
SPEC = importlib.util.spec_from_file_location("check_governance_tlc", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class ParseSummaryTest(unittest.TestCase):
    def test_extracts_successful_complete_graph(self):
        output = """TLC2 Version 2.19 of 08 August 2024 (rev: 5a47802)
Model checking completed. No error has been found.
184 states generated, 42 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 12.
"""
        self.assertEqual(
            MODULE.parse_summary(output),
            {
                "completed": True,
                "tlcVersion": "2.19 of 08 August 2024 (rev: 5a47802)",
                "statesGenerated": 184,
                "distinctStates": 42,
                "statesLeft": 0,
                "graphDepth": 12,
            },
        )

    def test_does_not_admit_partial_output(self):
        summary = MODULE.parse_summary("TLC2 Version 2.19\nError: invariant violated\n")
        self.assertFalse(summary["completed"])
        self.assertIsNone(summary["statesGenerated"])
        self.assertFalse(MODULE.summary_admitted(0, summary))

    def test_nonzero_exit_rejects_otherwise_complete_output(self):
        summary = {
            "completed": True,
            "tlcVersion": "2.19",
            "statesGenerated": 4,
            "distinctStates": 2,
            "statesLeft": 0,
            "graphDepth": 1,
        }
        self.assertFalse(MODULE.summary_admitted(1, summary))


if __name__ == "__main__":
    unittest.main()
