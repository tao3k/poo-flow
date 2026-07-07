"""Runtime ABI surface line-manifest validation."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from ._abi_surface_contract import (
    RUNTIME_ABI_ENTRYPOINTS,
    RUNTIME_ABI_GATES,
    RUNTIME_ABI_MANIFEST_SCHEMAS,
    RUNTIME_ABI_RECEIPT_SCHEMAS,
    RUNTIME_ABI_SURFACE_SCHEMA,
    RUNTIME_ABI_VALIDATION_ENTRYPOINTS,
    RUNTIME_DURABLE_ADAPTER_FACADE,
    runtime_abi_surface_manifest_bytes,
    runtime_abi_surface_manifest_string,
)


class RuntimeAbiSurfaceError(ValueError):
    pass


@dataclass(frozen=True)
class RuntimeAbiSurfaceManifest:
    schema: str
    owner: str
    policy_owner: str
    runtime_role: str
    entrypoints: tuple[str, ...]
    validation_entrypoints: tuple[str, ...]
    durable_adapter_facade: tuple[str, ...]
    manifest_schemas: tuple[str, ...]
    receipt_schemas: tuple[str, ...]
    gates: tuple[str, ...]
    receipt: bytes


def _join(values: tuple[str, ...]) -> str:
    return ",".join(values)


def _split_field(value: str) -> tuple[str, ...]:
    if not value:
        return ()
    return tuple(item for item in value.split(",") if item)


def _parse_line_manifest(payload: bytes) -> dict[str, str]:
    fields: dict[str, str] = {}
    for line in payload.decode("utf-8").splitlines():
        if not line:
            continue
        if "=" not in line:
            raise RuntimeAbiSurfaceError(f"invalid manifest line: {line!r}")
        key, value = line.split("=", 1)
        if not key:
            raise RuntimeAbiSurfaceError("manifest line has empty key")
        if key in fields:
            raise RuntimeAbiSurfaceError(f"duplicate manifest field: {key}")
        fields[key] = value
    return fields


def _sequence_field(payload: dict[str, Any], key: str) -> tuple[str, ...]:
    value = payload.get(key, ())
    if isinstance(value, str):
        return _split_field(value)
    return tuple(str(item) for item in value)


def _fields_from_dict(payload: dict[str, Any]) -> dict[str, str]:
    return {
        "schema": str(payload.get("schema", "")),
        "owner": str(payload.get("owner", "")),
        "policy-owner": str(payload.get("policy-owner", "")),
        "runtime-role": str(payload.get("runtime-role", "")),
        "entrypoints": _join(_sequence_field(payload, "entrypoints")),
        "validation-entrypoints": _join(
            _sequence_field(payload, "validation-entrypoints")
        ),
        "durable-adapter-facade": _join(
            _sequence_field(payload, "durable-adapter-facade")
        ),
        "manifest-schemas": _join(_sequence_field(payload, "manifest-schemas")),
        "receipt-schemas": _join(_sequence_field(payload, "receipt-schemas")),
        "gates": _join(_sequence_field(payload, "gates")),
    }


def _fields_and_receipt(
    payload: dict[str, Any] | bytes | str | None,
) -> tuple[dict[str, str], bytes]:
    if payload is None:
        payload = runtime_abi_surface_manifest_bytes()
    if isinstance(payload, str):
        payload = payload.encode("utf-8")
    if isinstance(payload, dict):
        return _fields_from_dict(payload), runtime_abi_surface_manifest_string().encode(
            "utf-8"
        )
    if isinstance(payload, bytes):
        return _parse_line_manifest(payload), payload
    raise RuntimeAbiSurfaceError(f"unsupported manifest payload: {type(payload)!r}")


def _require_fields(fields: dict[str, str]) -> None:
    required = (
        "schema",
        "owner",
        "policy-owner",
        "runtime-role",
        "entrypoints",
        "validation-entrypoints",
        "durable-adapter-facade",
        "manifest-schemas",
        "receipt-schemas",
        "gates",
    )
    missing = tuple(field for field in required if field not in fields)
    if missing:
        raise RuntimeAbiSurfaceError(f"missing manifest fields: {','.join(missing)}")


def _validate_identity(fields: dict[str, str]) -> None:
    if fields["schema"] != RUNTIME_ABI_SURFACE_SCHEMA:
        raise RuntimeAbiSurfaceError(f"unsupported schema: {fields['schema']}")
    if fields["owner"] != "python-runtime":
        raise RuntimeAbiSurfaceError(f"unsupported owner: {fields['owner']}")
    if fields["policy-owner"] != "scheme":
        raise RuntimeAbiSurfaceError(f"unsupported policy owner: {fields['policy-owner']}")
    if fields["runtime-role"] != "manifest-consumer":
        raise RuntimeAbiSurfaceError(
            f"unsupported runtime role: {fields['runtime-role']}"
        )


def _manifest_from_fields(
    fields: dict[str, str],
    receipt: bytes,
) -> RuntimeAbiSurfaceManifest:
    return RuntimeAbiSurfaceManifest(
        schema=fields["schema"],
        owner=fields["owner"],
        policy_owner=fields["policy-owner"],
        runtime_role=fields["runtime-role"],
        entrypoints=_split_field(fields["entrypoints"]),
        validation_entrypoints=_split_field(fields["validation-entrypoints"]),
        durable_adapter_facade=_split_field(fields["durable-adapter-facade"]),
        manifest_schemas=_split_field(fields["manifest-schemas"]),
        receipt_schemas=_split_field(fields["receipt-schemas"]),
        gates=_split_field(fields["gates"]),
        receipt=receipt,
    )


def _require_contains(
    field: str,
    actual: tuple[str, ...],
    required: tuple[str, ...],
) -> None:
    missing = tuple(item for item in required if item not in actual)
    if missing:
        raise RuntimeAbiSurfaceError(f"{field} missing required values: {','.join(missing)}")


def _validate_required_sets(manifest: RuntimeAbiSurfaceManifest) -> None:
    _require_contains("entrypoints", manifest.entrypoints, RUNTIME_ABI_ENTRYPOINTS)
    _require_contains(
        "validation-entrypoints",
        manifest.validation_entrypoints,
        RUNTIME_ABI_VALIDATION_ENTRYPOINTS,
    )
    _require_contains(
        "durable-adapter-facade",
        manifest.durable_adapter_facade,
        RUNTIME_DURABLE_ADAPTER_FACADE,
    )
    _require_contains(
        "manifest-schemas",
        manifest.manifest_schemas,
        RUNTIME_ABI_MANIFEST_SCHEMAS,
    )
    _require_contains(
        "receipt-schemas",
        manifest.receipt_schemas,
        RUNTIME_ABI_RECEIPT_SCHEMAS,
    )
    _require_contains("gates", manifest.gates, RUNTIME_ABI_GATES)


def coerce_runtime_abi_surface_manifest(
    payload: RuntimeAbiSurfaceManifest | dict[str, Any] | bytes | str | None = None,
) -> RuntimeAbiSurfaceManifest:
    if isinstance(payload, RuntimeAbiSurfaceManifest):
        return payload
    fields, receipt = _fields_and_receipt(payload)
    _require_fields(fields)
    _validate_identity(fields)
    manifest = _manifest_from_fields(fields, receipt)
    _validate_required_sets(manifest)
    return manifest
