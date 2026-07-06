from __future__ import annotations

import pytest

from poo_flow_runtime import (
    RuntimeValidationFailure,
    RuntimeValidationInput,
    ValidationRuntime,
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


def test_validation_runtime_reports_manifest_phase_failure() -> None:
    runtime = ValidationRuntime.from_probe()

    with pytest.raises(RuntimeValidationFailure) as error:
        runtime.validate(RuntimeValidationInput(b"", REQUEST))

    assert error.value.phase == "manifest-validation"
    assert error.value.cause.status_name == "invalid-manifest"


def test_validation_runtime_exposes_c_abi_graph_validation_receipt() -> None:
    runtime = ValidationRuntime.from_probe()

    receipt = runtime.describe_validation_graph()

    assert b"kind=runtime-graph-validation\n" in receipt
    assert b"nodes=2\n" in receipt
    assert b"node-actions=2\n" in receipt
    assert b"state-reducers=1\n" in receipt
    assert b"edges=3\n" in receipt
    assert b"plan-digest=" in receipt
