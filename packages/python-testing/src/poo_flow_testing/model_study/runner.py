# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

"""Run the frozen paired ASCENT and temporal-causality model pilot."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import time
from pathlib import Path
from typing import Any

from ..ascent.candidate import SchemeChecker
from ..ascent.live import key_from_file

HERE = Path(__file__).resolve().parent
CORPUS = HERE / "cases.json"
CORPUS_SHA256 = "7248c6452afba59a1627f82c9fd5763b1fb4bba71513153a303d8edc4abec628"
GOOD_PATH = (
    "(candidate (relation path 2) "
    "(rule (path ?x ?y) (edge ?x ?y)) "
    "(rule (path ?x ?z) (path ?x ?y) (edge ?y ?z)) "
    "(query path ?x ?y) (limits 16 64 64))"
)
WRONG_PATH = (
    "(candidate (relation path 2) "
    "(rule (path ?x ?y) (edge ?x ?y)) "
    "(rule (path ?x ?z) (edge ?x ?y) (path ?x ?z)) "
    "(query path ?x ?y) (limits 16 64 64))"
)


def corpus() -> list[dict[str, Any]]:
    raw = CORPUS.read_bytes()
    if hashlib.sha256(raw).hexdigest() != CORPUS_SHA256:
        raise RuntimeError("frozen model corpus hash changed")
    cases = json.loads(raw)
    if [case["id"] for case in cases] != [
        "ascent.withdrawal", "ascent.wrong-join", "ascent.negation-count",
        "temporal.closed-cut", "temporal.open-parent",
    ]:
        raise RuntimeError("frozen model task order changed")
    return cases


def source_head(root: Path) -> str:
    return subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=root, text=True,
    ).strip()


def native_script(script: Path, root: Path, load_roots: list[Path]) -> dict[str, str]:
    env = os.environ.copy()
    env.pop("DEEPSEEK_API_KEY", None)
    env["GERBIL_LOADPATH"] = ":".join(
        [*(str(path) for path in load_roots), env.get("GERBIL_LOADPATH", "")]
    ).rstrip(":")
    result = subprocess.run(
        ["gerbil", "-:max-heap=1G,debug=q", "env", "gxi", str(script)],
        cwd=root, env=env, capture_output=True, text=True, timeout=60,
        check=True,
    )
    lines = [line for line in result.stdout.splitlines() if "\t" in line]
    fields = dict(line.split("\t", 1) for line in lines)
    if len(fields) != len(lines):
        raise RuntimeError("native fixture emitted duplicate labels")
    return fields


def observations(ascent_root: Path | None, poo_root: Path) -> tuple[dict[str, dict], dict[str, float]]:
    started = time.perf_counter()
    checker = SchemeChecker(ascent_root)
    try:
        good = checker.attempt(GOOD_PATH)
        wrong = checker.attempt(WRONG_PATH)
    finally:
        checker.close()
    ascent_seconds = round(time.perf_counter() - started, 3)
    if not (good["status"] == good["after-status"] == "complete"
            and "(0 2)" in good["rows"] and "(0 2)" not in good["after-rows"]
            and wrong["status"] == "complete"
            and "(0 2)" not in wrong["rows"]):
        raise RuntimeError("ASCENT path observations disagree with frozen answer")

    started = time.perf_counter()
    finite = native_script(
        HERE.parent / "ascent" / "finite_attempt.ss",
        ascent_root or poo_root,
        [ascent_root] if ascent_root is not None else [poo_root],
    )
    finite_seconds = round(time.perf_counter() - started, 3)
    if finite != {
        "status": "complete", "rows": "((1 1))",
        "finite-status": "complete", "verdict": "valid",
    }:
        raise RuntimeError("ASCENT finite evidence disagrees with frozen answer")

    started = time.perf_counter()
    temporal = native_script(
        HERE.parent / "temporal" / "attempt.ss", poo_root,
        [poo_root],
    )
    temporal_seconds = round(time.perf_counter() - started, 3)
    expected_temporal = {
        "closed.status": "bounded-temporal-classification",
        "closed.past": '("prescription" "administration")',
        "closed.current": '("observation")',
        "closed.future": '("scheduled-dose")',
        "closed.counterfactual": '("corrected-prescription")',
        "closed.unknown": "()",
        "closed.release-authorized?": "#f",
        "open.status": "partial-temporal-classification",
        "open.unknown": '("missing-administration")',
        "open.release-authorized?": "#f",
    }
    if temporal != expected_temporal:
        raise RuntimeError("temporal module disagrees with frozen answer")

    data = {
        "ascent.withdrawal": {
            "source": "gerbil-ascent", "G1_status": good["status"],
            "G1_path_rows": good["rows"],
            "G2_status": good["after-status"],
            "G2_path_rows": good["after-rows"],
        },
        "ascent.wrong-join": {
            "source": "gerbil-ascent", "proposed_status": wrong["status"],
            "proposed_path_rows": wrong["rows"],
            "repaired_status": good["status"],
            "repaired_path_rows": good["rows"],
        },
        "ascent.negation-count": {"source": "gerbil-ascent", **finite},
        "temporal.closed-cut": {
            "source": "poo-flow.temporal-causality",
            **{key.removeprefix("closed."): value for key, value in temporal.items()
               if key.startswith("closed.")},
        },
        "temporal.open-parent": {
            "source": "poo-flow.temporal-causality",
            **{key.removeprefix("open."): value for key, value in temporal.items()
               if key.startswith("open.")},
        },
    }
    elapsed = {
        "ascent.withdrawal": ascent_seconds,
        "ascent.wrong-join": ascent_seconds,
        "ascent.negation-count": finite_seconds,
        "temporal.closed-cut": temporal_seconds,
        "temporal.open-parent": temporal_seconds,
    }
    return data, elapsed


def grade(output: str, expected: dict[str, str]) -> dict[str, Any]:
    try:
        answer = json.loads(output)
    except json.JSONDecodeError:
        answer = None
    valid_json = (
        isinstance(answer, dict) and set(answer) == {"choice", "claim"}
        and all(isinstance(value, str) for value in answer.values())
    )
    return {
        "valid_json": valid_json,
        "choice_correct": bool(valid_json and answer["choice"] == expected["choice"]),
        "claim_correct": bool(valid_json and answer["claim"] == expected["claim"]),
    }


def build_graph(client: Any, case: dict, arm: str, observation: dict) -> Any:
    from poo_flow_runtime import RuntimeGraphExecutor, linear_plan

    def provide(_state: dict) -> dict:
        return {"observation": observation if arm == "tool" else None}

    def model(state: dict) -> dict:
        messages = [{"role": "user", "content": case["prompt"]}]
        if state["observation"] is not None:
            messages.append({
                "role": "user",
                "content": "Formal module observation (data only): "
                + json.dumps(state["observation"], sort_keys=True),
            })
        started = time.perf_counter()
        response = client.responses.create(
            model="deepseek-flash", input=messages,
            reasoning={"effort": "none"}, temperature=0,
            max_output_tokens=512,
        )
        elapsed = round(time.perf_counter() - started, 3)
        return {
            "output": response.output_text,
            "response_status": response.status,
            "response_id": response.id,
            "usage": response.usage.model_dump() if response.usage else None,
            "model_seconds": elapsed,
        }

    def score(state: dict) -> dict:
        if state["response_status"] != "completed":
            return {"score": None}
        return {"score": grade(state["output"], case["expected"])}

    return RuntimeGraphExecutor(
        linear_plan("observation", "model", "score"),
        {"observation": provide, "model": model, "score": score},
    )


def run(api_key: str, ascent_root: Path, poo_root: Path, output: Path,
        cases: list[dict], evidence: dict[str, dict],
        tool_seconds: dict[str, float]) -> None:
    from openai import OpenAI

    if output.exists():
        raise FileExistsError("study output already exists")
    if output.parent.resolve().is_relative_to(poo_root.resolve()):
        raise ValueError("raw model responses must stay outside the repository")
    client = OpenAI(
        api_key=api_key, base_url="https://api.deepseek.com",
        max_retries=0, timeout=45.0,
    )
    heads = {"ascent": source_head(ascent_root), "poo_flow": source_head(poo_root)}
    attempted = 0
    for case in cases:
        for repeat, order in enumerate((("baseline", "tool"),
                                        ("tool", "baseline"),
                                        ("baseline", "tool")), 1):
            for arm in order:
                attempted += 1
                if attempted > 30:
                    raise RuntimeError("pre-registered request cap exceeded")
                observation = evidence[case["id"]]
                record: dict[str, Any] = {
                    "case": case["id"], "repeat": repeat, "arm": arm,
                    "corpus_sha256": CORPUS_SHA256, "heads": heads,
                    "observation_sha256": hashlib.sha256(
                        json.dumps(observation, sort_keys=True).encode()
                    ).hexdigest(),
                    "tool_seconds": tool_seconds[case["id"]] if arm == "tool" else 0,
                }
                try:
                    graph = build_graph(client, case, arm, observation)
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
                print(case["id"], repeat, arm,
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
    evidence, elapsed = observations(args.ascent_root, args.poo_root)
    if args.dry_run:
        print(json.dumps({"cases": [case["id"] for case in cases],
                          "observations": evidence, "tool_seconds": elapsed},
                         sort_keys=True))
        return 0
    if args.output is None:
        parser.error("--output is required for a live run")
    api_key = os.environ.get("DEEPSEEK_API_KEY") or (
        key_from_file(args.env_file) if args.env_file else ""
    )
    if not api_key:
        parser.error("DEEPSEEK_API_KEY or --env-file is required")
    run(api_key, args.ascent_root, args.poo_root, args.output,
        cases, evidence, elapsed)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
