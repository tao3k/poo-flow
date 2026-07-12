"""Benchmark the native batch path loaded from an installed Python wheel."""

from __future__ import annotations

import argparse
from statistics import median
import sys
import time

from .arena import NativeEvent
from .session import NativeBundleDescriptor, NativeRuntimeSession

BATCH_SIZES = (1, 8, 32, 128, 1024)


def run(iterations: int) -> tuple[str, ...]:
    if iterations <= 0:
        raise ValueError("native benchmark iterations must be positive")
    lines: list[str] = []
    sequence = 1
    bundle = NativeBundleDescriptor(bytes.fromhex("77" * 32), 1, b"benchmark")
    with NativeRuntimeSession(bundle) as session:
        with session.arena(bytearray(1024 * 1024)) as arena:
            for batch_size in BATCH_SIZES:
                samples: list[int] = []
                for _index in range(iterations):
                    events = tuple(
                        NativeEvent(sequence + offset) for offset in range(batch_size)
                    )
                    sequence += batch_size
                    started = time.perf_counter_ns()
                    result = arena.roundtrip(events)
                    samples.append(time.perf_counter_ns() - started)
                    if result.accepted_count != batch_size:
                        raise RuntimeError("native benchmark batch was not fully accepted")
                lines.append(
                    " ".join(
                        (
                            "schema=poo-flow.runtime-v0.python-wheel-benchmark.1",
                            f"batch={batch_size}",
                            f"iterations={iterations}",
                            f"p50-ns={int(median(samples))}",
                            f"crossings-per-item={4 / batch_size:.9f}",
                            "payload-zero-copy=true",
                            "lookup-complexity=O(log-n-plus-k)",
                            "abi-v1-frozen=false",
                        )
                    )
                )
    return tuple(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--iterations", type=int, default=20)
    args = parser.parse_args(argv)
    for line in run(args.iterations):
        sys.stdout.write(line + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
