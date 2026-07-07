"""Validation runtime built on the POO Flow runtime C ABI."""

from __future__ import annotations

from dataclasses import dataclass

from .bindings import PooFlowRuntimeBinding, PooFlowRuntimeError
from .materialization import RuntimeGraphBindings
from .program import (
    RUNTIME_GRAPH_PLAN_STATE_KEY,
    RuntimeGraphProgram,
    RuntimeGraphRegistries,
)
from .receipts import RuntimeReceipt, parse_runtime_receipt
from .runtime_graph import linear_plan


@dataclass(frozen=True)
class RuntimeValidationInput:
    manifest: bytes
    request: bytes


@dataclass(frozen=True)
class RuntimeValidationResult:
    manifest_receipt: bytes
    handoff_receipt: bytes
    status: str
    graph_validation_receipt: bytes

    @property
    def manifest(self) -> RuntimeReceipt:
        return parse_runtime_receipt(self.manifest_receipt)

    @property
    def handoff(self) -> RuntimeReceipt:
        return parse_runtime_receipt(self.handoff_receipt)

    @property
    def graph_validation(self) -> RuntimeReceipt:
        return parse_runtime_receipt(self.graph_validation_receipt)

    @property
    def plan_digest(self) -> str | None:
        return self.handoff.plan_digest


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
        plan = runtime_validation_graph_plan()
        graph_bindings = runtime_validation_graph_bindings()
        with self.binding.context() as runtime:
            program = RuntimeGraphProgram(
                plan=plan,
                graph_bindings=graph_bindings,
                registries=RuntimeGraphRegistries(
                    actions={
                        "poo.validate-manifest": lambda state: {
                            "manifest_receipt": _validate_manifest(runtime, state)
                        },
                        "poo.plan-runtime-graph-handoff": lambda state: {
                            "handoff_receipt": _plan_runtime_graph_handoff(
                                runtime,
                                state,
                            )
                        },
                    },
                    reducers={
                        "poo.receipts.append": lambda current, incoming: (
                            current + incoming
                        )
                    },
                ),
                binding=self.binding,
            )
            execution = program.invoke_with_trace(
                {
                    "manifest": value.manifest,
                    "request": value.request,
                }
            )
            state = execution.state

        return RuntimeValidationResult(
            manifest_receipt=state["manifest_receipt"],
            handoff_receipt=state["handoff_receipt"],
            status="ok",
            graph_validation_receipt=execution.validation_receipt,
        )

    def describe_validation_graph(self) -> bytes:
        program = RuntimeGraphProgram(
            plan=runtime_validation_graph_plan(),
            graph_bindings=runtime_validation_graph_bindings(),
            binding=self.binding,
        )
        return program.describe()

    def describe_validation_graph_receipt(self) -> RuntimeReceipt:
        program = RuntimeGraphProgram(
            plan=runtime_validation_graph_plan(),
            graph_bindings=runtime_validation_graph_bindings(),
            binding=self.binding,
        )
        return program.describe_receipt()


def runtime_request(*, runtime: str, strategy: str) -> bytes:
    return f"runtime={runtime}\nstrategy={strategy}\n".encode("utf-8")


def runtime_validation_graph_plan() -> object:
    return linear_plan("manifest-validation", "runtime-handoff", step_limit=16)


def runtime_validation_graph_bindings() -> RuntimeGraphBindings:
    return RuntimeGraphBindings(
        node_actions={
            "manifest-validation": "poo.validate-manifest",
            "runtime-handoff": "poo.plan-runtime-graph-handoff",
        },
        state_reducers={"receipts": "poo.receipts.append"},
    )


def _validate_manifest(runtime: object, state: dict[str, object]) -> bytes:
    try:
        return runtime.validate_manifest(state["manifest"])
    except PooFlowRuntimeError as exc:
        raise RuntimeValidationFailure("manifest-validation", exc) from exc


def _plan_runtime_graph_handoff(
    runtime: object,
    state: dict[str, object],
) -> bytes:
    try:
        graph_plan = state[RUNTIME_GRAPH_PLAN_STATE_KEY]
        from .materialization import materialize_runtime_graph_plan

        with materialize_runtime_graph_plan(
            runtime._binding, graph_plan, runtime_validation_graph_bindings()
        ) as graph_handle:
            return runtime.plan_runtime_graph_handoff(graph_handle, state["request"])
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
    __import__("sys").stdout.write("python-runtime-validation: ok\n")
