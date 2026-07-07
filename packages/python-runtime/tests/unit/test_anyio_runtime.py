from __future__ import annotations

import anyio

from poo_flow_runtime.program import RuntimeGraphProgram, RuntimeGraphRegistries
from poo_flow_runtime.runtime_graph import (
    END,
    START,
    RuntimeGraphConditionalEdge,
    RuntimeGraphEdge,
    RuntimeGraphExecutor,
    RuntimeGraphPlan,
    linear_plan,
)


def test_runtime_graph_executor_anyio_invocation() -> None:
    executor = RuntimeGraphExecutor(
        linear_plan("load"),
        {"load": lambda state: {"value": state["value"] + 1}},
    )

    async def scenario() -> None:
        assert await executor.ainvoke({"value": 1}) == {"value": 2}
        assert await executor.abatch(
            [{"value": 1}, {"value": 4}], max_concurrency=2
        ) == [{"value": 2}, {"value": 5}]
        chunks = [
            chunk
            async for chunk in executor.astream({"value": 1}, stream_mode="values")
        ]
        assert chunks == [{"value": 2}]

    anyio.run(scenario)


def test_runtime_graph_program_anyio_invocation() -> None:
    program = RuntimeGraphProgram(
        plan=linear_plan("load"),
        registries=RuntimeGraphRegistries(
            actions={"load": lambda state: {"value": state["value"] + 1}},
        ),
    )

    async def scenario() -> None:
        assert await program.ainvoke({"value": 1}) == {"value": 2}
        assert await program.abatch(
            [{"value": 1}, {"value": 4}], max_concurrency=2
        ) == [{"value": 2}, {"value": 5}]
        chunks = [
            chunk async for chunk in program.astream({"value": 1}, stream_mode="values")
        ]
        assert chunks == [{"value": 2}]

    anyio.run(scenario)


def test_runtime_graph_executor_awaits_async_action_and_router() -> None:
    async def load(state):
        await anyio.sleep(0)
        return {"route": "right"}

    async def route(state):
        await anyio.sleep(0)
        return state["route"]

    executor = RuntimeGraphExecutor(
        RuntimeGraphPlan(
            nodes=("load", "left", "right"),
            edges=(
                RuntimeGraphEdge(START, "load"),
                RuntimeGraphEdge("left", END),
                RuntimeGraphEdge("right", END),
            ),
            conditional_edges=(
                RuntimeGraphConditionalEdge(
                    "load", "choose", {"left": "left", "right": "right"}
                ),
            ),
        ),
        {
            "load": load,
            "left": lambda state: {"value": "left"},
            "right": lambda state: {"value": "right"},
        },
        routers={"choose": route},
    )

    async def scenario() -> None:
        state, trace = await executor.ainvoke_with_trace({})
        assert state["value"] == "right"
        assert trace == ["load", "right"]

    anyio.run(scenario)


def test_runtime_graph_program_awaits_async_action() -> None:
    async def load(state):
        await anyio.sleep(0)
        return {"value": state["value"] + 1}

    program = RuntimeGraphProgram(
        plan=linear_plan("load"),
        registries=RuntimeGraphRegistries(actions={"load": load}),
    )

    async def scenario() -> None:
        assert await program.ainvoke({"value": 1}) == {"value": 2}
        chunks = [
            chunk async for chunk in program.astream({"value": 2}, stream_mode="values")
        ]
        assert chunks == [{"value": 3}]

    anyio.run(scenario)
