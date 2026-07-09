"""Run POO Flow runtime benchmark suites as project modules."""

from __future__ import annotations

import argparse
import sys

from . import composition
from . import langgraph_alignment
from . import scheme_load_aot


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run POO Flow Python runtime benchmark suites."
    )
    parser.add_argument(
        "suite",
        choices=("langgraph-alignment", "composition", "scheme-load-aot"),
        help="Benchmark suite to run.",
    )
    parser.add_argument("--iterations", type=int, default=100)
    parser.add_argument("--fanout", type=int, default=16)
    parser.add_argument(
        "--source",
        default=str(scheme_load_aot.SCHEME_LOAD_AOT_DEFAULT_SOURCE),
    )
    parser.add_argument("--cwd", default=".")
    parser.add_argument("--include-interpreter", action="store_true")
    parser.add_argument("--include-artifact", action="store_true")
    parser.add_argument("--skip-fresh-process", action="store_true")
    parser.add_argument("--precompile", action="store_true")
    parser.add_argument("--preproject-artifact", action="store_true")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    if args.suite == "langgraph-alignment":
        benchmarks = langgraph_alignment.run_benchmarks(
            iterations=args.iterations,
            fanout=args.fanout,
        )
    elif args.suite == "composition":
        benchmarks = composition.run_composition_benchmarks(
            iterations=args.iterations,
            fanout=args.fanout,
        )
    else:
        benchmarks = scheme_load_aot.run_scheme_load_aot_benchmarks(
            source=args.source,
            cwd=args.cwd,
            iterations=args.iterations,
            include_interpreter=args.include_interpreter,
            include_fresh_process=not args.skip_fresh_process,
            include_artifact=args.include_artifact,
            precompile=args.precompile,
            preproject_artifact=args.preproject_artifact,
        )
    sys.stdout.write("\n".join(benchmark.receipt() for benchmark in benchmarks))
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
