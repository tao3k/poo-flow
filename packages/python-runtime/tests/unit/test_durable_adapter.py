from __future__ import annotations

import anyio
import pytest

from poo_flow_runtime.durable_adapter import RuntimeDurableAdapter
from poo_flow_runtime.program import RuntimeGraphProgram, RuntimeGraphRegistries
from poo_flow_runtime.runtime_graph import (
    END,
    START,
    RuntimeGraphEdge,
    RuntimeGraphInterrupt,
    RuntimeGraphInterrupted,
    RuntimeGraphPlan,
)


def test_turso_durable_adapter_consumes_scheme_manifest(tmp_path) -> None:
    adapter = RuntimeDurableAdapter.turso(
        tmp_path / "adapter.db",
        policy=(
            b"policy-id=poo-flow-durable-policy.v1\n"
            b"owner=scheme\n"
            b"checkpoint-id-strategy=runtime-generated\n"
            b"require-plan-digest-match=true\n"
            b"history-retention-limit=2\n"
        ),
    )

    adapter.store.put(("agent",), "state", {"value": 1})
    receipt = adapter.receipt()

    assert adapter.store.get(("agent",), "state").value == {"value": 1}
    assert b"poo-flow-durable-adapter.v1" in receipt
    assert b"owner=scheme" in receipt
    assert b"backend=turso" in receipt


def test_turso_durable_adapter_runs_async_thread_workflow(tmp_path) -> None:
    async def load(state):
        await anyio.sleep(0)
        return {"value": 42}

    async def approve(state):
        await anyio.sleep(0)
        return RuntimeGraphInterrupt("approve")

    async def done(state):
        await anyio.sleep(0)
        return {"done": state["approved"]}

    program = RuntimeGraphProgram(
        plan=RuntimeGraphPlan(
            nodes=("load", "approve", "done"),
            edges=(
                RuntimeGraphEdge(START, "load"),
                RuntimeGraphEdge("load", "approve"),
                RuntimeGraphEdge("approve", "done"),
                RuntimeGraphEdge("done", END),
            ),
        ),
        registries=RuntimeGraphRegistries(
            actions={"load": load, "approve": approve, "done": done}
        ),
    )
    adapter = RuntimeDurableAdapter.turso(tmp_path / "thread.db")

    async def scenario() -> None:
        with pytest.raises(RuntimeGraphInterrupted):
            await program.ainvoke_thread("thread-1", {}, adapter.checkpointer)
        execution = await program.aresume_thread(
            "thread-1", {"approved": True}, adapter.checkpointer
        )
        assert execution.state["done"] is True

    anyio.run(scenario)
