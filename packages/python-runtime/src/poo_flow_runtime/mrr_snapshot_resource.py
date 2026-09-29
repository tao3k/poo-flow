# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
#
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

"""MRR snapshot resource for POO Flow's existing RuntimeGraphTool boundary.

The caller supplies a projected RuntimeGraphPlan and execution configuration.
This adapter neither schedules work nor admits semantic query results itself.
"""
from __future__ import annotations

from dataclasses import dataclass
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile
from typing import Mapping

from ._runtime_graph_types import RuntimeGraphPlan
from .tools import RuntimeGraphTool

PROFILE = "poo-flow.static-edges.v1"
MAX_BYTES = 1024 * 1024
HEX = re.compile(r"[0-9a-f]{64}\Z")
CID = re.compile(r"b[a-z2-7]{58}\Z")


class MrrResourceError(RuntimeError):
    """No accepted result is available for this invocation."""


@dataclass(frozen=True)
class MrrReceipt:
    root: str
    generation: str
    source: str
    revision: str
    rows: tuple[tuple[str, str], ...] | None
    admission_digest: str | None
    remote_operations: int
    charged_bytes: int
    elapsed_micros: int


class MrrSnapshotResource:
    """One trusted worker and durable local store; runtime configuration is local."""

    def __init__(self, executable: Path, local: Path, environment: Mapping[str, str], *, timeout: float = 40):
        if timeout <= 0:
            raise ValueError("positive worker timeout required")
        self.executable = executable.resolve(strict=True)
        self.local = local.resolve()
        self.environment = dict(environment, MRR_LOCAL_DIR=str(self.local))
        self.timeout = timeout

    def _edges(self, plan: RuntimeGraphPlan) -> list[list[str]]:
        if not isinstance(plan, RuntimeGraphPlan):
            raise TypeError("an existing POO Flow RuntimeGraphPlan projection is required")
        if plan.conditional_edges:
            raise MrrResourceError("conditional routes are outside the static-edge profile")
        if len(plan.edges) > 1024:
            raise MrrResourceError("edge budget exceeded")
        nodes = set(plan.nodes) | {"__start__", "__end__"}
        edges = [[edge.source, edge.target] for edge in plan.edges]
        if any(node not in nodes for edge in edges for node in edge):
            raise MrrResourceError("edge references an undeclared runtime node")
        return edges

    def protect(self, plan: RuntimeGraphPlan, *, source: str, revision: str) -> MrrReceipt:
        """Durably protect a complete snapshot without requiring S3 access."""
        return self._invoke(source, revision, {"kind": "protect", "edges": self._edges(plan)})

    def publish(self, plan: RuntimeGraphPlan, *, source: str, revision: str) -> MrrReceipt:
        """Protect locally, then require remote root acknowledgement."""
        return self._invoke(source, revision, {"kind": "publish", "edges": self._edges(plan)})

    def sync(self, *, root: str, source: str, revision: str) -> MrrReceipt:
        """Publish a protected root and its children after connectivity returns."""
        if not isinstance(root, str) or not CID.fullmatch(root):
            raise MrrResourceError("canonical snapshot root required")
        return self._invoke(source, revision, {"kind": "sync", "root": root})

    def pending_roots(self) -> tuple[str, ...]:
        """Discover local outbox roots after a process restart."""
        if not self.local.is_dir():
            return ()
        roots = []
        for record in self.local.glob("snapshot-*.json"):
            root = record.name.removeprefix("snapshot-").removesuffix(".json")
            if not CID.fullmatch(root) or not record.is_file() or record.is_symlink() or record.stat().st_size > 4096:
                raise MrrResourceError("invalid local protection record")
            try:
                data = json.loads(record.read_bytes())
                if (set(data) != {"profile", "root", "source", "revision", "generation",
                                  "protected_until", "state", "blocks"}
                        or data["profile"] != PROFILE or data["root"] != root
                        or not isinstance(data["source"], str) or not data["source"]
                        or not isinstance(data["revision"], str) or not data["revision"]
                        or not isinstance(data["generation"], str) or not data["generation"]
                        or type(data["protected_until"]) is not int or data["protected_until"] < 0
                        or data["state"] not in ("pending", "synced")
                        or not isinstance(data["blocks"], list) or not 1 <= len(data["blocks"]) <= 8
                        or any(not isinstance(block, str) or not CID.fullmatch(block)
                               for block in data["blocks"])
                        or len(set(data["blocks"])) != len(data["blocks"])
                        or root not in data["blocks"]):
                    raise ValueError("record identity")
            except (ValueError, TypeError) as error:
                raise MrrResourceError("invalid local protection record") from error
            if data["state"] == "pending":
                roots.append(root)
        return tuple(sorted(roots))

    def sync_pending(self) -> dict[str, object]:
        """Replay one bounded batch from the durable outbox using Tokio."""
        with tempfile.TemporaryFile() as output, tempfile.TemporaryFile() as errors:
            try:
                completed = subprocess.run([str(self.executable), "--sync-pending"], input=b"",
                                           stdout=output, stderr=errors, env=self.environment,
                                           timeout=self.timeout, check=False)
            except subprocess.TimeoutExpired as error:
                raise MrrResourceError("MRR sync deadline exceeded") from error
            if completed.returncode:
                errors.seek(0)
                raise MrrResourceError(errors.read(4096).decode(errors="replace"))
            output.seek(0)
            raw = output.read(MAX_BYTES + 1)
        if len(raw) > MAX_BYTES:
            raise MrrResourceError("sync receipt exceeds 1 MiB")
        try:
            summary = json.loads(raw)
            if (not isinstance(summary, dict)
                    or set(summary) != {"profile", "attempted", "published", "failed_roots"}
                    or summary["profile"] != PROFILE
                    or any(type(summary[key]) is not int or summary[key] < 0
                           for key in ("attempted", "published"))
                    or summary["attempted"] > 128
                    or summary["published"] > summary["attempted"]
                    or not isinstance(summary["failed_roots"], list)
                    or len(summary["failed_roots"]) + summary["published"] != summary["attempted"]
                    or any(not isinstance(root, str) or not CID.fullmatch(root)
                           for root in summary["failed_roots"])
                    or len(set(summary["failed_roots"])) != len(summary["failed_roots"])):
                raise ValueError("sync summary")
            return summary
        except (ValueError, TypeError, KeyError) as error:
            raise MrrResourceError("invalid sync receipt") from error

    def query(self, *, root: str, source: str, revision: str) -> MrrReceipt:
        if not isinstance(root, str) or not CID.fullmatch(root):
            raise MrrResourceError("canonical snapshot root required")
        return self._invoke(source, revision, {"kind": "query", "root": root})

    def query_tool(self, *, root: str, source: str, revision: str) -> RuntimeGraphTool:
        # Scope is fixed by the runtime owner. Agent arguments cannot override it
        # or change credentials, cache paths, budgets or the trusted executable.
        def invoke(arguments):
            if arguments:
                raise MrrResourceError("the snapshot query tool accepts no scope overrides")
            return self.query(root=root, source=source, revision=revision)
        return RuntimeGraphTool("mrr_static_edges", invoke)

    def _invoke(self, source, revision, operation):
        request = {"profile": PROFILE, "source": source, "revision": revision, "operation": operation}
        encoded = json.dumps(request, ensure_ascii=False, separators=(",", ":")).encode()
        if len(encoded) > MAX_BYTES:
            raise MrrResourceError("request exceeds 1 MiB")
        # File-backed output avoids an unbounded communicate() allocation. The
        # trusted worker is itself bounded; only one receipt may be returned.
        with tempfile.TemporaryFile() as output, tempfile.TemporaryFile() as errors:
            try:
                completed = subprocess.run([str(self.executable)], input=encoded, stdout=output,
                                           stderr=errors, env=self.environment, timeout=self.timeout,
                                           check=False)
            except subprocess.TimeoutExpired as error:
                raise MrrResourceError("MRR worker deadline exceeded; no receipt accepted") from error
            if completed.returncode:
                errors.seek(0)
                raise MrrResourceError(errors.read(4096).decode(errors="replace"))
            output.seek(0)
            raw = output.read(MAX_BYTES + 1)
        if len(raw) > MAX_BYTES:
            raise MrrResourceError("worker receipt exceeds 1 MiB")
        try:
            receipt = json.loads(raw)
            if not isinstance(receipt, dict) or set(receipt) != {
                "profile", "producer", "request_sha256", "source", "revision", "root",
                "generation", "result", "remote_operations", "charged_bytes", "elapsed_micros"
            }:
                raise ValueError("receipt fields")
            for field, expected in (("profile", PROFILE), ("producer", "mrr-data-poo-flow"),
                                    ("source", source), ("revision", revision),
                                    ("request_sha256", hashlib.sha256(encoded).hexdigest())):
                if receipt[field] != expected:
                    raise ValueError("receipt binding mismatch: " + field)
            if (not CID.fullmatch(receipt["root"]) or not isinstance(receipt["generation"], str)
                    or not receipt["generation"] or len(receipt["generation"]) > 256):
                raise ValueError("receipt identity")
            for key in ("remote_operations", "charged_bytes", "elapsed_micros"):
                if type(receipt[key]) is not int or receipt[key] < 0:
                    raise ValueError("invalid counter")
            result = receipt["result"]
            rows, digest = None, None
            if operation["kind"] in ("publish", "protect", "sync"):
                expected = "protected" if operation["kind"] == "protect" else "published"
                if result != {"kind": expected}:
                    raise ValueError("snapshot receipt mismatch")
                if operation["kind"] == "sync" and receipt["root"] != operation["root"]:
                    raise ValueError("synchronization root mismatch")
            else:
                if receipt["root"] != operation["root"] or set(result) != {"kind", "rows", "admission_digest"}:
                    raise ValueError("query receipt binding mismatch")
                if result["kind"] != "admitted" or not HEX.fullmatch(result["admission_digest"]):
                    raise ValueError("MRR admission receipt required")
                if not isinstance(result["rows"], list) or len(result["rows"]) > 1024:
                    raise ValueError("row budget")
                if any(not isinstance(row, list) or len(row) != 2 or
                       any(not isinstance(cell, str) or not cell or len(cell) > 256 for cell in row)
                       for row in result["rows"]):
                    raise ValueError("query result shape")
                rows = tuple(tuple(row) for row in result["rows"])
                digest = result["admission_digest"]
            return MrrReceipt(receipt["root"], receipt["generation"], source, revision,
                              rows, digest, receipt["remote_operations"], receipt["charged_bytes"],
                              receipt["elapsed_micros"])
        except (ValueError, KeyError, TypeError) as error:
            raise MrrResourceError("invalid MRR worker receipt") from error
