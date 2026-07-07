"""Run POO Flow runtime benchmark suites as project modules."""

from __future__ import annotations

import argparse
import sys

from . import composition
from . import langgraph_alignment


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run POO Flow Python runtime benchmark suites."
    )
    parser.add_argument(
        "suite",
        choices=("langgraph-alignment", "composition"),
        help="Benchmark suite to run.",
    )
    parser.add_argument("--iterations", type=int, default=100)
    parser.add_argument("--fanout", type=int, default=16)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    if args.suite == "langgraph-alignment":
        benchmarks = langgraph_alignment.run_benchmarks(
            iterations=args.iterations,
            fanout=args.fanout,
        )
    else:
        benchmarks = composition.run_composition_benchmarks(
            iterations=args.iterations,
            fanout=args.fanout,
        )
    sys.stdout.write("\n".join(benchmark.receipt() for benchmark in benchmarks))
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
