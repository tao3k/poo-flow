"""Pure grouping algorithm for deterministic swarm benchmark workloads."""

from __future__ import annotations

from math import ceil
from typing import Sequence

from ._swarm_lifecycle_workload import (
    ArrivalSchedule,
    PlannedSwarm,
    PlannedSwarmAgent,
    PlannedTenant,
    SwarmWorkload,
)


def plan_swarm_workload(
    total_agents: int,
    tenant_count: int,
    agents_per_swarm: int,
    *,
    arrival: ArrivalSchedule | None = None,
    role_ids: Sequence[str] = ("worker",),
    policy_ids: Sequence[str] = ("default",),
    capability_set_ids: Sequence[str] = ("default",),
    step_budget: int = 100,
    tool_call_budget: int = 100,
) -> SwarmWorkload:
    """Plan bounded swarms with deterministic round-robin tenant assignment."""

    _validate_dimensions(
        total_agents=total_agents,
        tenant_count=tenant_count,
        agents_per_swarm=agents_per_swarm,
        step_budget=step_budget,
        tool_call_budget=tool_call_budget,
    )
    roles = _require_ids("role_ids", role_ids)
    policies = _require_ids("policy_ids", policy_ids)
    capabilities = _require_ids("capability_set_ids", capability_set_ids)
    schedule = arrival or ArrivalSchedule()
    width = max(4, len(str(total_agents)))
    tenant_populations = _tenant_populations(total_agents, tenant_count)
    tenant_ids = _tenant_ids(tenant_count)
    return SwarmWorkload(
        requested_total_agents=total_agents,
        tenant_count=tenant_count,
        agents_per_swarm=agents_per_swarm,
        arrival=schedule,
        agents=_plan_agents(
            total_agents=total_agents,
            tenant_count=tenant_count,
            agents_per_swarm=agents_per_swarm,
            tenant_ids=tenant_ids,
            schedule=schedule,
            roles=roles,
            policies=policies,
            capabilities=capabilities,
            step_budget=step_budget,
            tool_call_budget=tool_call_budget,
            agent_id_width=width,
        ),
        swarms=_plan_swarms(
            tenant_ids=tenant_ids,
            tenant_populations=tenant_populations,
            tenant_count=tenant_count,
            agents_per_swarm=agents_per_swarm,
            agent_id_width=width,
        ),
        tenants=_plan_tenants(
            tenant_ids=tenant_ids,
            tenant_populations=tenant_populations,
            agents_per_swarm=agents_per_swarm,
        ),
    )


def _plan_agents(
    *,
    total_agents: int,
    tenant_count: int,
    agents_per_swarm: int,
    tenant_ids: tuple[str, ...],
    schedule: ArrivalSchedule,
    roles: tuple[str, ...],
    policies: tuple[str, ...],
    capabilities: tuple[str, ...],
    step_budget: int,
    tool_call_budget: int,
    agent_id_width: int,
) -> tuple[PlannedSwarmAgent, ...]:
    agents: list[PlannedSwarmAgent] = []
    for ordinal in range(total_agents):
        tenant_index = ordinal % tenant_count
        tenant_position = ordinal // tenant_count
        swarm_index, member_index = divmod(tenant_position, agents_per_swarm)
        tenant_id = tenant_ids[tenant_index]
        main_ordinal = tenant_index + swarm_index * agents_per_swarm * tenant_count
        main_agent_id = _agent_id(main_ordinal, agent_id_width)
        agents.append(
            PlannedSwarmAgent(
                tenant_id=tenant_id,
                swarm_id=f"{tenant_id}/swarm-{swarm_index + 1:04d}",
                agent_id=_agent_id(ordinal, agent_id_width),
                parent_agent_id=None if member_index == 0 else main_agent_id,
                role_id=roles[ordinal % len(roles)],
                policy_id=policies[ordinal % len(policies)],
                capability_set_id=capabilities[ordinal % len(capabilities)],
                step_budget=step_budget,
                tool_call_budget=tool_call_budget,
                logical_eligible_at_ms=schedule.logical_eligible_at_ms(ordinal),
            )
        )
    return tuple(agents)


def _plan_swarms(
    *,
    tenant_ids: tuple[str, ...],
    tenant_populations: tuple[int, ...],
    tenant_count: int,
    agents_per_swarm: int,
    agent_id_width: int,
) -> tuple[PlannedSwarm, ...]:
    swarms: list[PlannedSwarm] = []
    for tenant_index, (tenant_id, population) in enumerate(
        zip(tenant_ids, tenant_populations, strict=True)
    ):
        for swarm_index, start in enumerate(range(0, population, agents_per_swarm)):
            main_ordinal = tenant_index + start * tenant_count
            swarms.append(
                PlannedSwarm(
                    tenant_id=tenant_id,
                    swarm_id=f"{tenant_id}/swarm-{swarm_index + 1:04d}",
                    main_agent_id=_agent_id(main_ordinal, agent_id_width),
                    member_count=min(agents_per_swarm, population - start),
                )
            )
    return tuple(swarms)


def _plan_tenants(
    *,
    tenant_ids: tuple[str, ...],
    tenant_populations: tuple[int, ...],
    agents_per_swarm: int,
) -> tuple[PlannedTenant, ...]:
    return tuple(
        PlannedTenant(
            tenant_id=tenant_id,
            agent_count=population,
            swarm_count=ceil(population / agents_per_swarm),
        )
        for tenant_id, population in zip(
            tenant_ids, tenant_populations, strict=True
        )
    )


def _tenant_ids(tenant_count: int) -> tuple[str, ...]:
    width = max(4, len(str(tenant_count)))
    return tuple(
        f"tenant-{index + 1:0{width}d}" for index in range(tenant_count)
    )


def _tenant_populations(total_agents: int, tenant_count: int) -> tuple[int, ...]:
    base, remainder = divmod(total_agents, tenant_count)
    return tuple(base + (index < remainder) for index in range(tenant_count))


def _agent_id(ordinal: int, width: int) -> str:
    return f"agent-{ordinal + 1:0{width}d}"


def _validate_dimensions(
    *,
    total_agents: int,
    tenant_count: int,
    agents_per_swarm: int,
    step_budget: int,
    tool_call_budget: int,
) -> None:
    _require_positive("total_agents", total_agents)
    _require_positive("tenant_count", tenant_count)
    _require_positive("agents_per_swarm", agents_per_swarm)
    _require_positive("step_budget", step_budget)
    _require_positive("tool_call_budget", tool_call_budget)
    if tenant_count > total_agents:
        raise ValueError("tenant_count must not exceed total_agents")


def _require_positive(name: str, value: int) -> None:
    if isinstance(value, bool) or not isinstance(value, int) or value < 1:
        raise ValueError(f"{name} must be a positive integer")


def _require_ids(name: str, values: Sequence[str]) -> tuple[str, ...]:
    if isinstance(values, str):
        raise ValueError(f"{name} must be a non-empty sequence of identifiers")
    normalized = tuple(values)
    if not normalized or any(not isinstance(value, str) or not value for value in normalized):
        raise ValueError(f"{name} must be a non-empty sequence of identifiers")
    return normalized
