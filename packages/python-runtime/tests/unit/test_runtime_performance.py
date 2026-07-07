import time

import pytest

from poo_flow_runtime import (
    END,
    START,
    MemoryRuntimeGraphCheckpointer,
    RuntimeGraphEdge,
    RuntimeGraphInterrupt,
    RuntimeGraphInterrupted,
    RuntimeGraphPlan,
    RuntimeGraphProgram,
    RuntimeGraphRegistries,
)
from poo_flow_runtime.bindings import PooFlowRuntimeBinding
import poo_flow_runtime.program as program_module


def _elapsed(fn, count: int = 1) -> float:
    started = time.perf_counter()
    for _ in range(count):
        fn()
    return time.perf_counter() - started


def test_runtime_c_abi_hot_binding_load_stays_fast() -> None:
    PooFlowRuntimeBinding.from_probe()

    elapsed = _elapsed(PooFlowRuntimeBinding.from_probe, 50)

    assert elapsed < 0.25


def test_runtime_c_abi_steady_rebuild_stays_bounded(tmp_path, monkeypatch) -> None:
    monkeypatch.setenv("POO_FLOW_RUNTIME_C_ABI_BUILD_DIR", str(tmp_path / "c-abi"))

    PooFlowRuntimeBinding.from_probe(force_rebuild=True)

    elapsed = _elapsed(lambda: PooFlowRuntimeBinding.from_probe(force_rebuild=True))

    assert elapsed < 3.0


def test_runtime_graph_program_invoke_stays_fast() -> None:
    binding = PooFlowRuntimeBinding.from_probe()
    plan = RuntimeGraphPlan(
        nodes=("load",),
        edges=(
            RuntimeGraphEdge(START, "load"),
            RuntimeGraphEdge("load", END),
        ),
    )
    program = RuntimeGraphProgram(
        plan=plan,
        registries=RuntimeGraphRegistries(actions={"load": lambda state: {"value": 1}}),
        binding=binding,
    )

    elapsed = _elapsed(lambda: program.invoke({}), 500)

    assert elapsed < 0.25


def test_runtime_graph_program_resume_reuses_injected_binding(monkeypatch) -> None:
    binding = PooFlowRuntimeBinding.from_probe()
    plan = RuntimeGraphPlan(
        nodes=("load", "pause", "done"),
        edges=(
            RuntimeGraphEdge(START, "load"),
            RuntimeGraphEdge("load", "pause"),
            RuntimeGraphEdge("pause", "done"),
            RuntimeGraphEdge("done", END),
        ),
    )
    program = RuntimeGraphProgram(
        plan=plan,
        registries=RuntimeGraphRegistries(
            actions={
                "load": lambda state: {"value": 1},
                "pause": lambda state: RuntimeGraphInterrupt("pause"),
                "done": lambda state: {"done": True},
            }
        ),
        binding=binding,
    )
    checkpointer = MemoryRuntimeGraphCheckpointer()

    with pytest.raises(RuntimeGraphInterrupted):
        program.invoke_thread("thread-1", {}, checkpointer)

    def fail_from_probe(*args, **kwargs):
        raise AssertionError("resume must reuse the injected binding")

    monkeypatch.setattr(program_module.PooFlowRuntimeBinding, "from_probe", fail_from_probe)

    execution = program.resume_thread("thread-1", {}, checkpointer)

    assert execution.state["done"] is True
