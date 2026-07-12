"""Typed failures for native runtime loading and negotiation."""

from __future__ import annotations


class NativeRuntimeError(RuntimeError):
    """Base error for the private runtime-v0 adapter."""

    def __init__(self, message: str, *, status: int | None = None) -> None:
        super().__init__(message)
        self.status = status


class NativeRuntimeLoadError(NativeRuntimeError):
    """The qualified native library could not be loaded or negotiated."""
