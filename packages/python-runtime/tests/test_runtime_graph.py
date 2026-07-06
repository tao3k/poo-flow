from __future__ import annotations

import pytest

from poo_flow_runtime import (
    END,
    START,
    RuntimeGraphConditionalEdge,
    RuntimeGraphEdge,
    RuntimeGraphError,
    RuntimeGraphExecutor,
    RuntimeGraphPlan,
    linear_plan,
)


def test_runtime_graph_executes_linear_plan() -> None:
    executor = RuntimeGraphExecutor(
        linear_plan("load", "double"),
        {
            "load": lambda state: {"value": state["seed"] + 1},
            "double": lambda state: {"value": state["value"] * 2},
        },
    )

    assert executor.invoke({"seed": 20})["value"] == 42


def test_runtime_graph_routes_conditionally() -> None:
    plan = RuntimeGraphPlan(
        nodes=("classify", "accept", "reject"),
        edges=(
            RuntimeGraphEdge(START, "classify"),
            RuntimeGraphEdge("accept", END),
            RuntimeGraphEdge("reject", END),
        ),
        conditional_edges=(
            RuntimeGraphConditionalEdge(
                "classify",
                "classification",
                {"ok": "accept", "bad": "reject"},
            ),
        ),
    )
    executor = RuntimeGraphExecutor(
        plan,
        {
            "classify": lambda state: {"route": "ok" if state["score"] > 0 else "bad"},
            "accept": lambda state: {"status": "accepted"},
            "reject": lambda state: {"status": "rejected"},
        },
        routers={"classification": lambda state: state["route"]},
    )

    assert executor.invoke({"score": 1})["status"] == "accepted"
    assert executor.invoke({"score": 0})["status"] == "rejected"


def test_runtime_graph_applies_reducers() -> None:
    plan = RuntimeGraphPlan(
        nodes=("left", "right"),
        edges=(
            RuntimeGraphEdge(START, "left"),
            RuntimeGraphEdge(START, "right"),
            RuntimeGraphEdge("left", END),
            RuntimeGraphEdge("right", END),
        ),
    )
    executor = RuntimeGraphExecutor(
        plan,
        {
            "left": lambda state: {"events": ["left"]},
            "right": lambda state: {"events": ["right"]},
        },
        reducers={"events": lambda current, incoming: current + incoming},
    )

    assert executor.invoke({"events": []})["events"] == ["left", "right"]


def test_runtime_graph_rejects_missing_action() -> None:
    with pytest.raises(RuntimeGraphError, match="missing runtime graph actions"):
        RuntimeGraphExecutor(linear_plan("missing"), {})


def test_runtime_graph_enforces_step_limit() -> None:
    plan = RuntimeGraphPlan(
        nodes=("loop",),
        edges=(
            RuntimeGraphEdge(START, "loop"),
            RuntimeGraphEdge("loop", "loop"),
        ),
        step_limit=3,
    )
    executor = RuntimeGraphExecutor(plan, {"loop": lambda state: {"count": 1}})

    with pytest.raises(RuntimeGraphError, match="step limit exceeded"):
        executor.invoke({})
