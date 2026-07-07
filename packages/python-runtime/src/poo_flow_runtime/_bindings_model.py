"""ctypes data model and helpers for the runtime C ABI."""

from __future__ import annotations

import ctypes
from enum import IntEnum


class Status(IntEnum):
    OK = 0
    INVALID_ARGUMENT = 1
    INVALID_MANIFEST = 2
    RUNTIME_REJECTED = 3
    INVALID_GRAPH = 4
    INTERNAL_ERROR = 5


class PooFlowRuntimeError(RuntimeError):
    def __init__(self, status: int, status_name: str) -> None:
        self.status = status
        self.status_name = status_name
        super().__init__(f"POO Flow runtime C ABI failed: {status_name} ({status})")


class PooFlowBytes(ctypes.Structure):
    _fields_ = [
        ("ptr", ctypes.POINTER(ctypes.c_uint8)),
        ("len", ctypes.c_size_t),
    ]


def payload_array(payload: bytes):
    return (ctypes.c_uint8 * len(payload)).from_buffer_copy(payload)


def string_arg(value: str) -> bytes:
    return value.encode("utf-8")
