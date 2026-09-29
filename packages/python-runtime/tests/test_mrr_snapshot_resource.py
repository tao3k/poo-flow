# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
#
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

"""Fail-closed receipt and POO Flow tool scope contracts; no cloud needed."""
import json
import hashlib
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

from poo_flow_runtime import RuntimeGraphPlan, RuntimeGraphEdge, RuntimeGraphConditionalEdge
from poo_flow_runtime.mrr_snapshot_resource import MrrSnapshotResource, MrrResourceError


class ResourceContracts(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.path = Path(self.directory.name)
        self.worker = self.path / "worker"
        self.worker.touch()
        self.resource = MrrSnapshotResource(self.worker, self.path / "cache", {})
        self.root = "b" + "a" * 58

    def test_agent_cannot_override_owner_scope(self):
        tool = self.resource.query_tool(root=self.root, source="plan", revision="revision")
        with patch("subprocess.run") as run:
            with self.assertRaises(MrrResourceError):
                tool.invoke({"root": self.root, "S3_ENDPOINT": "https://elsewhere"})
            run.assert_not_called()

    def test_conditional_or_dangling_graph_is_not_silently_reduced(self):
        plans = [RuntimeGraphPlan(nodes=("a",), edges=(RuntimeGraphEdge("a", "unknown"),)),
                 RuntimeGraphPlan(nodes=("a",), edges=(), conditional_edges=(
                     RuntimeGraphConditionalEdge("a", "router", {}),))]
        for plan in plans:
            with self.assertRaises(MrrResourceError):
                self.resource.publish(plan, source="plan", revision="rev")

    def test_unbound_or_malformed_receipt_is_not_a_semantic_success(self):
        for raw in (b'{}', b'{"result":{"kind":"admitted"}}', b'null', b'x' * (1024 * 1024 + 1)):
            def fake_run(*args, **kwargs):
                kwargs["stdout"].write(raw)
                return subprocess.CompletedProcess(args, 0)
            with patch("subprocess.run", side_effect=fake_run):
                with self.assertRaises(MrrResourceError):
                    self.resource.query(root=self.root, source="plan", revision="rev")

    def test_timeout_or_failed_process_never_returns_receipt(self):
        with patch("subprocess.run", side_effect=subprocess.TimeoutExpired("worker", 1)):
            with self.assertRaises(MrrResourceError):
                self.resource.query(root=self.root, source="plan", revision="rev")
        with patch("subprocess.run", return_value=subprocess.CompletedProcess("worker", 1)):
            with self.assertRaises(MrrResourceError):
                self.resource.query(root=self.root, source="plan", revision="rev")

    def test_protected_receipt_is_distinct_from_remote_publication(self):
        plan = RuntimeGraphPlan(nodes=("compile", "test"), edges=(RuntimeGraphEdge("compile", "test"),))

        def fake_run(*args, **kwargs):
            request = json.loads(kwargs["input"])
            receipt = {"profile": request["profile"], "producer": "mrr-data-poo-flow",
                       "request_sha256": hashlib.sha256(kwargs["input"]).hexdigest(),
                       "source": request["source"], "revision": request["revision"],
                       "root": self.root, "generation": "generation", "result": {"kind": "protected"},
                       "remote_operations": 0, "charged_bytes": 0, "elapsed_micros": 1}
            kwargs["stdout"].write(json.dumps(receipt).encode())
            return subprocess.CompletedProcess(args, 0)

        with patch("subprocess.run", side_effect=fake_run):
            protected = self.resource.protect(plan, source="plan", revision="rev")
            self.assertEqual(protected.root, self.root)
            with self.assertRaises(MrrResourceError):
                self.resource.publish(plan, source="plan", revision="rev")

    def test_pending_roots_read_durable_records(self):
        self.resource.local.mkdir()
        record = {"profile": "poo-flow.static-edges.v1", "root": self.root,
                  "source": "plan", "revision": "rev", "generation": "generation",
                  "protected_until": 10, "state": "pending", "blocks": [self.root]}
        path = self.resource.local / f"snapshot-{self.root}.json"
        path.write_text(json.dumps(record))
        self.assertEqual(self.resource.pending_roots(), (self.root,))
        record["state"] = "synced"
        path.write_text(json.dumps(record))
        self.assertEqual(self.resource.pending_roots(), ())
        record["root"] = "other"
        path.write_text(json.dumps(record))
        with self.assertRaises(MrrResourceError):
            self.resource.pending_roots()

    def test_sync_pending_accepts_only_bounded_summary(self):
        valid = {"profile": "poo-flow.static-edges.v1", "attempted": 1,
                 "published": 1, "failed_roots": []}
        for summary, accepted in ((valid, True), ({**valid, "published": 2}, False),
                                  ({**valid, "failed_roots": [self.root]}, False),
                                  ({**valid, "unexpected": 1}, False)):
            def fake_run(*args, **kwargs):
                self.assertEqual(args[0][-1], "--sync-pending")
                kwargs["stdout"].write(json.dumps(summary).encode())
                return subprocess.CompletedProcess(args, 0)
            with patch("subprocess.run", side_effect=fake_run):
                if accepted:
                    self.assertEqual(self.resource.sync_pending(), valid)
                else:
                    with self.assertRaises(MrrResourceError):
                        self.resource.sync_pending()


if __name__ == "__main__":
    unittest.main()
