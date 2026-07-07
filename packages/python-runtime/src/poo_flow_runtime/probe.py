"""Command-line probe for the Python runtime package."""

from __future__ import annotations

from .bindings import PooFlowRuntimeBinding, PooFlowRuntimeError, Status
from .materialization import RuntimeGraphBindings
from .program import RuntimeGraphProgram, RuntimeGraphRegistries
from .receipts import parse_runtime_receipt
from .runtime_graph import (
    END,
    START,
    RuntimeGraphConditionalEdge,
    RuntimeGraphEdge,
    RuntimeGraphPlan,
)
from .validation import RuntimeValidationInput, ValidationRuntime


MANIFEST = b"poo-flow-manifest.v1\npolicy-family=runtime-probe\n"
REQUEST = b"runtime=python\nstrategy=ctypes\n"


def run_probe() -> None:
    binding = PooFlowRuntimeBinding.from_probe(force_rebuild=True)
    with binding.context() as runtime:
        receipt = runtime.validate_manifest(MANIFEST)
        assert b"kind=manifest-validation\n" in receipt
        assert f"payload-bytes={len(MANIFEST)}\n".encode("ascii") in receipt

        handoff = runtime.plan_runtime_handoff(REQUEST)
        assert b"kind=runtime-handoff\n" in handoff
        assert f"payload-bytes={len(REQUEST)}\n".encode("ascii") in handoff

        try:
            runtime.validate_manifest(b"")
        except PooFlowRuntimeError as exc:
            assert exc.status == Status.INVALID_MANIFEST
        else:
            raise AssertionError("empty manifest should be rejected")

    validation = ValidationRuntime(binding)
    result = validation.validate(RuntimeValidationInput(MANIFEST, REQUEST))
    assert result.status == "ok"
    assert b"kind=manifest-validation\n" in result.manifest_receipt
    assert b"kind=runtime-graph-handoff\n" in result.handoff_receipt


def main() -> None:
    run_probe()
    __import__("sys").stdout.write("python-runtime-c-abi: ok\n")


def run_program_probe() -> None:
    plan = RuntimeGraphPlan(
        nodes=("classify", "accept", "reject", "audit"),
        edges=(
            RuntimeGraphEdge(START, "classify"),
            RuntimeGraphEdge("accept", "audit"),
            RuntimeGraphEdge("reject", "audit"),
            RuntimeGraphEdge("audit", END),
        ),
        conditional_edges=(
            RuntimeGraphConditionalEdge(
                "classify",
                "poo.route-classification",
                {"ok": "accept", "bad": "reject"},
            ),
        ),
        step_limit=16,
    )
    program = RuntimeGraphProgram(
        plan=plan,
        graph_bindings=RuntimeGraphBindings(
            node_actions={
                "classify": "poo.classify",
                "accept": "poo.accept",
                "reject": "poo.reject",
                "audit": "poo.audit",
            },
            state_reducers={"events": "poo.events.append"},
        ),
        registries=RuntimeGraphRegistries(
            actions={
                "poo.classify": lambda state: {
                    "route": "ok" if state["score"] > 0 else "bad",
                    "events": ["classify"],
                },
                "poo.accept": lambda state: {
                    "status": "accepted",
                    "events": ["accept"],
                },
                "poo.reject": lambda state: {
                    "status": "rejected",
                    "events": ["reject"],
                },
                "poo.audit": lambda state: {"events": ["audit"]},
            },
            routers={"poo.route-classification": lambda state: state["route"]},
            reducers={"poo.events.append": lambda current, incoming: current + incoming},
        ),
        binding=PooFlowRuntimeBinding.from_probe(),
    )

    receipt = program.describe_receipt()
    execution = program.invoke_with_trace(
        {"score": 1, "events": []},
        trace_key="trace",
    )

    assert receipt.kind == "runtime-graph-validation"
    assert receipt.integer("nodes") == 4
    assert receipt.integer("conditional-routes") == 2
    assert receipt.plan_digest is not None
    assert execution.state["status"] == "accepted"
    assert execution.state["events"] == ["classify", "accept", "audit"]
    assert execution.trace == ("classify", "accept", "audit")
    assert parse_runtime_receipt(program.describe()).plan_digest == receipt.plan_digest


def program_main() -> None:
    run_program_probe()
    __import__("sys").stdout.write("python-runtime-program: ok\n")


if __name__ == "__main__":
    main()
