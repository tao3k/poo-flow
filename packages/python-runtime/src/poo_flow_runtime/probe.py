"""Command-line probe for the Python runtime package."""

from __future__ import annotations

from .bindings import PooFlowRuntimeBinding, PooFlowRuntimeError, Status
from .validation import RuntimeValidationInput, ValidationRuntime


MANIFEST = b"poo-flow-manifest.v1\npolicy-family=runtime-probe\n"
REQUEST = b"runtime=python\nstrategy=ctypes\n"


def run_probe() -> None:
    binding = PooFlowRuntimeBinding.from_probe()
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
    print("python-runtime-c-abi: ok")


if __name__ == "__main__":
    main()
