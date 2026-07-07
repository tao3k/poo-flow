from __future__ import annotations

import pytest

from poo_flow_runtime import (
    RuntimeValidationFailure,
    RuntimeValidationInput,
    ValidationRuntime,
    parse_runtime_receipt,
    runtime_request,
)


MANIFEST = b"poo-flow-manifest.v1\npolicy-family=runtime-validation\n"
REQUEST = runtime_request(runtime="python", strategy="ctypes")


def test_validation_runtime_returns_handoff_result() -> None:
    runtime = ValidationRuntime.from_probe()

    result = runtime.validate(RuntimeValidationInput(MANIFEST, REQUEST))

    assert result.status == "ok"
    assert b"kind=manifest-validation\n" in result.manifest_receipt
    assert b"kind=runtime-graph-handoff\n" in result.handoff_receipt
    assert f"payload-bytes={len(MANIFEST)}\n".encode("ascii") in result.manifest_receipt
    assert f"payload-bytes={len(REQUEST)}\n".encode("ascii") in result.handoff_receipt
    assert result.manifest.kind == "manifest-validation"
    assert result.handoff.kind == "runtime-graph-handoff"
    assert result.plan_digest == result.handoff.plan_digest
    assert result.graph_validation.kind == "runtime-graph-validation"
    assert result.graph_validation.plan_digest == result.handoff.plan_digest


def test_validation_runtime_reports_manifest_phase_failure() -> None:
    runtime = ValidationRuntime.from_probe()

    with pytest.raises(RuntimeValidationFailure) as error:
        runtime.validate(RuntimeValidationInput(b"", REQUEST))

    assert error.value.phase == "manifest-validation"
    assert error.value.cause.status_name == "invalid-manifest"


def test_validation_runtime_exposes_c_abi_graph_validation_receipt() -> None:
    runtime = ValidationRuntime.from_probe()

    receipt = runtime.describe_validation_graph()
    parsed = parse_runtime_receipt(receipt)

    assert parsed.kind == "runtime-graph-validation"
    assert parsed.integer("nodes") == 2
    assert parsed.integer("node-actions") == 2
    assert parsed.integer("state-reducers") == 1
    assert parsed.integer("edges") == 3
    assert parsed.plan_digest is not None


def test_validation_runtime_exposes_typed_graph_validation_receipt() -> None:
    runtime = ValidationRuntime.from_probe()

    receipt = runtime.describe_validation_graph_receipt()

    assert receipt.kind == "runtime-graph-validation"
    assert receipt.integer("nodes") == 2
    assert receipt.integer("node-actions") == 2
    assert receipt.plan_digest is not None
