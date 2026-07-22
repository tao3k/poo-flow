"""Execute one bounded swarm and capture raw lifecycle timing evidence."""

from __future__ import annotations

from dataclasses import dataclass, field
from time import perf_counter_ns, process_time_ns
from typing import Any, Awaitable, Callable, Mapping

import anyio

from ..program import RuntimeGraphProgram, RuntimeGraphRegistries
from ..runtime_graph import linear_plan
from ._swarm_lifecycle_arrival import prepare_runtime_program, run_arrival_batch
from ._swarm_lifecycle_projection import (
    SwarmTimingEvidence,
    project_swarm_benchmark,
)
from ._swarm_lifecycle_receipt import SwarmLifecycleBenchmark
from ._swarm_lifecycle_workload import PlannedSwarmAgent, SwarmWorkload

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

    def evidence(self) -> SwarmTimingEvidence:
        return SwarmTimingEvidence(
            started_at_ns=dict(self.started_at_ns),
            finished_at_ns=dict(self.finished_at_ns),
            peak_active=self.peak_active,
            final_active=self.active,
        )


@dataclass(frozen=True, slots=True)
class _ExecutionSample:
    outputs: list[dict[str, Any]]
    wall_start_ns: int
    barrier_open_ns: int
    aggregate_created_ns: int
    process_elapsed_ns: int


async def measure_single_swarm(
    *,
    workload: SwarmWorkload,
    selected_capacity: int,
    available_cpus: int,
    capacity_source: str,
    capacity_policy: str,
    service_time_ms: float,
) -> SwarmLifecycleBenchmark:
    """Execute one swarm and project its terminal barrier evidence."""

    _validate_single_swarm(workload)
    observer = _SwarmObserver()
    sample = await _execute_inputs(
        program=_program(observer, service_time_ms),
        inputs=tuple(_agent_input(agent) for agent in workload.agents),
        workload=workload,
        selected_capacity=selected_capacity,
    )
    completed_ids = tuple(
        output["agent_id"]
        for output in sample.outputs
        if output.get("lifecycle_state") == "completed"
    )
    return project_swarm_benchmark(
        workload=workload,
        timings=observer.evidence(),
        outputs=sample.outputs,
        completed_ids=completed_ids,
        wall_start_ns=sample.wall_start_ns,
        barrier_open_ns=sample.barrier_open_ns,
        aggregate_created_ns=sample.aggregate_created_ns,
        process_elapsed_ns=sample.process_elapsed_ns,
        selected_capacity=selected_capacity,
        available_cpus=available_cpus,
        capacity_source=capacity_source,
        capacity_policy=capacity_policy,
        service_time_ms=service_time_ms,
    )


async def _execute_inputs(
    *,
    program: RuntimeGraphProgram,
    inputs: tuple[dict[str, Any], ...],
    workload: SwarmWorkload,
    selected_capacity: int,
) -> _ExecutionSample:
    prepared = prepare_runtime_program(program)
    wall_start_ns = perf_counter_ns()
    process_start_ns = process_time_ns()
    outputs = await run_arrival_batch(
        prepared,
        inputs,
        schedule=workload.arrival,
        max_concurrency=selected_capacity,
        wall_start_ns=wall_start_ns,
    )
    barrier_open_ns = perf_counter_ns()
    aggregate_created_ns = perf_counter_ns()
    return _ExecutionSample(
        outputs=outputs,
        wall_start_ns=wall_start_ns,
        barrier_open_ns=barrier_open_ns,
        aggregate_created_ns=aggregate_created_ns,
        process_elapsed_ns=process_time_ns() - process_start_ns,
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


def _agent_input(agent: PlannedSwarmAgent) -> dict[str, Any]:
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


def _validate_single_swarm(workload: SwarmWorkload) -> None:
    if workload.tenant_count != 1 or workload.swarm_count != 1:
        raise ValueError("phase-2 measurement requires exactly one swarm")
