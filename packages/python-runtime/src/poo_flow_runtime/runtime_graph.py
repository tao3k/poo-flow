"""Dependency-free runtime graph executor.

This module models the runtime execution substrate that a compiled POO Flow
handoff plan can target. It intentionally does not provide the user-facing
policy or graph authoring interface; Scheme owns that layer.
"""

from __future__ import annotations

from collections import defaultdict, deque
from dataclasses import dataclass, field
from typing import Any, Callable, Mapping


START = "__start__"
END = "__end__"

RuntimeState = dict[str, Any]
RuntimeAction = Callable[[Mapping[str, Any]], Mapping[str, Any] | None]
RuntimeRouter = Callable[[Mapping[str, Any]], str]
RuntimeReducer = Callable[[Any, Any], Any]


class RuntimeGraphError(RuntimeError):
    pass


@dataclass(frozen=True)
class RuntimeGraphEdge:
    source: str
    target: str


@dataclass(frozen=True)
class RuntimeGraphConditionalEdge:
    source: str
    router: str
    routes: Mapping[str, str]


@dataclass(frozen=True)
class RuntimeGraphPlan:
    nodes: tuple[str, ...]
    edges: tuple[RuntimeGraphEdge, ...]
    conditional_edges: tuple[RuntimeGraphConditionalEdge, ...] = ()
    step_limit: int = 100
    metadata: Mapping[str, str] = field(default_factory=dict)

    def __post_init__(self) -> None:
        if self.step_limit <= 0:
            raise RuntimeGraphError("runtime graph step_limit must be positive")

        node_set = set(self.nodes)
        for edge in self.edges:
            _check_endpoint(edge.source, node_set)
            _check_endpoint(edge.target, node_set)

        for edge in self.conditional_edges:
            _check_endpoint(edge.source, node_set)
            for target in edge.routes.values():
                _check_endpoint(target, node_set)


class RuntimeGraphExecutor:
    """Execute a compiled runtime graph plan with registered node actions."""

    def __init__(
        self,
        plan: RuntimeGraphPlan,
        actions: Mapping[str, RuntimeAction],
        *,
        routers: Mapping[str, RuntimeRouter] | None = None,
        reducers: Mapping[str, RuntimeReducer] | None = None,
    ) -> None:
        self.plan = plan
        self.actions = dict(actions)
        self.routers = dict(routers or {})
        self.reducers = dict(reducers or {})
        self._edges = _index_edges(plan.edges)
        self._conditional_edges = _index_conditional_edges(plan.conditional_edges)
        self._validate_actions()

    def invoke(self, initial_state: Mapping[str, Any]) -> RuntimeState:
        state: RuntimeState = dict(initial_state)
        pending = deque(self._edges[START])
        steps = 0

        while pending:
            node = pending.popleft()
            if node == END:
                continue

            steps += 1
            if steps > self.plan.step_limit:
                raise RuntimeGraphError("runtime graph step limit exceeded")

            action = self.actions[node]
            update = action(dict(state))
            if update:
                state = _merge_state(state, update, self.reducers)

            for conditional in self._conditional_edges[node]:
                router = self.routers.get(conditional.router)
                if router is None:
                    raise RuntimeGraphError(
                        f"missing runtime graph router: {conditional.router}"
                    )
                route_key = router(dict(state))
                try:
                    pending.append(conditional.routes[route_key])
                except KeyError as exc:
                    raise RuntimeGraphError(
                        f"router {conditional.router} returned unknown route: "
                        f"{route_key}"
                    ) from exc

            pending.extend(self._edges[node])

        return state

    def _validate_actions(self) -> None:
        missing = sorted(node for node in self.plan.nodes if node not in self.actions)
        if missing:
            raise RuntimeGraphError(
                "missing runtime graph actions: " + ", ".join(missing)
            )


def linear_plan(*nodes: str, step_limit: int = 100) -> RuntimeGraphPlan:
    if not nodes:
        raise RuntimeGraphError("linear runtime graph requires at least one node")

    edges = [RuntimeGraphEdge(START, nodes[0])]
    edges.extend(
        RuntimeGraphEdge(source, target)
        for source, target in zip(nodes, nodes[1:], strict=False)
    )
    edges.append(RuntimeGraphEdge(nodes[-1], END))
    return RuntimeGraphPlan(nodes=tuple(nodes), edges=tuple(edges), step_limit=step_limit)


def _check_endpoint(endpoint: str, node_set: set[str]) -> None:
    if endpoint in (START, END):
        return
    if endpoint not in node_set:
        raise RuntimeGraphError(f"unknown runtime graph node: {endpoint}")


def _index_edges(edges: tuple[RuntimeGraphEdge, ...]) -> dict[str, list[str]]:
    indexed: dict[str, list[str]] = defaultdict(list)
    for edge in edges:
        indexed[edge.source].append(edge.target)
    return indexed


def _index_conditional_edges(
    edges: tuple[RuntimeGraphConditionalEdge, ...],
) -> dict[str, list[RuntimeGraphConditionalEdge]]:
    indexed: dict[str, list[RuntimeGraphConditionalEdge]] = defaultdict(list)
    for edge in edges:
        indexed[edge.source].append(edge)
    return indexed


def _merge_state(
    state: RuntimeState,
    update: Mapping[str, Any],
    reducers: Mapping[str, RuntimeReducer],
) -> RuntimeState:
    merged = dict(state)
    for key, value in update.items():
        if key in merged and key in reducers:
            merged[key] = reducers[key](merged[key], value)
        else:
            merged[key] = value
    return merged
