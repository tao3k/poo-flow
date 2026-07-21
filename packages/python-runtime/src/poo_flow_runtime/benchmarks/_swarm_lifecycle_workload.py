"""Deterministic workload planning for the swarm lifecycle benchmark."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

ArrivalMode = Literal["instant", "ramp"]


@dataclass(frozen=True, slots=True)
class ArrivalSchedule:
    """Logical launch schedule, independent of host execution capacity."""

    mode: ArrivalMode = "instant"
    initial_wave_size: int = 1
    wave_size: int = 1
    wave_interval_ms: int = 0
    simulation_time_scale: float = 1.0

    def __post_init__(self) -> None:
        if self.mode not in ("instant", "ramp"):
            raise ValueError("arrival mode must be 'instant' or 'ramp'")
        if self.initial_wave_size < 1:
            raise ValueError("initial_wave_size must be at least one")
        if self.wave_size < 1:
            raise ValueError("wave_size must be at least one")
        if self.wave_interval_ms < 0:
            raise ValueError("wave_interval_ms must not be negative")
        if self.simulation_time_scale <= 0:
            raise ValueError("simulation_time_scale must be greater than zero")

    def logical_eligible_at_ms(self, ordinal: int) -> int:
        """Return logical eligibility time for a zero-based agent ordinal."""

        if ordinal < 0:
            raise ValueError("agent ordinal must not be negative")
        if self.mode == "instant" or ordinal < self.initial_wave_size:
            return 0
        wave = 1 + (ordinal - self.initial_wave_size) // self.wave_size
        return wave * self.wave_interval_ms

    def effective_eligible_at_ms(self, ordinal: int) -> float:
        """Return compressed wall-time eligibility for benchmark execution."""

        return self.logical_eligible_at_ms(ordinal) / self.simulation_time_scale


@dataclass(frozen=True, slots=True)
class PlannedSwarmAgent:
    tenant_id: str
    swarm_id: str
    agent_id: str
    parent_agent_id: str | None
    role_id: str
    policy_id: str
    capability_set_id: str
    step_budget: int
    tool_call_budget: int
    logical_eligible_at_ms: int


@dataclass(frozen=True, slots=True)
class PlannedSwarm:
    tenant_id: str
    swarm_id: str
    main_agent_id: str
    member_count: int


@dataclass(frozen=True, slots=True)
class PlannedTenant:
    tenant_id: str
    agent_count: int
    swarm_count: int


@dataclass(frozen=True, slots=True)
class SwarmWorkload:
    requested_total_agents: int
    tenant_count: int
    agents_per_swarm: int
    arrival: ArrivalSchedule
    agents: tuple[PlannedSwarmAgent, ...]
    swarms: tuple[PlannedSwarm, ...]
    tenants: tuple[PlannedTenant, ...]

    @property
    def realized_total_agents(self) -> int:
        return len(self.agents)

    @property
    def swarm_count(self) -> int:
        return len(self.swarms)
