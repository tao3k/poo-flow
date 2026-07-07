from __future__ import annotations

import inspect

import poo_flow_runtime as runtime


RUNTIME_ABI_EXPORTS = {
    "PooFlowRuntimeBinding",
    "RUNTIME_ABI_ENTRYPOINTS",
    "RUNTIME_ABI_GATES",
    "RUNTIME_ABI_MANIFEST_SCHEMAS",
    "RUNTIME_ABI_RECEIPT_SCHEMAS",
    "RUNTIME_ABI_SURFACE_SCHEMA",
    "RUNTIME_DURABLE_ADAPTER_FACADE",
    "RuntimeAbiSurfaceError",
    "RuntimeAbiSurfaceManifest",
    "RuntimeDurableAdapter",
    "RuntimeDurableEnvelopeManifest",
    "RuntimeDurablePolicyError",
    "RuntimeDurablePolicyManifest",
    "RuntimeGraphBuilder",
    "RuntimeGraphProgram",
    "coerce_runtime_abi_surface_manifest",
    "coerce_runtime_durable_envelope_manifest",
    "coerce_runtime_durable_policy_manifest",
    "runtime_abi_surface_manifest",
    "runtime_abi_surface_manifest_bytes",
    "runtime_abi_surface_manifest_lines",
    "runtime_abi_surface_manifest_string",
}


DURABLE_ADAPTER_METHODS = {
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
}


def test_runtime_abi_public_exports_are_declared() -> None:
    exported = set(runtime.__all__)

    assert RUNTIME_ABI_EXPORTS <= exported
    for name in RUNTIME_ABI_EXPORTS:
        assert hasattr(runtime, name)


def test_durable_adapter_runtime_facade_is_public() -> None:
    adapter = runtime.RuntimeDurableAdapter

    for method in DURABLE_ADAPTER_METHODS:
        assert callable(getattr(adapter, method))


def test_durable_adapter_thread_facade_accepts_program_argument() -> None:
    invoke_signature = inspect.signature(runtime.RuntimeDurableAdapter.invoke_thread)
    resume_signature = inspect.signature(runtime.RuntimeDurableAdapter.resume_thread)

    assert tuple(invoke_signature.parameters)[:3] == ("self", "program", "thread_id")
    assert tuple(resume_signature.parameters)[:3] == ("self", "program", "thread_id")
