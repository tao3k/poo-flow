"""Validate, calibrate, and dispatch burst lifecycle measurements."""

from __future__ import annotations

from collections.abc import Sequence
from functools import partial
import sys

import anyio

from ._anyio_runtime_runner import _available_cpu_count
from ._burst_lifecycle_measurement import _measure_population
from .burst_lifecycle import BurstLifecycleBenchmark, capacity_candidates


def run_burst_lifecycle_benchmarks(
    *,
    populations: Sequence[int],
    max_concurrency: int | None,
    serial_steps: int,
    parallel_fanout: int,
    parallel_steps: int,
    serial_interval_us: int,
    trace_memory: bool,
    stream_progress: bool,
) -> list[BurstLifecycleBenchmark]:
    _validate_inputs(
        populations,
        max_concurrency,
        serial_steps,
        parallel_fanout,
        parallel_steps,
        serial_interval_us,
    )
    return anyio.run(
        partial(
            _run_benchmarks,
            populations=tuple(populations),
            max_concurrency=max_concurrency,
            serial_steps=serial_steps,
            parallel_fanout=parallel_fanout,
            parallel_steps=parallel_steps,
            serial_interval_us=serial_interval_us,
            trace_memory=trace_memory,
            stream_progress=stream_progress,
        )
    )


def _validate_inputs(
    populations: Sequence[int],
    max_concurrency: int | None,
    serial_steps: int,
    parallel_fanout: int,
    parallel_steps: int,
    serial_interval_us: int,
) -> None:
    if not populations or any(population < 1 for population in populations):
        raise ValueError("populations must be non-empty and positive")
    if max_concurrency is not None and max_concurrency < 1:
        raise ValueError("max concurrency must be positive")
    if serial_steps < 0 or parallel_steps < 0 or parallel_fanout < 1:
        raise ValueError("case topology values must be non-negative")
    if serial_interval_us < 0:
        raise ValueError("serial interval must be non-negative")


async def _run_benchmarks(
    *,
    populations: Sequence[int],
    max_concurrency: int | None,
    serial_steps: int,
    parallel_fanout: int,
    parallel_steps: int,
    serial_interval_us: int,
    trace_memory: bool,
    stream_progress: bool,
) -> list[BurstLifecycleBenchmark]:
    available_cpus = _available_cpu_count()
    calibration_population = min(min(populations), 1_000)
    capacity, source, candidates = await _select_capacity(
        available_cpus=available_cpus,
        calibration_population=calibration_population,
        requested=max_concurrency,
        serial_steps=serial_steps,
        parallel_fanout=parallel_fanout,
        parallel_steps=parallel_steps,
        serial_interval_us=serial_interval_us,
    )
    receipts: list[BurstLifecycleBenchmark] = []
    for population in populations:
        receipt = await _measure_population(
            population=population,
            available_cpus=available_cpus,
            capacity=capacity,
            capacity_source=source,
            calibration_population=calibration_population,
            calibration_capacities=candidates,
            serial_steps=serial_steps,
            parallel_fanout=parallel_fanout,
            parallel_steps=parallel_steps,
            serial_interval_us=serial_interval_us,
            trace_memory=trace_memory,
        )
        receipts.append(receipt)
        if stream_progress:
            sys.stderr.write(receipt.progress_receipt() + "\n")
            sys.stderr.flush()
    return receipts


async def _select_capacity(
    *,
    available_cpus: int,
    calibration_population: int,
    requested: int | None,
    serial_steps: int,
    parallel_fanout: int,
    parallel_steps: int,
    serial_interval_us: int,
) -> tuple[int, str, tuple[int, ...]]:
    if requested is not None:
        return requested, "manual", (requested,)
    candidates = capacity_candidates(
        available_cpus=available_cpus,
        calibration_population=calibration_population,
    )
    receipts = [
        await _measure_population(
            population=calibration_population,
            available_cpus=available_cpus,
            capacity=candidate,
            capacity_source="calibration",
            calibration_population=calibration_population,
            calibration_capacities=candidates,
            serial_steps=serial_steps,
            parallel_fanout=parallel_fanout,
            parallel_steps=parallel_steps,
            serial_interval_us=serial_interval_us,
            trace_memory=False,
        )
        for candidate in candidates
    ]
    selected = max(
        receipts, key=lambda receipt: receipt.throughput_cases_per_second
    ).selected_capacity
    return selected, "auto-throughput", candidates
