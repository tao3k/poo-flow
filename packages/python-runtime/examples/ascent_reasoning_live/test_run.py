# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

"""Offline checks for the interactive model boundary."""

from __future__ import annotations

import importlib.util
import os
import re
import unittest
from pathlib import Path
from types import SimpleNamespace

spec = importlib.util.spec_from_file_location("reasoning_live", Path(__file__).with_name("run.py"))
assert spec and spec.loader
live = importlib.util.module_from_spec(spec)
spec.loader.exec_module(live)


class BoundaryTest(unittest.TestCase):
    def test_accepts_only_one_inert_candidate_datum(self) -> None:
        valid = "(candidate (relation path 2) (query path ?x ?y) (limits 8 8 8))"
        self.assertEqual(live.candidate_text(valid), valid)
        self.assertEqual(live.candidate_text("```\n" + valid + "\n```"), valid)
        for unsafe in ("#.(delete-file \"x\")", valid + " (second)",
                       valid.replace("path", "#.(run)"), "before\n" + valid,
                       "(candidate (relation path 2)"):
            self.assertIsNone(live.candidate_text(unsafe))

    def test_native_receipt_tracks_withdrawn_snapshot(self) -> None:
        ascent_root = os.environ.get("ASCENT_TEST_ROOT")
        if not ascent_root:
            self.skipTest("ASCENT_TEST_ROOT is required for the native integration check")
        candidate = (
            "(candidate (relation path 2) "
            "(rule (path ?x ?y) (edge ?x ?y)) "
            "(rule (path ?x ?z) (edge ?x ?y) (path ?y ?z)) "
            "(query path ?x ?y) (limits 16 64 64))"
        )
        checker = live.SchemeChecker(Path(ascent_root))
        try:
            rejected = checker.attempt(candidate.replace(
                "(relation path 2)", "(relation edge 2) (relation path 2)"))
            receipt = checker.attempt(candidate)
            repeated = checker.attempt(candidate)
        finally:
            checker.close()
        self.assertEqual(rejected["status"], "rejected")
        self.assertIn("duplicate-relation", rejected["diagnostics"])
        self.assertEqual(repeated, receipt)
        self.assertEqual(receipt["status"], "complete")
        self.assertEqual(receipt["bound"], "#t")
        self.assertEqual(receipt["diagnostics"], "()")
        self.assertEqual(set(re.findall(r"\(\d+ \d+\)", receipt["rows"])),
                         {"(0 1)", "(0 2)", "(1 2)"})
        self.assertEqual(receipt["after-status"], "complete")
        self.assertEqual(receipt["after-rows"], "((0 1))")
        self.assertEqual(receipt["after-bound"], "#t")

    def test_runtime_graph_uses_sdk_without_injecting_a_prompt(self) -> None:
        calls: list[dict] = []

        def create(**kwargs: object) -> list[SimpleNamespace]:
            calls.append(kwargs)
            response = SimpleNamespace(status="completed", id="test-response",
                                       usage=None, incomplete_details=None)
            return [SimpleNamespace(type="response.output_text.delta", delta="Hello"),
                    SimpleNamespace(type="response.completed", response=response)]

        client = SimpleNamespace(responses=SimpleNamespace(create=create))
        graph = live.build_graph(client, "deepseek-flash")
        messages = [{"role": "user", "content": "hello"}]
        state, trace = graph.invoke_with_trace({"messages": messages})
        self.assertEqual(trace, ["model", "candidate"])
        self.assertEqual(state["output"], "Hello")
        self.assertIsNone(state["receipt"])
        self.assertEqual(calls[0]["input"], messages)
        self.assertNotIn("instructions", calls[0])
        self.assertTrue(calls[0]["stream"])


if __name__ == "__main__":
    unittest.main()
