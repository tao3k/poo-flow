from __future__ import annotations

import argparse
import asyncio
import json
from pathlib import Path
import sys
from typing import Sequence

from poo_flow_proof import axle_verify as axle_verify  # noqa: F401
from poo_flow_proof.axle_exact_closure import build_exact_axle_closure
from poo_flow_proof.axle_exact_closure import (
    DEFAULT_BASE_TIMEOUT_SECONDS,
    DEFAULT_OPERATION_TIMEOUT_SECONDS,
)
from poo_flow_proof.independent_bundle_projection import (
    build_independent_declaration_bundle,
)
from poo_flow_proof.lean_declaration_closure import (
    LeanClosureError,
    LeanDeclarationClosure,
    LeanOwnerSource,
    export_declaration_closure,
    resolve_owner_sources,
)


RECEIPT_SCHEMA_ID = "poo-flow.axle-closure-preflight.v1"


def _environment_version(environment: str) -> str | None:
    prefix = "lean-"
    if environment.startswith(prefix):
        return environment.removeprefix(prefix)
    return None


def _verify_environment(
    closure: LeanDeclarationClosure,
    environment: str,
) -> None:
    expected = _environment_version(environment)
    if expected is not None and expected != closure.lean_version:
        raise LeanClosureError(
            "axle-environment-toolchain-mismatch",
            f"{environment} != Lean {closure.lean_version}",
        )


def _verify_paths(
    provided: Sequence[Path],
    sources: Sequence[LeanOwnerSource],
) -> tuple[Path, ...]:
    expected = tuple(source.path.resolve() for source in sources)
    if not provided:
        return expected
    actual = tuple(path.resolve() for path in provided)
    if set(actual) != set(expected) or len(actual) != len(expected):
        raise LeanClosureError(
            "axle-source-set-mismatch",
            (
                f"expected={','.join(map(str, expected))};"
                f"actual={','.join(map(str, actual))}"
            ),
        )
    order = {path: index for index, path in enumerate(expected)}
    return tuple(sorted(actual, key=order.__getitem__))


def _preflight_receipt(
    closure: LeanDeclarationClosure,
    sources: Sequence[LeanOwnerSource],
    environment: str,
    operation_timeout_seconds: float,
    base_timeout_seconds: float,
) -> dict[str, object]:
    return {
        "axle_environment": environment,
        "axle_base_timeout_seconds": base_timeout_seconds,
        "axle_operation_timeout_seconds": operation_timeout_seconds,
        "closure_digest": closure.closure_digest,
        "declaration_count": len(closure.declarations),
        "owner_sources": [
            {
                "module": source.module,
                "owner_path": source.owner_path,
                "source_digest": source.source_digest,
            }
            for source in sources
        ],
        "root_declarations": list(closure.root_declarations),
        "root_module": closure.root_module,
        "schema_id": RECEIPT_SCHEMA_ID,
    }


def _observe_phase(receipt: object) -> None:
    print(
        json.dumps(
            receipt,
            ensure_ascii=False,
            separators=(",", ":"),
            sort_keys=True,
        ),
        file=sys.stderr,
        flush=True,
    )


def run(args: argparse.Namespace) -> int:
    operation_timeout_seconds = getattr(
        args,
        "axle_operation_timeout_seconds",
        DEFAULT_OPERATION_TIMEOUT_SECONDS,
    )
    base_timeout_seconds = getattr(
        args,
        "axle_base_timeout_seconds",
        DEFAULT_BASE_TIMEOUT_SECONDS,
    )
    closure = export_declaration_closure(
        lean_root=args.lean_root,
        root_module=args.root_module,
        root_declarations=tuple(args.root_declarations),
        base_imports=("Init", *tuple(args.base_imports)),
    )
    _verify_environment(closure, args.environment)
    sources = resolve_owner_sources(
        closure=closure,
        lean_root=args.lean_root,
    )
    _verify_paths(args.paths, sources)
    receipt = _preflight_receipt(
        closure,
        sources,
        args.environment,
        operation_timeout_seconds,
        base_timeout_seconds,
    )
    canonical_receipt = json.dumps(
        receipt,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    )
    if args.closure_output is not None:
        artifact = {
            "closure": closure.canonical_manifest(),
            "preflight": receipt,
        }
        args.closure_output.write_text(
            json.dumps(
                artifact,
                ensure_ascii=False,
                indent=2,
                sort_keys=True,
            )
            + "\n"
        )
    print(canonical_receipt)
    exact = asyncio.run(
        build_exact_axle_closure(
            closure=closure,
            sources=sources,
            environment=args.environment,
            operation_timeout_seconds=operation_timeout_seconds,
            base_timeout_seconds=base_timeout_seconds,
            phase_observer=_observe_phase,
        )
    )
    independent_bundle = build_independent_declaration_bundle(
        closure=closure,
        exact=exact,
        sources=sources,
        lean_root=args.lean_root,
    )
    artifact = {
        "closure": closure.canonical_manifest(),
        "preflight": receipt,
        "exact_bundle": exact.canonical_manifest(),
        "exact_bundle_digest": exact.bundle_digest,
        "independent_declaration_bundle": independent_bundle.canonical_manifest(),
        "independent_declaration_bundle_digest": independent_bundle.bundle_digest,
    }
    if args.closure_output is not None:
        args.closure_output.write_text(
            json.dumps(artifact, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
        )
    print(
        json.dumps(
            {
                "schema_id": exact.schema_id,
                "bundle_digest": exact.bundle_digest,
                "canonical_source_digest": exact.canonical_source_digest,
                "declaration_count": len(exact.declarations),
                "root_declarations": list(exact.root_declarations),
                "independent_declaration_bundle_digest": (
                    independent_bundle.bundle_digest
                ),
                "verification": exact.verification,
            },
            ensure_ascii=False,
            separators=(",", ":"),
            sort_keys=True,
        )
    )
    return 0
