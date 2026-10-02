# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

"""Transport inert candidates to ASCENT's qualified support corpus."""

from __future__ import annotations

import os
import subprocess
from pathlib import Path

from ..ascent.candidate import candidate_text

COLUMNS = ("generation", "status", "rows", "finite", "founded", "policy", "diagnostics")


def parse_observation(raw: str, initial: bool = False) -> list[dict[str, str]]:
    lines = raw.splitlines()
    if not lines or lines.pop() != "END":
        raise RuntimeError("ASCENT support observation lacks completion marker")
    records = [dict(zip(COLUMNS, line.split("\t"), strict=True)) for line in lines]
    expected = ["0"] if initial else ["0", "1", "2", "3", "stale"]
    if [row["generation"] for row in records] != expected:
        raise RuntimeError("ASCENT support observation has unexpected source states")
    return records


def observe(root: Path, gerbil_path: Path, proposal: str | None = None,
            initial: bool = False) -> str:
    command = ["just", "support-study-reference"]
    if proposal is not None:
        if candidate_text(proposal) != proposal.strip():
            raise ValueError("native input must be one bounded inert candidate")
        command = ["just", "support-study-candidate", "initial" if initial else "evaluate"]
    env = os.environ.copy()
    env.pop("DEEPSEEK_API_KEY", None)
    env["GERBIL_PATH"] = str(gerbil_path)
    env["GERBIL_LOADPATH"] = str(root)
    result = subprocess.run(command, input=proposal or "", cwd=root, env=env,
                            text=True, capture_output=True, timeout=125, check=True)
    parse_observation(result.stdout, initial)
    return result.stdout


def score(raw: str, reference: str) -> dict:
    observed, expected = parse_observation(raw), parse_observation(reference)
    states = [{"generation": row["generation"], "complete": row["status"] == "complete",
               "finite_valid": row["finite"] == "valid", "founded_valid": row["founded"] == "valid",
               "task_shape": row["policy"] == "task-shape", "output_matches": row["rows"] == target["rows"]}
              for row, target in zip(observed[:4], expected[:4], strict=True)]
    matches = [all(value for name, value in state.items() if name != "generation") for state in states]
    applicable = all(states[0][name] for name in ("complete", "finite_valid", "founded_valid"))
    stale = observed[-1]["finite"] == observed[-1]["founded"] == "invalid"
    return {"states": states, "matched_states": matches, "stale_invalid": stale,
            "stale_applicable": applicable, "correct": all(matches) and applicable and stale}
