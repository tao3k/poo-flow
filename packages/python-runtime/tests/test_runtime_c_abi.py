from __future__ import annotations

import pytest

from poo_flow_runtime import (
    END,
    START,
    PooFlowRuntimeBinding,
    PooFlowRuntimeError,
    Status,
)


MANIFEST = b"poo-flow-manifest.v1\npolicy-family=runtime-probe\n"
REQUEST = b"runtime=python\nstrategy=ctypes\n"


def test_validate_manifest_returns_receipt() -> None:
    binding = PooFlowRuntimeBinding.from_probe()
    with binding.context() as runtime:
        receipt = runtime.validate_manifest(MANIFEST)

    assert b"kind=manifest-validation\n" in receipt
    assert f"payload-bytes={len(MANIFEST)}\n".encode("ascii") in receipt


def test_plan_runtime_handoff_returns_receipt() -> None:
    binding = PooFlowRuntimeBinding.from_probe()
    with binding.context() as runtime:
        handoff = runtime.plan_runtime_handoff(REQUEST)

    assert b"kind=runtime-handoff\n" in handoff
    assert f"payload-bytes={len(REQUEST)}\n".encode("ascii") in handoff


def test_empty_manifest_is_rejected() -> None:
    binding = PooFlowRuntimeBinding.from_probe()
    with binding.context() as runtime:
        with pytest.raises(PooFlowRuntimeError) as error:
            runtime.validate_manifest(b"")

    assert error.value.status == Status.INVALID_MANIFEST
    assert error.value.status_name == "invalid-manifest"


def test_runtime_graph_plan_handoff_uses_c_abi_handle() -> None:
    binding = PooFlowRuntimeBinding.from_probe()
    request = b"runtime=python\nstrategy=ctypes-graph\n"

    with binding.graph_plan() as graph_plan:
        graph_plan.set_step_limit(16)
        graph_plan.add_node("manifest-validation")
        graph_plan.set_node_action("manifest-validation", "poo.validate-manifest")
        graph_plan.add_node("runtime-handoff")
        graph_plan.set_node_action("runtime-handoff", "poo.plan-runtime-graph-handoff")
        graph_plan.add_node("fallback")
        graph_plan.set_node_action("fallback", "poo.runtime-fallback")
        graph_plan.set_state_reducer("receipts", "poo.receipts.append")
        graph_plan.set_state_reducer("events", "poo.events.append")
        graph_plan.set_state_reducer("events", "poo.events.append-v2")
        graph_plan.add_edge(START, "manifest-validation")
        graph_plan.add_edge("manifest-validation", "runtime-handoff")
        graph_plan.add_edge("runtime-handoff", END)
        graph_plan.add_edge("fallback", END)
        graph_plan.add_conditional_route(
            source="manifest-validation",
            router="manifest-status",
            route_key="fallback",
            target="fallback",
        )

        description = graph_plan.describe()
        assert b"kind=runtime-graph-plan\n" in description
        assert b"nodes=3\n" in description
        assert b"node-actions=3\n" in description
        assert b"state-reducers=2\n" in description
        assert b"edges=4\n" in description
        assert b"conditional-routes=1\n" in description
        assert b"step-limit=16\n" in description

        validation = graph_plan.validate()
        assert b"kind=runtime-graph-validation\n" in validation
        assert b"nodes=3\n" in validation
        assert b"node-actions=3\n" in validation
        assert b"state-reducers=2\n" in validation
        validation_digest = _receipt_value(validation, b"plan-digest")

        with binding.context() as runtime:
            handoff = runtime.plan_runtime_graph_handoff(graph_plan, request)

    assert b"kind=runtime-graph-handoff\n" in handoff
    assert f"payload-bytes={len(request)}\n".encode("ascii") in handoff
    assert b"nodes=3\n" in handoff
    assert b"edges=4\n" in handoff
    assert _receipt_value(handoff, b"plan-digest") == validation_digest


def test_empty_runtime_graph_plan_is_rejected_by_c_abi() -> None:
    binding = PooFlowRuntimeBinding.from_probe()
    with binding.graph_plan() as graph_plan:
        with binding.context() as runtime:
            with pytest.raises(PooFlowRuntimeError) as error:
                runtime.plan_runtime_graph_handoff(graph_plan, b"request")

    assert error.value.status == Status.INVALID_ARGUMENT
    assert error.value.status_name == "invalid-argument"


def test_duplicate_runtime_graph_node_is_rejected_by_c_abi() -> None:
    binding = PooFlowRuntimeBinding.from_probe()
    with binding.graph_plan() as graph_plan:
        graph_plan.add_node("manifest-validation")
        with pytest.raises(PooFlowRuntimeError) as error:
            graph_plan.add_node("manifest-validation")

    assert error.value.status == Status.INVALID_GRAPH
    assert error.value.status_name == "invalid-graph"


def test_runtime_graph_node_action_requires_existing_node() -> None:
    binding = PooFlowRuntimeBinding.from_probe()
    with binding.graph_plan() as graph_plan:
        with pytest.raises(PooFlowRuntimeError) as error:
            graph_plan.set_node_action("missing", "poo.missing")

    assert error.value.status == Status.INVALID_GRAPH
    assert error.value.status_name == "invalid-graph"


def test_runtime_graph_plan_digest_changes_with_reducer_binding() -> None:
    binding = PooFlowRuntimeBinding.from_probe()
    with binding.graph_plan() as graph_plan:
        graph_plan.add_node("manifest-validation")
        graph_plan.add_edge(START, "manifest-validation")
        graph_plan.add_edge("manifest-validation", END)
        baseline = _receipt_value(graph_plan.validate(), b"plan-digest")

        graph_plan.set_state_reducer("receipts", "poo.receipts.append")
        changed = _receipt_value(graph_plan.validate(), b"plan-digest")

    assert changed != baseline


def _receipt_value(receipt: bytes, key: bytes) -> bytes:
    prefix = key + b"="
    for line in receipt.splitlines():
        if line.startswith(prefix):
            return line[len(prefix) :]
    raise AssertionError(f"missing receipt field: {key.decode('ascii')}")


def test_dangling_runtime_graph_edge_is_rejected_by_c_abi() -> None:
    binding = PooFlowRuntimeBinding.from_probe()
    with binding.graph_plan() as graph_plan:
        graph_plan.add_node("manifest-validation")
        graph_plan.add_edge(START, "manifest-validation")
        graph_plan.add_edge("manifest-validation", END)
        graph_plan.add_edge("manifest-validation", "missing")
        with pytest.raises(PooFlowRuntimeError) as error:
            graph_plan.validate()

    assert error.value.status == Status.INVALID_GRAPH
    assert error.value.status_name == "invalid-graph"


def test_runtime_graph_plan_without_start_or_end_is_rejected_by_c_abi() -> None:
    binding = PooFlowRuntimeBinding.from_probe()
    with binding.graph_plan() as graph_plan:
        graph_plan.add_node("manifest-validation")
        graph_plan.add_node("runtime-handoff")
        graph_plan.add_edge("manifest-validation", "runtime-handoff")
        with pytest.raises(PooFlowRuntimeError) as error:
            graph_plan.validate()

    assert error.value.status == Status.INVALID_GRAPH
    assert error.value.status_name == "invalid-graph"
