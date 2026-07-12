"""Own a negotiated runtime-v0 instance, Bundle, and session."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from types import TracebackType
from typing import Self

from .errors import NativeRuntimeError, NativeRuntimeLoadError
from .loader import BUNDLE_SCHEMA, NativeRuntimeHealth, native_library_path


@dataclass(frozen=True, slots=True)
class NativeBundleDescriptor:
    digest: bytes
    epoch: int
    canonical_packet: bytes
    digest_algorithm: int = 1
    schema: bytes = BUNDLE_SCHEMA

    def __post_init__(self) -> None:
        if len(self.digest) != 32:
            raise ValueError("native Bundle digest must be exactly 32 bytes")
        if self.epoch < 0:
            raise ValueError("native Bundle epoch cannot be negative")
        if not self.canonical_packet:
            raise ValueError("native Bundle canonical packet cannot be empty")


class NativeRuntimeSession:
    def __init__(
        self,
        bundle: NativeBundleDescriptor,
        *,
        library_path: str | Path | None = None,
    ) -> None:
        from ._runtime_v0_cffi import ffi, lib

        self._ffi = ffi
        self._lib = lib
        self._closed = False
        self._library_path = (
            Path(library_path).resolve()
            if library_path is not None
            else native_library_path()
        )
        schema = ffi.new("uint8_t[]", bundle.schema)
        identity_bytes = b"poo-flow-python-runtime"
        identity = ffi.new("uint8_t[]", identity_bytes)
        digest = ffi.new("uint8_t[]", bundle.digest)
        packet = ffi.new("uint8_t[]", bundle.canonical_packet)
        health = ffi.new("poo_flow_python_runtime_v0_health *")
        self._context = lib.poo_flow_python_runtime_v0_open(
            str(self._library_path).encode(),
            schema,
            len(bundle.schema),
            identity,
            len(identity_bytes),
            bundle.digest_algorithm,
            digest,
            len(bundle.digest),
            bundle.epoch,
            packet,
            len(bundle.canonical_packet),
            health,
        )
        if self._context == ffi.NULL:
            message = ffi.string(health.error).decode("utf-8", "replace")
            raise NativeRuntimeLoadError(message, status=int(health.status))
        self.health = NativeRuntimeHealth(
            self._library_path,
            int(health.abi_major),
            int(health.abi_minor),
            int(health.capabilities),
            int(health.max_payload_bytes),
        )

    @property
    def closed(self) -> bool:
        return self._closed

    def close(self) -> None:
        if self._closed:
            return
        status = int(self._lib.poo_flow_python_runtime_v0_close(self._context))
        self._context = self._ffi.NULL
        self._closed = True
        if status != 0:
            raise NativeRuntimeError("native runtime session close failed", status=status)

    def arena(
        self,
        buffer: bytearray | memoryview,
        *,
        generation: int = 1,
    ):
        if self._closed:
            raise NativeRuntimeError("native runtime session is closed")
        from .arena import NativeArena

        return NativeArena(self, buffer, generation=generation)

    def __enter__(self) -> Self:
        return self

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc: BaseException | None,
        traceback: TracebackType | None,
    ) -> None:
        self.close()

    def __del__(self) -> None:
        if not getattr(self, "_closed", True):
            try:
                self.close()
            except Exception:
                pass
