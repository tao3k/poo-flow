import pytest

from poo_flow_runtime import (
    END,
    START,
    MemoryRuntimeGraphStore,
    RuntimeGraphEdge,
    RuntimeGraphExecutor,
    RuntimeGraphPlan,
    RuntimeGraphProgram,
    RuntimeGraphRegistries,
    RuntimeGraphRuntime,
    RuntimeGraphRuntimeError,
)


def test_runtime_graph_executor_injects_runtime_context() -> None:
    store = MemoryRuntimeGraphStore()
    runtime = RuntimeGraphRuntime.reference(thread_id="thread-1", store=store)
    executor = RuntimeGraphExecutor(
        RuntimeGraphPlan(
            nodes=("remember", "recall"),
            edges=(
                RuntimeGraphEdge(START, "remember"),
                RuntimeGraphEdge("remember", "recall"),
                RuntimeGraphEdge("recall", END),
            ),
        ),
        {
            "remember": lambda state, runtime: {
                "stored": runtime.require_store()
                .put(("threads", runtime.require_thread_id()), "value", state["value"])
                .key
            },
            "recall": lambda state, runtime: {
                "remembered": runtime.require_store()
                .get(("threads", runtime.require_thread_id()), "value")
                .value
            },
        },
        runtime=runtime,
    )

    state = executor.invoke({"value": 42})

    assert state["stored"] == "value"
    assert state["remembered"] == 42


def test_runtime_graph_program_injects_runtime_context() -> None:
    store = MemoryRuntimeGraphStore()
    runtime = RuntimeGraphRuntime.reference(thread_id="thread-1", store=store)
    program = RuntimeGraphProgram.reference(
        plan=RuntimeGraphPlan(
            nodes=("remember", "recall"),
            edges=(
                RuntimeGraphEdge(START, "remember"),
                RuntimeGraphEdge("remember", "recall"),
                RuntimeGraphEdge("recall", END),
            ),
        ),
        registries=RuntimeGraphRegistries(
            actions={
                "remember": lambda state, runtime: {
                    "stored": runtime.require_store()
                    .put(
                        ("threads", runtime.require_thread_id()),
                        "value",
                        state["value"],
                    )
                    .key
                },
                "recall": lambda state, runtime: {
                    "remembered": runtime.require_store()
                    .get(("threads", runtime.require_thread_id()), "value")
                    .value
                },
            }
        ),
        runtime=runtime,
    )

    execution = program.invoke_with_trace({"value": 42})

    assert execution.state["stored"] == "value"
    assert execution.state["remembered"] == 42
    assert execution.plan_digest is not None


def test_runtime_graph_runtime_requires_configured_resources() -> None:
    runtime = RuntimeGraphRuntime.reference()

    with pytest.raises(RuntimeGraphRuntimeError, match="thread_id"):
        runtime.require_thread_id()

    with pytest.raises(RuntimeGraphRuntimeError, match="store"):
        runtime.require_store()

    with pytest.raises(RuntimeGraphRuntimeError, match="checkpointer"):
        runtime.require_checkpointer()


def test_runtime_graph_runtime_native_backend_fails_closed_without_public_capability() -> None:
    runtime = RuntimeGraphRuntime()

    with pytest.raises(RuntimeGraphRuntimeError, match="negotiated native context"):
        runtime.require_native_context()


def test_runtime_graph_runtime_reference_backend_is_explicit() -> None:
    runtime = RuntimeGraphRuntime.reference()

    assert runtime.backend == "reference"
    with pytest.raises(RuntimeGraphRuntimeError, match="negotiated native context"):
        runtime.require_native_context()
