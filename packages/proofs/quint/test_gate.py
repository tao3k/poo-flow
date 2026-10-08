# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Admission failure and exact-source freshness controls for the proof gate."""
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from poo_flow_testing.checks import quint
from source_binding import check_binding

ROOT = Path(__file__).resolve().parents[3]


class GateTest(unittest.TestCase):
    def test_crash_is_not_an_expected_counterexample(self):
        context = SimpleNamespace(repository_root=ROOT)
        with patch.object(quint.subprocess, 'run', return_value=SimpleNamespace(stdout='0.33.0')), \
             patch.object(quint, '_run_quint', return_value=(1, b'error: syntax failure', 1)):
            with self.assertRaisesRegex(AssertionError, 'unexpected Quint result'):
                quint.check_quint(context, quint.QuintCase('TemporalFamilyMutation',
                                                          'TerminalAgreement', True))

    def test_no_output_terminates_the_child(self):
        with tempfile.TemporaryDirectory() as work, patch.object(quint, 'IDLE_LIMIT_SECONDS', 0.1):
            with self.assertRaisesRegex(TimeoutError, 'no bytes'):
                quint._run_quint([sys.executable, '-c', 'import time; time.sleep(10)'], Path(work))

    def test_quint_change_invalidates_lean_source_binding(self):
        source = ROOT / 'packages/proofs/quint/HealthcareStandardMigration.qnt'
        lean = ROOT / 'packages/proofs/lean/PooFlowProof/Vertical/Healthcare/StandardMigrationRefinement.lean'
        check_binding(source, lean)
        with tempfile.TemporaryDirectory() as work:
            changed = Path(work) / source.name
            changed.write_bytes(source.read_bytes() + b'\n// different source identity\n')
            with self.assertRaisesRegex(AssertionError, 'stale Quint source digest'):
                check_binding(changed, lean)


if __name__ == '__main__':
    unittest.main()
