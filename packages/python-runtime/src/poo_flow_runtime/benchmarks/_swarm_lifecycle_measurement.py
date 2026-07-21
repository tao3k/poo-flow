"""Instant-arrival measurement for one bounded swarm."""

from __future__ import annotations

from dataclasses import dataclass, field
from time import perf_counter_ns, process_time_ns
from typing import Any, Awaitable, Callable, Mapping

import anyio

from ..program import RuntimeGraphProgram, RuntimeGraphRegistries
from ..runtime_graph import linear_plan
from ._swarm_lifecycle_receipt import (
    SwarmLatencySummary,
    SwarmLifecycleBenchmark,
)
from ._swarm_lifecycle_workload import SwarmWorkload

AgentAction = Callable[[Mapping[str, Any]], Awaitable[dict[str, Any]]]


@dataclass(slots=True)
class _SwarmObserver:
    started_at_ns: dict[str, int] = field(default_factory=dict)
    finished_at_ns: dict[str, int] = field(default_factory=dict)
    active: int = 0
    peak_active: int = 0

    def start(self, agent_id: str) -> None:
        self.started_at_ns[agent_id] = perf_counter_ns()
        self.active += 1
        self.peak_active = max(self.peak_active, self.active)

    def finish(self, agent_id: str) -> None:
        self.finished_at_ns[agent_id] = perf_counter_ns()
        self.active -= 1


async def measure_single_swarm(
    *,
    workload: SwarmWorkload,
    selected_capacity: int,
    available_cpus: int,
    capacity_source: str,
    capacity_policy: str,
    service_time_ms: float,
) -> SwarmLifecycleBenchmark:
    """Execute one instant-arrival swarm and open one terminal barrier."""

    _validate_single_swarm(workload)
    observer = _SwarmObserver()
    program = _program(observer, service_time_ms)
    inputs = tuple(_agent_input(agent) for agent in workload.agents)
    wall_start_ns = perf_counter_ns()
    process_start_ns = process_time_ns()
    outputs = await program.abatch(inputs, max_concurrency=selected_capacity)
    barrier_open_ns = perf_counter_ns()
    completed_ids = tuple(
        output["agent_id"]
        for output in outputs
        if output.get("lifecycle_state") == "completed"
    )
    aggregate_created_ns = perf_counter_ns()
    process_finish_ns = process_time_ns()
    return _project_benchmark(
        workload=workload,
        observer=observer,
        completed_ids=completed_ids,
        wall_start_ns=wall_start_ns,
        barrier_open_ns=barrier_open_ns,
        aggregate_created_ns=aggregate_created_ns,
        process_elapsed_ns=process_finish_ns - process_start_ns,
        selected_capacity=selected_capacity,
        available_cpus=available_cpus,
        capacity_source=capacity_source,
        capacity_policy=capacity_policy,
        service_time_ms=service_time_ms,
    )


def _program(observer: _SwarmObserver, service_time_ms: float) -> RuntimeGraphProgram:
    return RuntimeGraphProgram.reference(
        plan=linear_plan("agent"),
        registries=RuntimeGraphRegistries(
            actions={"agent": _agent_action(observer, service_time_ms)}
        ),
    )


def _agent_action(observer: _SwarmObserver, service_time_ms: float) -> AgentAction:
    async def execute(state: Mapping[str, Any]) -> dict[str, Any]:
        agent_id = str(state["agent_id"])
        observer.start(agent_id)
        try:
            await anyio.sleep(service_time_ms / 1_000.0)
            return {"lifecycle_state": "completed"}
        finally:
            observer.finish(agent_id)

    return execute


def _agent_input(agent: Any) -> dict[str, Any]:
    return {
        "tenant_id": agent.tenant_id,
        "swarm_id": agent.swarm_id,
        "agent_id": agent.agent_id,
        "parent_agent_id": agent.parent_agent_id,
        "role_id": agent.role_id,
        "policy_id": agent.policy_id,
        "capability_set_id": agent.capability_set_id,
        "lifecycle_state": "queued",
    }


def _project_benchmark(
    *,
    workload: SwarmWorkload,
    observer: _SwarmObserver,
    completed_ids: tuple[str, ...],
    wall_start_ns: int,
    barrier_open_ns: int,
    aggregate_created_ns: int,
    process_elapsed_ns: int,
    selected_capacity: int,
    available_cpus: int,
    capacity_source: str,
    capacity_policy: str,
    service_time_ms: float,
) -> SwarmLifecycleBenchmark:
    expected_ids = {agent.agent_id for agent in workload.agents}
    completed_id_set = set(completed_ids)
    starts = tuple(observer.started_at_ns[agent_id] for agent_id in completed_ids)
    finishes = tuple(observer.finished_at_ns[agent_id] for agent_id in completed_ids)
    wall_elapsed_ns = aggregate_created_ns - wall_start_ns
    return SwarmLifecycleBenchmark(
        total_agents=workload.realized_total_agents,
        selected_capacity=selected_capacity,
        available_cpus=available_cpus,
        capacity_source=capacity_source,
        capacity_policy=capacity_policy,
        service_time_ms=service_time_ms,
        wall_time_ms=_ms(wall_elapsed_ns),
        process_time_ms=_ms(process_elapsed_ns),
        startup_latency=_latencies(start - wall_start_ns for start in starts),
        service_latency=_latencies(
            finish - start for start, finish in zip(starts, finishes, strict=True)
        ),
        settlement_latency=_latencies(
            aggregate_created_ns - finish for finish in finishes
        ),
        barrier_wait=_latencies(barrier_open_ns - finish for finish in finishes),
        aggregation_latency_ms=_ms(aggregate_created_ns - barrier_open_ns),
        throughput_agents_per_second=(
            len(completed_ids) / (wall_elapsed_ns / 1_000_000_000)
        ),
        peak_active_agents=observer.peak_active,
        completed_agents=len(completed_ids),
        failed_agents=0,
        timed_out_agents=0,
        cancelled_agents=0,
        duplicate_completion_count=len(completed_ids) - len(completed_id_set),
        lost_completion_count=len(expected_ids - completed_id_set),
        final_active_agents=observer.active,
        total_logical_steps=workload.realized_total_agents,
        critical_steps=1,
        barrier_opened_after_all_terminal=(
            len(observer.finished_at_ns) == workload.realized_total_agents
            and all(finish <= barrier_open_ns for finish in finishes)
        ),
        aggregate_created_after_barrier=aggregate_created_ns >= barrier_open_ns,
    )


def _latencies(values: Any) -> SwarmLatencySummary:
    ordered = sorted(values)
    return SwarmLatencySummary(
        p50_ms=_ms(_percentile(ordered, 0.50)),
        p95_ms=_ms(_percentile(ordered, 0.95)),
        p99_ms=_ms(_percentile(ordered, 0.99)),
    )


def _percentile(ordered: list[int], fraction: float) -> float:
    if not ordered:
        return 0.0
    position = (len(ordered) - 1) * fraction
    lower = int(position)
    upper = min(lower + 1, len(ordered) - 1)
    weight = position - lower
    return ordered[lower] * (1 - weight) + ordered[upper] * weight


def _ms(nanoseconds: int | float) -> float:
    return nanoseconds / 1_000_000


def _validate_single_swarm(workload: SwarmWorkload) -> None:
    if workload.tenant_count != 1 or workload.swarm_count != 1:
        raise ValueError("phase-2 measurement requires exactly one swarm")
