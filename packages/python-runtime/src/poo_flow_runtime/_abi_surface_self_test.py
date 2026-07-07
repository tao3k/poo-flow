"""Runtime ABI surface completeness self-test."""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass
from importlib import import_module
from typing import Any

from ._abi_surface_contract import (
    RUNTIME_ABI_SURFACE_VALIDATION_SCHEMA,
    runtime_abi_surface_manifest_bytes,
)
from ._abi_surface_parse import (
    RuntimeAbiSurfaceError,
    RuntimeAbiSurfaceManifest,
    coerce_runtime_abi_surface_manifest,
)


class RuntimeAbiSurfaceSelfTestError(RuntimeAbiSurfaceError):
    """Raised when the generated ABI manifest diverges from public runtime API."""


@dataclass(frozen=True)
class RuntimeAbiSurfaceValidationReceipt:
    status: str
    detail: str
    schema: str = RUNTIME_ABI_SURFACE_VALIDATION_SCHEMA

    def lines(self) -> tuple[str, ...]:
        return (
            f"schema={self.schema}",
            f"status={self.status}",
            f"detail={self.detail}",
        )

    def string(self) -> str:
        return "\n".join(self.lines()) + "\n"

    def bytes(self) -> bytes:
        return self.string().encode("utf-8")


def runtime_abi_surface_self_test() -> RuntimeAbiSurfaceManifest:
    manifest = coerce_runtime_abi_surface_manifest(runtime_abi_surface_manifest_bytes())
    runtime_package = import_module("poo_flow_runtime")
    adapter_type = getattr(runtime_package, "RuntimeDurableAdapter", None)
    failures = (
        _missing_message("missing entrypoints", runtime_package, manifest.entrypoints),
        _missing_message(
            "missing validation entrypoints",
            runtime_package,
            manifest.validation_entrypoints,
        ),
        _missing_message(
            "missing durable adapter facade",
            adapter_type,
            manifest.durable_adapter_facade,
        ),
    )
    details = tuple(detail for detail in failures if detail)
    if details:
        raise RuntimeAbiSurfaceSelfTestError("; ".join(details))
    return manifest


def runtime_abi_surface_validation_receipt(
    status: str,
    detail: str,
) -> RuntimeAbiSurfaceValidationReceipt:
    return RuntimeAbiSurfaceValidationReceipt(status=status, detail=detail)


def coerce_runtime_abi_surface_validation_receipt(
    payload: bytes | str | Mapping[str, Any] | RuntimeAbiSurfaceValidationReceipt,
) -> RuntimeAbiSurfaceValidationReceipt:
    if isinstance(payload, RuntimeAbiSurfaceValidationReceipt):
        return payload
    if isinstance(payload, bytes):
        payload = payload.decode("utf-8")
    if isinstance(payload, str):
        payload = _parse_line_payload(payload)
    if not isinstance(payload, Mapping):
        raise RuntimeAbiSurfaceError("validation receipt payload must be mapping or lines")
    schema = _required_string(payload, "schema")
    status = _required_string(payload, "status")
    detail = _required_string(payload, "detail")
    if schema != RUNTIME_ABI_SURFACE_VALIDATION_SCHEMA:
        raise RuntimeAbiSurfaceError(f"unsupported validation receipt schema: {schema}")
    if status not in ("ok", "fail"):
        raise RuntimeAbiSurfaceError(f"unsupported validation receipt status: {status}")
    return RuntimeAbiSurfaceValidationReceipt(status=status, detail=detail)


def runtime_abi_surface_self_test_receipt() -> RuntimeAbiSurfaceValidationReceipt:
    try:
        manifest = runtime_abi_surface_self_test()
    except RuntimeAbiSurfaceError as exc:
        return runtime_abi_surface_validation_receipt("fail", str(exc))
    return runtime_abi_surface_validation_receipt("ok", manifest.schema)


def _missing_message(label: str, owner: Any, names: tuple[str, ...]) -> str | None:
    missing = tuple(name for name in names if not hasattr(owner, name))
    if not missing:
        return None
    return f"{label}: {','.join(missing)}"


def _parse_line_payload(payload: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    for raw_line in payload.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        name, separator, value = line.partition("=")
        if not separator:
            raise RuntimeAbiSurfaceError(f"invalid validation receipt line: {line}")
        fields[name] = value
    return fields


def _required_string(payload: Mapping[str, Any], name: str) -> str:
    value = payload.get(name)
    if not isinstance(value, str) or not value:
        raise RuntimeAbiSurfaceError(f"missing validation receipt field: {name}")
    return value
