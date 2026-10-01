# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

"""Compare the frozen v1 and typed v2 module observations."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
from typing import Any

from ..ascent.live import key_from_file
from .runner import build_graph, corpus, observations, source_head, CORPUS_SHA256


def typed_observation(case_id: str, old: dict[str, Any]) -> dict[str, Any]:
    typed = dict(old)
    if case_id.startswith("ascent."):
        typed["evidence_scope"] = "candidate_on_named_finite_snapshot"
        typed["intent_verified"] = False
    elif case_id.startswith("temporal."):
        if typed.pop("release-authorized?") != "#f":
            raise RuntimeError("native release field changed from frozen fixture")
        typed["release_authorized"] = False
        typed["causation_proven"] = False
        typed["evidence_scope"] = "temporal_classification_only"
        if case_id == "temporal.open-parent":
            typed["absence_proven"] = False
    else:
        raise RuntimeError("unknown frozen task")
    return typed


def run(api_key: str, ascent_root: Path, poo_root: Path, output: Path,
        cases: list[dict], old: dict[str, dict], tool_seconds: dict[str, float]) -> None:
    from openai import OpenAI

    if output.exists():
        raise FileExistsError("v2 study output already exists")
    if output.parent.resolve().is_relative_to(poo_root.resolve()):
        raise ValueError("raw model responses must stay outside the repository")
    client = OpenAI(api_key=api_key, base_url="https://api.deepseek.com",
                    max_retries=0, timeout=45.0)
    heads = {"ascent": source_head(ascent_root), "poo_flow": source_head(poo_root)}
    attempted = 0
    for case in cases:
        case_id = case["id"]
        variants = {"old": old[case_id],
                    "typed": typed_observation(case_id, old[case_id])}
        for repeat, order in enumerate((("old", "typed"),
                                        ("typed", "old"),
                                        ("old", "typed")), 1):
            for arm in order:
                attempted += 1
                if attempted > 30:
                    raise RuntimeError("pre-registered v2 request cap exceeded")
                observation = variants[arm]
                record: dict[str, Any] = {
                    "case": case_id, "repeat": repeat, "arm": arm,
                    "corpus_sha256": CORPUS_SHA256, "heads": heads,
                    "observation_sha256": hashlib.sha256(
                        json.dumps(observation, sort_keys=True).encode()
                    ).hexdigest(),
                    "tool_seconds": tool_seconds[case_id],
                }
                try:
                    graph = build_graph(client, case, "tool", observation)
                    result, _trace = graph.invoke_with_trace({})
                    record.update({
                        "response_status": result["response_status"],
                        "response_id": result["response_id"],
                        "output": result["output"],
                        "usage": result["usage"],
                        "model_seconds": result["model_seconds"],
                        "score": result["score"],
                    })
                except Exception as error:
                    record["error_type"] = type(error).__name__
                    record["score"] = None
                with output.open("a", encoding="utf-8") as file:
                    file.write(json.dumps(record, sort_keys=True) + "\n")
                print(case_id, repeat, arm,
                      record["score"] if record["score"] is not None
                      else record.get("error_type", record.get("response_status")),
                      flush=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ascent-root", type=Path, required=True)
    parser.add_argument("--poo-root", type=Path, required=True)
    parser.add_argument("--env-file", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    cases = corpus()
    old, tool_seconds = observations(args.ascent_root, args.poo_root)
    typed = {case["id"]: typed_observation(case["id"], old[case["id"]])
             for case in cases}
    if args.dry_run:
        print(json.dumps({"old": old, "typed": typed}, sort_keys=True))
        return 0
    if args.output is None:
        parser.error("--output is required for a live run")
    api_key = os.environ.get("DEEPSEEK_API_KEY") or (
        key_from_file(args.env_file) if args.env_file else ""
    )
    if not api_key:
        parser.error("DEEPSEEK_API_KEY or --env-file is required")
    run(api_key, args.ascent_root, args.poo_root, args.output,
        cases, old, tool_seconds)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
