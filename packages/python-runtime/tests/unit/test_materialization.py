from __future__ import annotations

import pytest

from poo_flow_runtime import (
    RuntimeGraphBindings,
    RuntimeGraphEdge,
    RuntimeGraphPlan,
    RuntimeGraphProgram,
    RuntimeGraphRegistries,
    PooFlowRuntimeBinding,
    linear_plan,
    materialize_runtime_graph_plan,
)


def test_materialize_runtime_graph_plan_to_c_abi_handle() -> None:
    binding = PooFlowRuntimeBinding.from_probe()
    plan = linear_plan("load", "save", step_limit=12)
    graph_bindings = RuntimeGraphBindings(
        node_actions={
            "load": "poo.load",
            "save": "poo.save",
        },
        state_reducers={"events": "poo.events.append"},
    )

    with materialize_runtime_graph_plan(binding, plan, graph_bindings) as graph_plan:
        receipt = graph_plan.validate()

    assert b"kind=runtime-graph-validation\n" in receipt
    assert b"nodes=2\n" in receipt
    assert b"node-actions=2\n" in receipt
    assert b"state-reducers=1\n" in receipt
    assert b"edges=3\n" in receipt
    assert b"step-limit=12\n" in receipt
    assert b"plan-digest=" in receipt


def test_materialize_runtime_graph_defaults_action_symbols_to_node_names() -> None:
    binding = PooFlowRuntimeBinding.from_probe()
    plan = linear_plan("load")

    with materialize_runtime_graph_plan(binding, plan) as graph_plan:
        receipt = graph_plan.validate()

    assert b"nodes=1\n" in receipt
    assert b"node-actions=1\n" in receipt


def test_materialize_runtime_graph_rejects_unknown_action_binding() -> None:
    binding = PooFlowRuntimeBinding.from_probe()
    plan = linear_plan("load")

    with pytest.raises(ValueError, match="unknown nodes"):
        materialize_runtime_graph_plan(
            binding,
            plan,
            RuntimeGraphBindings(node_actions={"missing": "poo.missing"}),
        )


def test_materialize_runtime_graph_closes_invalid_c_handle() -> None:
    binding = PooFlowRuntimeBinding.from_probe()
    plan = RuntimeGraphPlan(
        nodes=("load",),
        edges=(RuntimeGraphEdge("load", "load"),),
    )

    with pytest.raises(Exception):
        materialize_runtime_graph_plan(binding, plan)


def test_runtime_graph_program_describes_c_abi_validated_plan() -> None:
    program = RuntimeGraphProgram(
        plan=linear_plan("load", "save", step_limit=8),
        graph_bindings=RuntimeGraphBindings(
            node_actions={
                "load": "poo.load",
                "save": "poo.save",
            },
        ),
        binding=PooFlowRuntimeBinding.from_probe(),
    )

    receipt = program.describe()

    assert b"kind=runtime-graph-validation\n" in receipt
    assert b"nodes=2\n" in receipt
    assert b"node-actions=2\n" in receipt
    assert b"step-limit=8\n" in receipt


def test_runtime_graph_program_invokes_registered_actions_and_reducers() -> None:
    plan = linear_plan("load", "save")
    graph_bindings = RuntimeGraphBindings(
        node_actions={
            "load": "poo.load",
            "save": "poo.save",
        },
        state_reducers={"events": "poo.events.append"},
    )

    def load(state: dict[str, object]) -> dict[str, object]:
        return {"events": ["load"], "value": 1}

    def save(state: dict[str, object]) -> dict[str, object]:
        return {"events": ["save"], "saved": state["value"]}

    program = RuntimeGraphProgram(
        plan=plan,
        graph_bindings=graph_bindings,
        registries=RuntimeGraphRegistries(
            actions={
                "poo.load": load,
                "poo.save": save,
            },
            reducers={
                "poo.events.append": lambda left, right: [*left, *right],
            },
        ),
        binding=PooFlowRuntimeBinding.from_probe(),
    )

    result = program.invoke({"events": []})

    assert result["events"] == ["load", "save"]
    assert result["saved"] == 1
    assert "_poo_flow_runtime_graph_plan" not in result
