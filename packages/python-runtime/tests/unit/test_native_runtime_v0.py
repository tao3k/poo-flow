from __future__ import annotations

from pathlib import Path

import pytest

from poo_flow_runtime._native.errors import NativeRuntimeLoadError
from poo_flow_runtime._native.loader import probe_native_runtime
from poo_flow_runtime._native.session import (
    NativeBundleDescriptor,
    NativeRuntimeSession,
)
from poo_flow_runtime._native.arena import NativeEvent
from poo_flow_runtime import (
    RuntimeGraphProgram,
    RuntimeGraphRegistries,
    RuntimeGraphRuntime,
    linear_plan,
)


def _repo_library() -> Path:
    return (
        Path(__file__).resolve().parents[4]
        / "bindings"
        / "runtime-c"
        / "build"
        / "libpoo_flow_runtime_v0.dylib"
    )


def test_native_runtime_override_negotiates_runtime_v0() -> None:
    pytest.importorskip("poo_flow_runtime._native._runtime_v0_cffi")
    library = _repo_library()
    if not library.is_file():
        pytest.skip("focused runtime-C build has not run")
    health = probe_native_runtime(library_path=library)
    assert (health.abi_major, health.abi_minor) == (0, 1)
    assert health.capabilities & 1


def test_native_runtime_missing_library_fails_closed(tmp_path: Path) -> None:
    pytest.importorskip("poo_flow_runtime._native._runtime_v0_cffi")
    with pytest.raises(NativeRuntimeLoadError, match="absent"):
        probe_native_runtime(library_path=tmp_path / "missing-runtime")


def test_native_runtime_session_owns_and_closes_full_control_chain() -> None:
    pytest.importorskip("poo_flow_runtime._native._runtime_v0_cffi")
    library = _repo_library()
    if not library.is_file():
        pytest.skip("focused runtime-C build has not run")
    bundle = NativeBundleDescriptor(bytes.fromhex("44" * 32), 7, b"bundle")
    with NativeRuntimeSession(bundle, library_path=library) as session:
        assert session.health.capabilities & 1
        assert not session.closed
    assert session.closed
    session.close()


def test_native_bundle_descriptor_rejects_noncanonical_shape() -> None:
    with pytest.raises(ValueError, match="32 bytes"):
        NativeBundleDescriptor(b"short", 1, b"bundle")
    with pytest.raises(ValueError, match="epoch"):
        NativeBundleDescriptor(bytes(32), -1, b"bundle")
    with pytest.raises(ValueError, match="canonical packet"):
        NativeBundleDescriptor(bytes(32), 1, b"")


def test_native_arena_roundtrip_is_batched_zero_copy_and_recyclable() -> None:
    pytest.importorskip("poo_flow_runtime._native._runtime_v0_cffi")
    library = _repo_library()
    if not library.is_file():
        pytest.skip("focused runtime-C build has not run")
    bundle = NativeBundleDescriptor(bytes.fromhex("55" * 32), 9, b"bundle")
    with NativeRuntimeSession(bundle, library_path=library) as session:
        with session.arena(bytearray(4096)) as arena:
            result = arena.roundtrip(
                (
                    NativeEvent(1, payload_length=16),
                    NativeEvent(2, payload_offset=64, payload_length=32),
                )
            )
            assert result.published_count == 2
            assert result.produced_count == 2
            assert result.accepted_count == 2
            assert result.item_statuses == (0, 0)
            assert result.accepted_bitmap == b"\x03"
            arena.recycle(2)
            assert arena.generation == 2


def test_runtime_graph_program_binds_execution_to_negotiated_native_context() -> None:
    pytest.importorskip("poo_flow_runtime._native._runtime_v0_cffi")
    library = _repo_library()
    if not library.is_file():
        pytest.skip("focused runtime-C build has not run")
    bundle = NativeBundleDescriptor(bytes.fromhex("66" * 32), 10, b"bundle")
    with NativeRuntimeSession(bundle, library_path=library) as session:
        runtime = RuntimeGraphRuntime.native(session)
        program = RuntimeGraphProgram(
            plan=linear_plan("native-step"),
            registries=RuntimeGraphRegistries(
                actions={"native-step": lambda state: {"value": state["value"] + 1}}
            ),
            runtime=runtime,
        )

        execution = program.invoke_with_trace({"value": 1})

        assert execution.state == {"value": 2}
        assert execution.plan_digest is not None
