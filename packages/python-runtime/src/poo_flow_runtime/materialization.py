"""Materialize typed runtime graph plans into C ABI graph handles."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Mapping

from .bindings import PooFlowGraphPlan, PooFlowRuntimeBinding
from .runtime_graph import RuntimeGraphPlan


@dataclass(frozen=True)
class RuntimeGraphBindings:
    """Runtime action and reducer symbols for a typed graph plan."""

    node_actions: Mapping[str, str] = field(default_factory=dict)
    state_reducers: Mapping[str, str] = field(default_factory=dict)

    def action_for(self, node: str) -> str:
        return self.node_actions.get(node, node)


def materialize_runtime_graph_plan(
    binding: PooFlowRuntimeBinding,
    plan: RuntimeGraphPlan,
    graph_bindings: RuntimeGraphBindings | None = None,
) -> PooFlowGraphPlan:
    """Create and validate a C ABI graph plan handle from a typed plan."""

    graph_bindings = graph_bindings or RuntimeGraphBindings()
    _validate_graph_bindings(plan, graph_bindings)

    graph_plan = binding.graph_plan()
    try:
        graph_plan.set_step_limit(plan.step_limit)

        for node in plan.nodes:
            graph_plan.add_node(node)
            graph_plan.set_node_action(node, graph_bindings.action_for(node))

        for state_key, reducer in graph_bindings.state_reducers.items():
            graph_plan.set_state_reducer(state_key, reducer)

        for edge in plan.edges:
            graph_plan.add_edge(edge.source, edge.target)

        for conditional_edge in plan.conditional_edges:
            for route_key, target in conditional_edge.routes.items():
                graph_plan.add_conditional_route(
                    source=conditional_edge.source,
                    router=conditional_edge.router,
                    route_key=route_key,
                    target=target,
                )

        graph_plan.validate()
    except Exception:
        graph_plan.close()
        raise

    return graph_plan


def _validate_graph_bindings(
    plan: RuntimeGraphPlan,
    graph_bindings: RuntimeGraphBindings,
) -> None:
    nodes = set(plan.nodes)
    extra_actions = sorted(
        node for node in graph_bindings.node_actions.keys() if node not in nodes
    )
    if extra_actions:
        raise ValueError(
            "node action bindings reference unknown nodes: "
            + ", ".join(extra_actions)
        )
