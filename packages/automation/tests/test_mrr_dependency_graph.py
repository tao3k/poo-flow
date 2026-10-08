# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Reject consumer pin drift and a second producer in the actual lock."""
import importlib.util
from pathlib import Path
import shutil
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[1] / 'check_mrr_dependency_graph.py'
spec = importlib.util.spec_from_file_location('mrr_graph', SOURCE)
graph = importlib.util.module_from_spec(spec)
spec.loader.exec_module(graph)


class GraphTest(unittest.TestCase):
    def copy_graph(self, root):
        for directory in ('bindings/rust-runtime', 'bindings/rust-runtime/qualification/physical-roundtrip'):
            target = root / directory
            target.mkdir(parents=True)
            for name in ('Cargo.toml', 'Cargo.lock'):
                shutil.copyfile(graph.ROOT / directory / name, target / name)

    def test_current_manifests_and_locks_agree(self):
        graph.check()

    def test_divergent_consumer_revision_rejects(self):
        with tempfile.TemporaryDirectory() as work:
            root = Path(work)
            self.copy_graph(root)
            path = root / 'bindings/rust-runtime/qualification/physical-roundtrip/Cargo.toml'
            mrr, _ = graph.check(root)
            path.write_text(path.read_text().replace(mrr, '0' * 40, 1))
            with self.assertRaisesRegex(ValueError, 'divergent'):
                graph.check(root)

    def test_parent_publication_pin_cannot_hide_behind_physical_owner(self):
        with tempfile.TemporaryDirectory() as work:
            root = Path(work)
            self.copy_graph(root)
            path = root / 'bindings/rust-runtime/Cargo.toml'
            _, data = graph.check(root)
            path.write_text(path.read_text().replace(data, '0' * 40, 1))
            with self.assertRaisesRegex(ValueError, 'divergent'):
                graph.check(root)

    def test_stale_locked_producer_rejects(self):
        with tempfile.TemporaryDirectory() as work:
            root = Path(work)
            self.copy_graph(root)
            path = root / 'bindings/rust-runtime/Cargo.lock'
            mrr, _ = graph.check(root)
            path.write_text(path.read_text().replace(mrr, '0' * 40, 1))
            with self.assertRaisesRegex(ValueError, 'stale or duplicate'):
                graph.check(root)

    def test_implicit_head_cannot_hide_a_second_producer(self):
        with tempfile.TemporaryDirectory() as work:
            root = Path(work)
            self.copy_graph(root)
            path = root / 'bindings/rust-runtime/Cargo.lock'
            with path.open('a') as output:
                output.write('\n[[package]]\nname = "mrr-identity"\nversion = "0.1.0"\n'
                             f'source = "git+{graph.MRR}#{"0" * 40}"\n')
            with self.assertRaisesRegex(ValueError, 'stale or duplicate'):
                graph.check(root)
