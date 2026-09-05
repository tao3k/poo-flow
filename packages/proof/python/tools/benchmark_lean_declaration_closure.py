from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
from statistics import median
import time
from typing import Mapping

from poo_flow_proof.lean_declaration_closure import (
    LeanDeclarationClosureRequest,
    export_declaration_closures,
)


SCHEMA_ID = "poo-flow.lean-declaration-closure-performance.v1"
REQUESTS = (
    LeanDeclarationClosureRequest(
        root_module="PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryCedarAuthorizationLifecycleCore",
        root_declarations=(
            "PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryCedarAuthorizationLifecycleCore.SourceBoundEffectCompletionRecoveryCedarAuthorizationEvidence.Admitted",
        ),
        proof_base_imports=("Cedar.Spec",),
    ),
    LeanDeclarationClosureRequest(
        root_module="PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryCedarAuthorizationSubjectBridgeCore",
        root_declarations=(
            "PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryCedarAuthorizationSubjectBridgeCore.SourceBoundEffectCompletionRecoveryCedarAuthorizationSubjectBridge.lifecycleAdmitted",
        ),
        proof_base_imports=("Cedar.Spec",),
    ),
)


def _sample(
    lean_root: Path,
    timeout_seconds: float,
) -> dict[str, object]:
    phases: list[Mapping[str, object]] = []
    started = time.monotonic()
    closures = export_declaration_closures(
        lean_root=lean_root,
        requests=REQUESTS,
        timeout_seconds=timeout_seconds,
        phase_observer=phases.append,
    )
    elapsed_ms = round((time.monotonic() - started) * 1000)
    cache_states = tuple(
        phase.get("cache_state") for phase in phases if phase.get("phase") == "closure-cache-read"
    )
    state = (
        "warm"
        if cache_states and all(value == "hit" for value in cache_states)
        else "cold-or-mixed"
    )
    return {
        "cache_state": state,
        "closure_digests": [closure.closure_digest for closure in closures],
        "elapsed_ms": elapsed_ms,
        "phases": phases,
    }


def _summary(samples: list[dict[str, object]]) -> dict[str, object]:
    warm_elapsed = [
        sample["elapsed_ms"]
        for sample in samples
        if sample["cache_state"] == "warm" and isinstance(sample["elapsed_ms"], int)
    ]
    sorted_warm_elapsed = sorted(warm_elapsed)
    warm_p95_ms = (
        sorted_warm_elapsed[max(0, math.ceil(0.95 * len(sorted_warm_elapsed)) - 1)]
        if sorted_warm_elapsed
        else None
    )
    return {
        "sample_count": len(samples),
        "warm_max_ms": max(warm_elapsed) if warm_elapsed else None,
        "warm_p50_ms": round(median(warm_elapsed)) if warm_elapsed else None,
        "warm_p95_ms": warm_p95_ms,
        "warm_sample_count": len(warm_elapsed),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--lean-root", type=Path, default=Path("../lean"))
    parser.add_argument("--output", type=Path)
    parser.add_argument("--runs", type=int, default=3)
    parser.add_argument("--timeout-seconds", type=float, default=30.0)
    args = parser.parse_args()
    if args.runs <= 0:
        parser.error("--runs must be positive")
    samples = [_sample(args.lean_root, args.timeout_seconds) for _ in range(args.runs)]
    receipt = {
        "requests": [
            {
                "root_declarations": list(request.root_declarations),
                "root_module": request.root_module,
            }
            for request in REQUESTS
        ],
        "samples": samples,
        "schema_id": SCHEMA_ID,
        "summary": _summary(samples),
    }
    output = (
        json.dumps(
            receipt,
            ensure_ascii=False,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )
    if args.output is None:
        print(output, end="")
    else:
        args.output.write_text(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
