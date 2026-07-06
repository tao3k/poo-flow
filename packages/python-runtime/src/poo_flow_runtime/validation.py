"""Validation runtime built on the POO Flow runtime C ABI."""

from __future__ import annotations

from dataclasses import dataclass

from .bindings import PooFlowRuntimeBinding, PooFlowRuntimeError
from .runtime_graph import END, START, RuntimeGraphExecutor, linear_plan


@dataclass(frozen=True)
class RuntimeValidationInput:
    manifest: bytes
    request: bytes


@dataclass(frozen=True)
class RuntimeValidationResult:
    manifest_receipt: bytes
    handoff_receipt: bytes
    status: str


class RuntimeValidationFailure(RuntimeError):
    def __init__(self, phase: str, cause: PooFlowRuntimeError) -> None:
        self.phase = phase
        self.cause = cause
        super().__init__(
            f"POO Flow runtime validation failed during {phase}: "
            f"{cause.status_name}"
        )


class ValidationRuntime:
    """Runtime-language validation harness for POO Flow handoff checks."""

    def __init__(self, binding: PooFlowRuntimeBinding | None = None) -> None:
        self.binding = binding or PooFlowRuntimeBinding.from_probe()

    @classmethod
    def from_probe(cls) -> "ValidationRuntime":
        return cls(PooFlowRuntimeBinding.from_probe())

    def validate(self, value: RuntimeValidationInput) -> RuntimeValidationResult:
        with self.binding.graph_plan() as graph_plan:
            _build_validation_graph_plan(graph_plan)
            graph_plan.validate()
            with self.binding.context() as runtime:
                executor = RuntimeGraphExecutor(
                    linear_plan("manifest-validation", "runtime-handoff"),
                    {
                        "manifest-validation": lambda state: {
                            "manifest_receipt": _validate_manifest(runtime, state)
                        },
                        "runtime-handoff": lambda state: {
                            "handoff_receipt": _plan_runtime_graph_handoff(
                                runtime,
                                graph_plan,
                                state,
                            )
                        },
                    },
                )
                state = executor.invoke(
                    {
                        "manifest": value.manifest,
                        "request": value.request,
                    }
                )

        return RuntimeValidationResult(
            manifest_receipt=state["manifest_receipt"],
            handoff_receipt=state["handoff_receipt"],
            status="ok",
        )

    def describe_validation_graph(self) -> bytes:
        with self.binding.graph_plan() as graph_plan:
            _build_validation_graph_plan(graph_plan)
            return graph_plan.validate()


def runtime_request(*, runtime: str, strategy: str) -> bytes:
    return f"runtime={runtime}\nstrategy={strategy}\n".encode("utf-8")


def _build_validation_graph_plan(graph_plan: object) -> None:
    graph_plan.set_step_limit(16)
    graph_plan.add_node("manifest-validation")
    graph_plan.set_node_action("manifest-validation", "poo.validate-manifest")
    graph_plan.add_node("runtime-handoff")
    graph_plan.set_node_action("runtime-handoff", "poo.plan-runtime-graph-handoff")
    graph_plan.set_state_reducer("receipts", "poo.receipts.append")
    graph_plan.add_edge(START, "manifest-validation")
    graph_plan.add_edge("manifest-validation", "runtime-handoff")
    graph_plan.add_edge("runtime-handoff", END)


def _validate_manifest(runtime: object, state: dict[str, object]) -> bytes:
    try:
        return runtime.validate_manifest(state["manifest"])
    except PooFlowRuntimeError as exc:
        raise RuntimeValidationFailure("manifest-validation", exc) from exc


def _plan_runtime_graph_handoff(
    runtime: object,
    graph_plan: object,
    state: dict[str, object],
) -> bytes:
    try:
        return runtime.plan_runtime_graph_handoff(graph_plan, state["request"])
    except PooFlowRuntimeError as exc:
        raise RuntimeValidationFailure("runtime-handoff", exc) from exc




def main() -> None:
    value = RuntimeValidationInput(
        manifest=b"poo-flow-manifest.v1\npolicy-family=runtime-validation\n",
        request=runtime_request(runtime="python", strategy="ctypes"),
    )
    result = ValidationRuntime.from_probe().validate(value)
    assert result.status == "ok"
    assert b"kind=manifest-validation\n" in result.manifest_receipt
    assert b"kind=runtime-graph-handoff\n" in result.handoff_receipt
    print("python-runtime-validation: ok")
