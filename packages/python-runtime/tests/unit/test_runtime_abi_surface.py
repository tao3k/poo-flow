from __future__ import annotations

import pytest

import poo_flow_runtime as runtime
from poo_flow_runtime.abi_surface_cli import main as abi_surface_main


def _parse_manifest_lines(payload: bytes) -> dict[str, str]:
    decoded = payload.decode("utf-8")
    return dict(line.split("=", 1) for line in decoded.splitlines() if line)


def test_runtime_abi_surface_manifest_describes_runtime_boundary() -> None:
    manifest = runtime.runtime_abi_surface_manifest()

    assert manifest["schema"] == runtime.RUNTIME_ABI_SURFACE_SCHEMA
    assert manifest["owner"] == "python-runtime"
    assert manifest["policy-owner"] == "scheme"
    assert manifest["runtime-role"] == "manifest-consumer"
    assert "RuntimeDurableAdapter" in manifest["entrypoints"]
    assert "poo-flow.durable.runtime-envelope.v1" in manifest["manifest-schemas"]
    assert "poo-flow.build-profile-gate.v1" in manifest["receipt-schemas"]


def test_runtime_abi_surface_bytes_are_line_manifest_carrier() -> None:
    fields = _parse_manifest_lines(runtime.runtime_abi_surface_manifest_bytes())

    assert fields["schema"] == "poo-flow.python-runtime.abi-surface.v1"
    assert fields["owner"] == "python-runtime"
    assert "RuntimeGraphProgram" in fields["entrypoints"].split(",")
    assert "RuntimeDurableAdapter" in fields["entrypoints"].split(",")
    assert "gxpkg build -g" in fields["gates"].split(",")


def test_runtime_abi_surface_manifest_coerces_generated_payload() -> None:
    manifest = runtime.coerce_runtime_abi_surface_manifest(
        runtime.runtime_abi_surface_manifest_bytes()
    )

    assert manifest.schema == runtime.RUNTIME_ABI_SURFACE_SCHEMA
    assert manifest.owner == "python-runtime"
    assert manifest.policy_owner == "scheme"
    assert manifest.runtime_role == "manifest-consumer"
    assert "RuntimeDurableAdapter" in manifest.entrypoints
    assert "resume_thread" in manifest.durable_adapter_facade
    assert manifest.receipt == runtime.runtime_abi_surface_manifest_bytes()


def test_runtime_abi_surface_rejects_unsupported_schema() -> None:
    with pytest.raises(runtime.RuntimeAbiSurfaceError, match="unsupported schema"):
        runtime.coerce_runtime_abi_surface_manifest(
            runtime.runtime_abi_surface_manifest_bytes().replace(
                b"poo-flow.python-runtime.abi-surface.v1",
                b"poo-flow.python-runtime.abi-surface.v0",
            )
        )


def test_runtime_abi_surface_rejects_missing_facade_method() -> None:
    with pytest.raises(runtime.RuntimeAbiSurfaceError, match="durable-adapter-facade"):
        runtime.coerce_runtime_abi_surface_manifest(
            runtime.runtime_abi_surface_manifest_bytes().replace(
                b",resume_thread,aresume_thread",
                b",aresume_thread",
            )
        )


def test_runtime_abi_surface_facade_matches_adapter_methods() -> None:
    for method in runtime.RUNTIME_DURABLE_ADAPTER_FACADE:
        assert callable(getattr(runtime.RuntimeDurableAdapter, method))


def test_runtime_abi_surface_cli_emits_manifest(capsys) -> None:
    exit_code = abi_surface_main([])

    captured = capsys.readouterr()
    fields = _parse_manifest_lines(captured.out.encode("utf-8"))

    assert exit_code == 0
    assert fields["schema"] == runtime.RUNTIME_ABI_SURFACE_SCHEMA
    assert "RuntimeDurableAdapter" in fields["entrypoints"].split(",")


def test_runtime_abi_surface_cli_validates_file(tmp_path, capsys) -> None:
    payload = tmp_path / "abi-surface.manifest"
    payload.write_bytes(runtime.runtime_abi_surface_manifest_bytes())

    exit_code = abi_surface_main(["--validate", str(payload)])

    captured = capsys.readouterr()
    fields = _parse_manifest_lines(captured.out.encode("utf-8"))
    assert exit_code == 0
    assert fields["schema"] == "poo-flow.python-runtime.abi-surface.validation.v1"
    assert fields["status"] == "ok"
    assert fields["detail"] == runtime.RUNTIME_ABI_SURFACE_SCHEMA


def test_runtime_abi_surface_cli_reports_invalid_file(tmp_path, capsys) -> None:
    payload = tmp_path / "abi-surface.manifest"
    payload.write_bytes(
        runtime.runtime_abi_surface_manifest_bytes().replace(
            b"poo-flow.python-runtime.abi-surface.v1",
            b"poo-flow.python-runtime.abi-surface.v0",
        )
    )

    exit_code = abi_surface_main(["--validate", str(payload)])

    captured = capsys.readouterr()
    fields = _parse_manifest_lines(captured.out.encode("utf-8"))
    assert exit_code == 1
    assert fields["schema"] == "poo-flow.python-runtime.abi-surface.validation.v1"
    assert fields["status"] == "fail"
    assert "unsupported schema" in fields["detail"]
