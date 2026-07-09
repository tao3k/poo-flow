"""Executable composition benchmark scenarios for runtime graph features."""

from __future__ import annotations

import time
from collections.abc import Callable, Mapping
from dataclasses import dataclass
from typing import Any

from ..builder import RuntimeGraphBuilder
from ..bindings import PooFlowRuntimeBinding
from ..checkpoints import MemoryRuntimeGraphCheckpointer, RuntimeGraphCheckpoint
from ..funflow import benchmark_funflow_cicd_sandbox_dag
from ..subgraphs import RuntimeGraphSubgraph
from ..validation import RuntimeValidationInput, ValidationRuntime

RuntimeState = Mapping[str, Any]


@dataclass(frozen=True, slots=True)
class CompositionBenchmarkCase:
    scenario: str
    iterations: int
    elapsed_micros: int
    detail: str


def run_composition_cases(
    *, iterations: int, fanout: int
) -> list[CompositionBenchmarkCase]:
    return [
        _run_strategy_combinator_pipeline(iterations),
        _run_durable_fanout_strategy(iterations, fanout),
        _run_nested_subgraph_stream_projection(iterations),
        _run_cabi_status_hot_call(iterations),
        _run_validation_workflow_round_trip(iterations),
        _run_funflow_cicd_sandbox_dag(iterations, fanout),
    ]


def _run_strategy_combinator_pipeline(iterations: int) -> CompositionBenchmarkCase:
    executor = _compile_strategy_pipeline()

    def invoke_pipeline() -> None:
        executor.invoke({"score": 1, "steps": ()})

    elapsed = _elapsed_micros(invoke_pipeline, iterations)
    return CompositionBenchmarkCase(
        scenario="strategy-combinator-pipeline",
        iterations=iterations,
        elapsed_micros=elapsed,
        detail="stages: 8; functional strategy pipeline compiled once and reused",
    )


def _run_durable_fanout_strategy(
    iterations: int, fanout: int
) -> CompositionBenchmarkCase:
    checkpointer = MemoryRuntimeGraphCheckpointer()
    executor = _compile_durable_fanout_executor(fanout)
    thread_id = "composition-benchmark-durable"
    checkpointer.save(
        RuntimeGraphCheckpoint(
            checkpoint_id="composition-benchmark-durable-initial",
            thread_id=thread_id,
            interrupt=None,
            node="start",
            step=0,
            state={},
            trace=(),
        )
    )

    def invoke_thread() -> None:
        state = executor.invoke({"value": 2, "fanout": fanout})
        checkpointer.update_state(thread_id, state, replace=True)
        checkpointer.history(thread_id)

    elapsed = _elapsed_micros(invoke_thread, iterations)
    return CompositionBenchmarkCase(
        scenario="durable-fanout-strategy",
        iterations=iterations,
        elapsed_micros=elapsed,
        detail="fanout reduction with durable thread checkpoints",
    )


def _run_nested_subgraph_stream_projection(iterations: int) -> CompositionBenchmarkCase:
    executor = _compile_nested_subgraph_executor()

    def consume_stream() -> None:
        tuple(executor.stream({"value": 3}, stream_mode="values"))

    elapsed = _elapsed_micros(consume_stream, iterations)
    return CompositionBenchmarkCase(
        scenario="nested-subgraph-stream-projection",
        iterations=iterations,
        elapsed_micros=elapsed,
        detail="subgraph action projected through runtime stream surface",
    )


def _run_cabi_status_hot_call(iterations: int) -> CompositionBenchmarkCase:
    binding = PooFlowRuntimeBinding.from_probe()

    def read_status_name() -> None:
        binding.status_name(0)

    elapsed = _elapsed_micros(read_status_name, iterations)
    return CompositionBenchmarkCase(
        scenario="cabi-status-hot-call",
        iterations=iterations,
        elapsed_micros=elapsed,
        detail="loaded C ABI binding hot status lookup",
    )


def _run_validation_workflow_round_trip(iterations: int) -> CompositionBenchmarkCase:
    runtime = ValidationRuntime.from_probe()
    runtime.describe_validation_graph_receipt()
    validation_input = RuntimeValidationInput(
        manifest=b'{"policy":"composition-benchmark"}',
        request=b'{"value":5}',
    )

    def validate_request() -> None:
        runtime.validate(validation_input)

    elapsed = _elapsed_micros(validate_request, iterations)
    return CompositionBenchmarkCase(
        scenario="validation-workflow-round-trip",
        iterations=iterations,
        elapsed_micros=elapsed,
        detail="manifest validation plus graph handoff workflow",
    )


def _run_funflow_cicd_sandbox_dag(
    iterations: int, fanout: int
) -> CompositionBenchmarkCase:
    receipt = benchmark_funflow_cicd_sandbox_dag(iterations=iterations, fanout=fanout)
    return CompositionBenchmarkCase(
        scenario="funflow-cicd-sandbox-dag",
        iterations=iterations,
        elapsed_micros=receipt.elapsed_micros,
        detail=(
            "AnyIO DAG+sandbox CI/CD runtime; "
            f"steps: {len(receipt.steps)}; "
            f"max-wave-width: {receipt.max_wave_width}; "
            f"trace: {'>'.join(receipt.trace)}"
        ),
    )


def _compile_strategy_pipeline():
    builder = RuntimeGraphBuilder()
    builder.add_sequence(tuple(_strategy_node(index) for index in range(8)))
    return builder.compile()


def _compile_durable_fanout_executor(fanout: int):
    builder = RuntimeGraphBuilder()
    builder.add_sequence(
        (
            ("fanout", _fanout_action(fanout)),
            ("reduce", _reduce_action),
        )
    )
    return builder.compile()


def _compile_nested_subgraph_executor():
    child = RuntimeGraphBuilder()
    child.add_sequence(
        (
            ("normalize", lambda state: {"value": int(state.get("value", 0))}),
            ("project", lambda state: {"projected": state["value"] * 3}),
        )
    )
    parent = RuntimeGraphBuilder()
    parent.add_sequence(
        (
            ("child", RuntimeGraphSubgraph(child.compile()).as_action()),
            ("summary", lambda state: {"summary": state["projected"] + 1}),
        )
    )
    return parent.compile()


def _strategy_node(index: int) -> tuple[str, Callable[[RuntimeState], dict[str, Any]]]:
    def transform(state: RuntimeState) -> dict[str, Any]:
        steps = tuple(state.get("steps", ()))
        return {
            "score": int(state.get("score", 0)) + index + 1,
            "steps": steps + (index,),
        }

    return (f"strategy-{index}", transform)


def _fanout_action(fanout: int) -> Callable[[RuntimeState], dict[str, Any]]:
    def action(state: RuntimeState) -> dict[str, Any]:
        value = int(state.get("value", 0))
        values = tuple(value + index for index in range(fanout))
        return {"fanout_values": values, "fanout_count": fanout}

    return action


def _reduce_action(state: RuntimeState) -> dict[str, Any]:
    values = tuple(state.get("fanout_values", ()))
    return {"fanout_total": sum(values), "fanout_count": len(values)}


def _elapsed_micros(call: Callable[[], None], iterations: int) -> int:
    call()
    started = time.perf_counter_ns()
    for _ in range(iterations):
        call()
    return (time.perf_counter_ns() - started) // 1_000
