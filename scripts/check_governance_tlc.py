# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
#
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

"""Run official TLC and emit an identity-bound Governance model receipt."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


SUCCESS = "Model checking completed. No error has been found."
VERSION_RE = re.compile(r"^TLC2 Version (?P<version>.+)$", re.MULTILINE)
STATES_RE = re.compile(
    r"(?P<generated>\d+) states generated, "
    r"(?P<distinct>\d+) distinct states found, "
    r"(?P<left>\d+) states left on queue\."
)
DEPTH_RE = re.compile(r"complete state graph search is (?P<depth>\d+)\.")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return f"sha256:{digest.hexdigest()}"


def parse_summary(output: str) -> dict[str, object]:
    version = VERSION_RE.search(output)
    states = STATES_RE.search(output)
    depth = DEPTH_RE.search(output)
    return {
        "completed": SUCCESS in output,
        "tlcVersion": version.group("version") if version else None,
        "statesGenerated": int(states.group("generated")) if states else None,
        "distinctStates": int(states.group("distinct")) if states else None,
        "statesLeft": int(states.group("left")) if states else None,
        "graphDepth": int(depth.group("depth")) if depth else None,
    }


def summary_admitted(returncode: int, summary: dict[str, object]) -> bool:
    return bool(
        returncode == 0
        and summary["completed"]
        and summary["tlcVersion"]
        and summary["statesGenerated"] is not None
        and summary["distinctStates"] is not None
        and summary["statesLeft"] == 0
        and summary["graphDepth"] is not None
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tlc", required=True)
    parser.add_argument("--spec", type=Path, required=True)
    parser.add_argument("--config", type=Path, required=True)
    parser.add_argument("--receipt", type=Path, required=True)
    parser.add_argument("--workers", default="1")
    args = parser.parse_args()

    spec = args.spec.resolve(strict=True)
    config = args.config.resolve(strict=True)
    if spec.parent != config.parent:
        parser.error("spec and config must share one model directory")
    executable_name = shutil.which(args.tlc)
    if executable_name is None:
        parser.error(f"TLC executable not found: {args.tlc}")
    executable = Path(executable_name).resolve(strict=True)

    with tempfile.TemporaryDirectory(prefix="poo-flow-governance-tlc-") as metadir:
        command = [
            str(executable),
            "-config",
            config.name,
            "-workers",
            args.workers,
            "-metadir",
            metadir,
            spec.stem,
        ]
        result = subprocess.run(
            command,
            cwd=spec.parent,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=False,
        )

    sys.stdout.write(result.stdout)
    summary = parse_summary(result.stdout)
    admitted = summary_admitted(result.returncode, summary)
    receipt = {
        "schema": "poo-flow.governance-tlc-receipt.v1",
        "model": spec.stem,
        "specDigest": sha256(spec),
        "configDigest": sha256(config),
        "toolExecutable": str(executable),
        "toolDigest": sha256(executable),
        "workers": args.workers,
        "exitStatus": result.returncode,
        "admitted": admitted,
        **summary,
    }
    args.receipt.parent.mkdir(parents=True, exist_ok=True)
    temporary = args.receipt.with_suffix(args.receipt.suffix + ".tmp")
    temporary.write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n")
    temporary.replace(args.receipt)
    print(json.dumps(receipt, sort_keys=True))
    return 0 if admitted else 1


if __name__ == "__main__":
    raise SystemExit(main())
