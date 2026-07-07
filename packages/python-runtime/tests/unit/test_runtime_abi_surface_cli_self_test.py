from types import SimpleNamespace

import pytest

from poo_flow_runtime import (
    RUNTIME_ABI_ENTRYPOINTS,
    RUNTIME_ABI_GATES,
    RUNTIME_ABI_RECEIPT_SCHEMAS,
    RUNTIME_ABI_SURFACE_VALIDATION_SCHEMA,
    RUNTIME_ABI_VALIDATION_ENTRYPOINTS,
    RUNTIME_DURABLE_ADAPTER_FACADE,
    RuntimeAbiSurfaceError,
    RuntimeAbiSurfaceManifest,
    RuntimeAbiSurfaceSelfTestError,
    RuntimeAbiSurfaceValidationReceipt,
    coerce_runtime_abi_surface_validation_receipt,
    runtime_abi_surface_self_test,
    runtime_abi_surface_self_test_receipt,
    runtime_abi_surface_validation_receipt,
)
from poo_flow_runtime import _abi_surface_self_test as self_test_module
from poo_flow_runtime.abi_surface_cli import main as abi_surface_main


def test_runtime_abi_gates_include_surface_self_test() -> None:
    assert "poo-flow-runtime-abi-surface --self-test" in RUNTIME_ABI_GATES


def test_runtime_abi_surface_self_test_checks_public_surface() -> None:
    manifest = runtime_abi_surface_self_test()

    assert isinstance(manifest, RuntimeAbiSurfaceManifest)
    assert manifest.schema == "poo-flow.python-runtime.abi-surface.v1"


def test_runtime_abi_surface_self_test_receipt_api() -> None:
    receipt = runtime_abi_surface_self_test_receipt()

    assert isinstance(receipt, RuntimeAbiSurfaceValidationReceipt)
    assert receipt.schema == RUNTIME_ABI_SURFACE_VALIDATION_SCHEMA
    assert receipt.status == "ok"
    assert receipt.detail == "poo-flow.python-runtime.abi-surface.v1"
    assert receipt.bytes() == receipt.string().encode("utf-8")


def test_runtime_abi_surface_manifest_lists_validation_receipt_schema() -> None:
    receipt = runtime_abi_surface_self_test_receipt()

    assert receipt.schema in RUNTIME_ABI_RECEIPT_SCHEMAS


def test_runtime_abi_surface_validation_receipt_lines() -> None:
    receipt = runtime_abi_surface_validation_receipt("fail", "missing entrypoint")

    assert receipt.lines() == (
        "schema=poo-flow.python-runtime.abi-surface.validation.v1",
        "status=fail",
        "detail=missing entrypoint",
    )


def test_runtime_abi_surface_validation_receipt_coerces_lines() -> None:
    source = runtime_abi_surface_validation_receipt("ok", "ready")

    receipt = coerce_runtime_abi_surface_validation_receipt(source.bytes())

    assert receipt == source


def test_runtime_abi_surface_validation_receipt_rejects_bad_status() -> None:
    with pytest.raises(RuntimeAbiSurfaceError, match="unsupported validation receipt status"):
        coerce_runtime_abi_surface_validation_receipt(
            {
                "schema": "poo-flow.python-runtime.abi-surface.validation.v1",
                "status": "maybe",
                "detail": "unknown",
            },
        )


def test_runtime_abi_surface_self_test_reports_missing_validation_entrypoint(
    monkeypatch,
) -> None:
    adapter_type = type("Adapter", (), {})
    for name in RUNTIME_DURABLE_ADAPTER_FACADE:
        setattr(adapter_type, name, object())
    runtime_package = SimpleNamespace(RuntimeDurableAdapter=adapter_type)
    for name in RUNTIME_ABI_ENTRYPOINTS:
        if name != "RuntimeDurableAdapter":
            setattr(runtime_package, name, object())
    missing_name = RUNTIME_ABI_VALIDATION_ENTRYPOINTS[-1]
    for name in RUNTIME_ABI_VALIDATION_ENTRYPOINTS[:-1]:
        setattr(runtime_package, name, object())

    monkeypatch.setattr(
        self_test_module,
        "import_module",
        lambda name: runtime_package,
    )

    with pytest.raises(RuntimeAbiSurfaceSelfTestError, match=missing_name):
        runtime_abi_surface_self_test()


def test_runtime_abi_surface_self_test_reports_missing_facade(monkeypatch) -> None:
    adapter_type = type("Adapter", (), {})
    missing_name = RUNTIME_DURABLE_ADAPTER_FACADE[-1]
    for name in RUNTIME_DURABLE_ADAPTER_FACADE[:-1]:
        setattr(adapter_type, name, object())
    runtime_package = SimpleNamespace(RuntimeDurableAdapter=adapter_type)
    for name in RUNTIME_ABI_ENTRYPOINTS:
        if name != "RuntimeDurableAdapter":
            setattr(runtime_package, name, object())
    for name in RUNTIME_ABI_VALIDATION_ENTRYPOINTS:
        setattr(runtime_package, name, object())

    monkeypatch.setattr(
        self_test_module,
        "import_module",
        lambda name: runtime_package,
    )

    with pytest.raises(RuntimeAbiSurfaceSelfTestError, match=missing_name):
        runtime_abi_surface_self_test()


def test_cli_self_test_emits_validation_receipt(capsys) -> None:
    assert abi_surface_main(["--self-test"]) == 0

    assert capsys.readouterr().out == (
        "schema=poo-flow.python-runtime.abi-surface.validation.v1\n"
        "status=ok\n"
        "detail=poo-flow.python-runtime.abi-surface.v1\n"
    )


def test_cli_validate_missing_file_emits_failure_receipt(capsys, tmp_path) -> None:
    missing_path = tmp_path / "missing.manifest"

    assert abi_surface_main(["--validate", str(missing_path)]) == 1

    output = capsys.readouterr().out
    assert output.startswith(
        "schema=poo-flow.python-runtime.abi-surface.validation.v1\n"
        "status=fail\n"
        "detail="
    )
    assert "missing.manifest" in output
