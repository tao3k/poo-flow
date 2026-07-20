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
    program = RuntimeGraphProgram.reference(
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

    program = RuntimeGraphProgram.reference(
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


def test_runtime_graph_program_abatch_bounds_concurrency_and_preserves_order() -> None:
    async def scenario() -> None:
        active = 0
        peak = 0
        started = 0
        saturated = anyio.Event()
        third_started = anyio.Event()
        release = anyio.Event()
        results: list[dict[str, int]] | None = None

        async def load(state):
            nonlocal active, peak, started
            started += 1
            active += 1
            peak = max(peak, active)
            if started == 2:
                saturated.set()
            if started == 3:
                third_started.set()
            try:
                await release.wait()
                return {"value": state["value"] * 2}
            finally:
                active -= 1

        program = RuntimeGraphProgram.reference(
            plan=linear_plan("load"),
            registries=RuntimeGraphRegistries(actions={"load": load}),
        )

        async def run_batch() -> None:
            nonlocal results
            results = await program.abatch(
                [{"value": value} for value in range(6)],
                max_concurrency=2,
            )

        with anyio.fail_after(2):
            async with anyio.create_task_group() as task_group:
                task_group.start_soon(run_batch)
                await saturated.wait()
                assert peak == 2
                for _ in range(3):
                    await anyio.sleep(0)
                assert not third_started.is_set()
                release.set()

        assert results == [{"value": value * 2} for value in range(6)]
        assert active == 0

    anyio.run(scenario)


def test_runtime_graph_program_abatch_propagates_cancellation() -> None:
    async def scenario() -> None:
        active = 0
        stopped = 0
        saturated = anyio.Event()

        async def load(state):
            nonlocal active, stopped
            active += 1
            if active == 2:
                saturated.set()
            try:
                await anyio.sleep_forever()
            finally:
                active -= 1
                stopped += 1

        program = RuntimeGraphProgram.reference(
            plan=linear_plan("load"),
            registries=RuntimeGraphRegistries(actions={"load": load}),
        )

        async def run_batch() -> None:
            await program.abatch(
                [{"value": value} for value in range(4)],
                max_concurrency=2,
            )

        with anyio.fail_after(2):
            async with anyio.create_task_group() as task_group:
                task_group.start_soon(run_batch)
                await saturated.wait()
                task_group.cancel_scope.cancel()

        assert active == 0
        assert stopped == 2

    anyio.run(scenario)


def test_runtime_graph_program_astream_respects_consumer_backpressure() -> None:
    async def scenario() -> None:
        executed: list[str] = []

        async def first(state):
            executed.append("first")
            return {"first": True}

        async def second(state):
            executed.append("second")
            return {"second": True}

        program = RuntimeGraphProgram.reference(
            plan=linear_plan("first", "second"),
            registries=RuntimeGraphRegistries(
                actions={"first": first, "second": second}
            ),
        )
        stream = program.astream({}, stream_mode="updates")

        first_chunk = await anext(stream)
        assert first_chunk == {"first": {"first": True}}
        assert executed == ["first"]

        await stream.aclose()
        assert executed == ["first"]

    anyio.run(scenario)
