from __future__ import annotations

from collections import Counter

import pytest

from poo_flow_runtime.benchmarks._swarm_lifecycle_planner import plan_swarm_workload
from poo_flow_runtime.benchmarks._swarm_lifecycle_workload import ArrivalSchedule


def test_plans_one_bounded_swarm_with_explicit_composition() -> None:
    workload = plan_swarm_workload(
        4,
        tenant_count=1,
        agents_per_swarm=4,
        role_ids=("research", "verify"),
        policy_ids=("fast", "strict"),
        capability_set_ids=("web", "code"),
        step_budget=15,
        tool_call_budget=30,
    )

    assert workload.realized_total_agents == 4
    assert workload.swarm_count == 1
    assert workload.swarms[0].member_count == 4
    assert workload.agents[0].parent_agent_id is None
    assert all(
        agent.parent_agent_id == workload.agents[0].agent_id
        for agent in workload.agents[1:]
    )
    assert [agent.role_id for agent in workload.agents] == [
        "research",
        "verify",
        "research",
        "verify",
    ]
    assert [agent.policy_id for agent in workload.agents] == [
        "fast",
        "strict",
        "fast",
        "strict",
    ]
    assert [agent.capability_set_id for agent in workload.agents] == [
        "web",
        "code",
        "web",
        "code",
    ]


def test_ramp_schedule_preserves_logical_and_effective_time() -> None:
    schedule = ArrivalSchedule(
        mode="ramp",
        initial_wave_size=5,
        wave_size=1,
        wave_interval_ms=700,
        simulation_time_scale=100,
    )
    workload = plan_swarm_workload(
        8,
        tenant_count=1,
        agents_per_swarm=8,
        arrival=schedule,
    )

    assert [agent.logical_eligible_at_ms for agent in workload.agents] == [
        0,
        0,
        0,
        0,
        0,
        700,
        1400,
        2100,
    ]
    assert schedule.effective_eligible_at_ms(7) == 21


def test_multitenant_plan_is_fair_and_keeps_partial_swarms_explicit() -> None:
    workload = plan_swarm_workload(
        5_003,
        tenant_count=12,
        agents_per_swarm=128,
    )
    tenant_counts = [tenant.agent_count for tenant in workload.tenants]

    assert max(tenant_counts) - min(tenant_counts) == 1
    assert sum(tenant_counts) == 5_003
    assert sum(swarm.member_count for swarm in workload.swarms) == 5_003
    assert all(1 <= swarm.member_count <= 128 for swarm in workload.swarms)
    assert any(swarm.member_count < 128 for swarm in workload.swarms)
    assert workload.swarm_count == sum(
        tenant.swarm_count for tenant in workload.tenants
    )


def test_100k_plan_has_no_lost_or_duplicate_agent_membership() -> None:
    workload = plan_swarm_workload(
        100_000,
        tenant_count=1_000,
        agents_per_swarm=128,
    )
    agent_ids = {agent.agent_id for agent in workload.agents}
    swarm_counts = Counter(agent.swarm_id for agent in workload.agents)

    assert workload.requested_total_agents == 100_000
    assert workload.realized_total_agents == 100_000
    assert len(agent_ids) == 100_000
    assert sum(swarm_counts.values()) == 100_000
    assert max(swarm_counts.values()) <= 128
    assert set(swarm_counts) == {swarm.swarm_id for swarm in workload.swarms}
    assert all(
        swarm_counts[swarm.swarm_id] == swarm.member_count
        for swarm in workload.swarms
    )


@pytest.mark.parametrize(
    ("kwargs", "match"),
    [
        ({"total_agents": 0}, "total_agents"),
        ({"tenant_count": 0}, "tenant_count"),
        ({"tenant_count": 3, "total_agents": 2}, "must not exceed"),
        ({"agents_per_swarm": 0}, "agents_per_swarm"),
        ({"step_budget": 0}, "step_budget"),
        ({"tool_call_budget": 0}, "tool_call_budget"),
        ({"role_ids": ()}, "role_ids"),
        ({"policy_ids": "default"}, "policy_ids"),
        ({"capability_set_ids": ("",)}, "capability_set_ids"),
    ],
)
def test_rejects_invalid_workload_dimensions(
    kwargs: dict[str, object], match: str
) -> None:
    arguments: dict[str, object] = {
        "total_agents": 4,
        "tenant_count": 1,
        "agents_per_swarm": 4,
    }
    arguments.update(kwargs)

    with pytest.raises(ValueError, match=match):
        plan_swarm_workload(**arguments)  # type: ignore[arg-type]


@pytest.mark.parametrize(
    "schedule",
    [
        ArrivalSchedule(mode="instant"),
        ArrivalSchedule(mode="ramp", initial_wave_size=5, wave_size=2),
    ],
)
def test_schedule_rejects_negative_agent_ordinal(schedule: ArrivalSchedule) -> None:
    with pytest.raises(ValueError, match="ordinal"):
        schedule.logical_eligible_at_ms(-1)


@pytest.mark.parametrize(
    "kwargs",
    [
        {"mode": "unknown"},
        {"initial_wave_size": 0},
        {"wave_size": 0},
        {"wave_interval_ms": -1},
        {"simulation_time_scale": 0},
    ],
)
def test_rejects_invalid_arrival_schedule(kwargs: dict[str, object]) -> None:
    with pytest.raises(ValueError):
        ArrivalSchedule(**kwargs)  # type: ignore[arg-type]
