# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Reject duplicate runtime ownership and cross-repository CI pin drift."""
import importlib.util
from pathlib import Path
import shutil
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[1] / 'check_mrr_dependency_graph.py'
spec = importlib.util.spec_from_file_location('mrr_owner', SOURCE)
graph = importlib.util.module_from_spec(spec)
spec.loader.exec_module(graph)


class RuntimeOwnerTest(unittest.TestCase):
    def copy_contract(self, root):
        for name in ('packages/automation/mrr-runtime.toml', '.github/workflows/ci.yml',
                     '.github/workflows/python-runtime-wheel.yml'):
            target = root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(graph.ROOT / name, target)

    def test_current_owner_and_checkout_agree(self):
        graph.check()

    def test_ci_cannot_use_another_runtime_revision(self):
        with tempfile.TemporaryDirectory() as work:
            root = Path(work)
            self.copy_contract(root)
            revision = graph.check(root)
            path = root / '.github/workflows/ci.yml'
            path.write_text(path.read_text().replace(revision, '0' * 40, 1))
            with self.assertRaisesRegex(ValueError, 'differs'):
                graph.check(root)

    def test_reintroduced_local_runtime_is_rejected(self):
        with tempfile.TemporaryDirectory() as work:
            root = Path(work)
            self.copy_contract(root)
            path = root / 'bindings/rust-runtime/Cargo.toml'
            path.parent.mkdir(parents=True)
            path.write_text('[package]\nname="duplicate-runtime"\n')
            with self.assertRaisesRegex(ValueError, 'must not own'):
                graph.check(root)
