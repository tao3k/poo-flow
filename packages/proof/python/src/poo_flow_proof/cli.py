"""Command-line interface for typed Lean artifact generation."""

from __future__ import annotations

import argparse
from pathlib import Path

from .lean_emit import manifest_to_lean
from .model import canonical_loop_engine_manifest


def _emit_lean(args: argparse.Namespace) -> int:
    output = manifest_to_lean(canonical_loop_engine_manifest(), args.module_name)
    if args.output:
        output_path = Path(args.output)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(output, encoding="utf-8")
    else:
        print(output, end="")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="poo-flow-proof")
    subparsers = parser.add_subparsers(dest="command", required=True)

    emit_lean = subparsers.add_parser("emit-lean")
    emit_lean.add_argument("--module-name", default="PooFlowProof.Generated.LoopEngine")
    emit_lean.add_argument("--output")
    emit_lean.set_defaults(func=_emit_lean)
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
