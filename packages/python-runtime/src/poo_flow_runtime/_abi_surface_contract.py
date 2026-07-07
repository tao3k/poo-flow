"""Runtime ABI surface constants and line-manifest emission."""

from __future__ import annotations

from typing import Any


RUNTIME_ABI_SURFACE_SCHEMA = "poo-flow.python-runtime.abi-surface.v1"
RUNTIME_ABI_SURFACE_VALIDATION_SCHEMA = (
    "poo-flow.python-runtime.abi-surface.validation.v1"
)

RUNTIME_ABI_ENTRYPOINTS = (
    "PooFlowRuntimeBinding",
    "PooFlowRuntimeCffiBinding",
    "RuntimeGraphBuilder",
    "RuntimeGraphProgram",
    "RuntimeDurablePolicyManifest",
    "RuntimeDurableEnvelopeManifest",
    "RuntimeDurableAdapter",
)

RUNTIME_ABI_VALIDATION_ENTRYPOINTS = (
    "coerce_runtime_abi_surface_manifest",
    "coerce_runtime_abi_surface_validation_receipt",
    "runtime_abi_surface_self_test",
    "runtime_abi_surface_self_test_receipt",
    "runtime_abi_surface_validation_receipt",
)

RUNTIME_DURABLE_ADAPTER_FACADE = (
    "turso",
    "turso_from_envelope",
    "receipt",
    "has",
    "ahas",
    "inspect",
    "ainspect",
    "history",
    "ahistory",
    "load_at",
    "aload_at",
    "update_state",
    "aupdate_state",
    "clear",
    "aclear",
    "invoke_thread",
    "ainvoke_thread",
    "resume_thread",
    "aresume_thread",
)

RUNTIME_ABI_MANIFEST_SCHEMAS = (
    "poo-flow.durable.runtime-policy-manifest.v1",
    "poo-flow.durable.runtime-envelope.v1",
)

RUNTIME_ABI_RECEIPT_SCHEMAS = (
    RUNTIME_ABI_SURFACE_VALIDATION_SCHEMA,
    "poo-flow-receipt.v1",
    "poo-flow-durable-adapter.v1",
    "poo-flow.build-profile.v1",
    "poo-flow.build-profile-gate.v1",
)

RUNTIME_ABI_GATES = (
    "gxpkg build -g",
    "poo-flow-runtime-abi-surface --self-test",
    "uv run --project packages/python-runtime python -m poo_flow_runtime.benchmarks langgraph-alignment --iterations 25 --fanout 8",
    "uv run --project packages/python-runtime python -m poo_flow_runtime.benchmarks composition --iterations 10 --fanout 8",
    "uv run --project packages/python-runtime pytest packages/python-runtime/tests --quiet --durations=12",
    "git diff --check",
    "uv run --project packages/python-runtime poo-flow-build-profile --cwd .",
)


def _join(values: tuple[str, ...]) -> str:
    return ",".join(values)


def runtime_abi_surface_manifest() -> dict[str, Any]:
    return {
        "schema": RUNTIME_ABI_SURFACE_SCHEMA,
        "owner": "python-runtime",
        "policy-owner": "scheme",
        "runtime-role": "manifest-consumer",
        "entrypoints": RUNTIME_ABI_ENTRYPOINTS,
        "validation-entrypoints": RUNTIME_ABI_VALIDATION_ENTRYPOINTS,
        "durable-adapter-facade": RUNTIME_DURABLE_ADAPTER_FACADE,
        "manifest-schemas": RUNTIME_ABI_MANIFEST_SCHEMAS,
        "receipt-schemas": RUNTIME_ABI_RECEIPT_SCHEMAS,
        "gates": RUNTIME_ABI_GATES,
    }


def runtime_abi_surface_manifest_lines() -> tuple[str, ...]:
    manifest = runtime_abi_surface_manifest()
    return (
        f"schema={manifest['schema']}",
        f"owner={manifest['owner']}",
        f"policy-owner={manifest['policy-owner']}",
        f"runtime-role={manifest['runtime-role']}",
        f"entrypoints={_join(manifest['entrypoints'])}",
        f"validation-entrypoints={_join(manifest['validation-entrypoints'])}",
        f"durable-adapter-facade={_join(manifest['durable-adapter-facade'])}",
        f"manifest-schemas={_join(manifest['manifest-schemas'])}",
        f"receipt-schemas={_join(manifest['receipt-schemas'])}",
        f"gates={_join(manifest['gates'])}",
    )


def runtime_abi_surface_manifest_string() -> str:
    return "\n".join(runtime_abi_surface_manifest_lines()) + "\n"


def runtime_abi_surface_manifest_bytes() -> bytes:
    return runtime_abi_surface_manifest_string().encode("utf-8")
