# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Runtime C consumer of the same POO Temporal publication contract."""
from __future__ import annotations
import ctypes
import hmac
from threading import Lock
from pathlib import Path
from .temporal_selection import FIELDS, SignedPublication, PublicationEffect, PointerObservation, unframe


class _Request(ctypes.Structure):
    _fields_ = [(name, ctypes.c_char_p) for name in FIELDS] + [
        ("expected_version", ctypes.c_uint64), ("expires_unix", ctypes.c_uint64),
        ("authorization_signature", ctypes.c_ubyte * 32), ("evaluation_signature", ctypes.c_ubyte * 32)]


class _Effect(ctypes.Structure):
    _fields_ = [("status", ctypes.c_uint32), ("version", ctypes.c_uint64), ("effect_signature", ctypes.c_ubyte * 32)]


_Verify = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_void_p, ctypes.c_uint32,
                          ctypes.c_void_p, ctypes.c_size_t, ctypes.c_void_p)
_Sign = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_void_p, ctypes.c_void_p, ctypes.c_size_t, ctypes.c_void_p)
_STATUSES = ("committed", "conflict", "denied", "expired", "corrupt", "invalid", "storage-error", "replayed", "absent", "budget-exhausted")


class NativeTemporalSelectionStore:
    def __init__(self, path: Path | str, *, native_library: Path | str,
                 authorizer_key: bytes, evaluator_key: bytes, runtime_key: bytes, budget: str | None = None) -> None:
        if budget is not None and (not isinstance(budget, str) or not budget or "\0" in budget or len(budget.encode()) > 512):
            raise ValueError("invalid required budget")
        keys = (authorizer_key, evaluator_key, runtime_key)
        if any(not isinstance(key, bytes) or len(key) < 32 for key in keys) or len(set(keys)) != 3:
            raise ValueError("three distinct host keys of at least 32 bytes are required")
        self._runtime_key = keys[2]
        self._lib = ctypes.CDLL(str(native_library))
        self._handle = ctypes.c_void_p()
        self._lock = Lock()
        self._lib.poo_flow_temporal_open_v1.argtypes = [ctypes.c_char_p, _Verify, _Sign, ctypes.c_void_p,
                                                      ctypes.POINTER(ctypes.c_void_p)]
        self._lib.poo_flow_temporal_open_v1.restype = ctypes.c_int
        self._lib.poo_flow_temporal_close_v1.argtypes = [ctypes.c_void_p]
        self._lib.poo_flow_temporal_publish_selection_v1.argtypes = [ctypes.c_void_p, ctypes.POINTER(_Request),
                                                                   ctypes.POINTER(_Effect)]
        self._lib.poo_flow_temporal_publish_selection_v1.restype = ctypes.c_uint32
        self._lib.poo_flow_temporal_payload_v1.argtypes = [ctypes.POINTER(_Request), ctypes.c_void_p,
                                                         ctypes.c_size_t, ctypes.POINTER(ctypes.c_size_t)]
        self._lib.poo_flow_temporal_payload_v1.restype = ctypes.c_int
        self._lib.poo_flow_temporal_observe_selection_v1.argtypes = [ctypes.c_void_p, ctypes.c_char_p,
            ctypes.c_char_p, ctypes.c_void_p, ctypes.c_size_t, ctypes.POINTER(ctypes.c_size_t), ctypes.POINTER(_Effect)]
        self._lib.poo_flow_temporal_observe_selection_v1.restype = ctypes.c_uint32

        @_Verify
        def verify(_host, role, data, length, signature):
            if role not in (1, 2, 3):
                return 0
            expected = hmac.digest(keys[role - 1], ctypes.string_at(data, length), "sha256")
            return int(hmac.compare_digest(expected, ctypes.string_at(signature, 32)))

        @_Sign
        def sign(_host, data, length, signature):
            ctypes.memmove(signature, self._runtime_signature(ctypes.string_at(data, length)), 32)
            return 1

        self._verify, self._sign = verify, sign
        if not self._lib.poo_flow_temporal_open_v1(str(path).encode(), verify, sign, None, ctypes.byref(self._handle)):
            raise OSError("cannot open native Temporal selection store")

        self._lib.poo_flow_temporal_require_budget_v1.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
        self._lib.poo_flow_temporal_require_budget_v1.restype = ctypes.c_int
        if budget is not None and not self._lib.poo_flow_temporal_require_budget_v1(self._handle, budget.encode()):
            self.close()
            raise ValueError("native budget configuration rejected")

    def _runtime_signature(self, payload: bytes) -> bytes:
        return hmac.digest(self._runtime_key, payload, "sha256")

    def _request(self, request: SignedPublication) -> _Request:
        p = request.publication
        return _Request(*(getattr(p, field).encode("utf-8") for field in FIELDS), p.expected_version, p.expires_unix,
                        (ctypes.c_ubyte * 32).from_buffer_copy(request.authorization_signature),
                        (ctypes.c_ubyte * 32).from_buffer_copy(request.evaluation_signature))

    def payload(self, request: SignedPublication) -> bytes:
        request.publication.payload()
        native = self._request(request)
        length = ctypes.c_size_t()
        if not self._lib.poo_flow_temporal_payload_v1(ctypes.byref(native), None, 0, ctypes.byref(length)):
            raise ValueError("native projection rejected publication")
        buffer = ctypes.create_string_buffer(length.value)
        if not self._lib.poo_flow_temporal_payload_v1(ctypes.byref(native), buffer, length.value, ctypes.byref(length)):
            raise ValueError("native projection failed")
        return buffer.raw

    def publish(self, request: SignedPublication) -> PublicationEffect:
        with self._lock:
            return self._publish(request)

    def _publish(self, request: SignedPublication) -> PublicationEffect:
        if not self._handle.value:
            return PublicationEffect("storage-error")
        try:
            request.publication.payload()
        except (ValueError, AttributeError, UnicodeError):
            return PublicationEffect("invalid")
        signatures = (request.authorization_signature, request.evaluation_signature)
        if any(not isinstance(signature, bytes) or len(signature) != 32 for signature in signatures):
            return PublicationEffect("denied")
        native, result = self._request(request), _Effect()
        status = self._lib.poo_flow_temporal_publish_selection_v1(self._handle, ctypes.byref(native), ctypes.byref(result))
        if status >= len(_STATUSES):
            raise RuntimeError("unsupported native Temporal publication status")
        signature = bytes(result.effect_signature) if status in (0, 7) else b""
        return PublicationEffect(_STATUSES[status], result.version, signature)

    def observe(self, subject: str, scope: str) -> PointerObservation:
        if any(not isinstance(value, str) or not value or "\0" in value for value in (subject, scope)):
            return PointerObservation("invalid")
        with self._lock:
            if not self._handle.value:
                return PointerObservation("storage-error")
            buffer, length, result = ctypes.create_string_buffer(8192), ctypes.c_size_t(), _Effect()
            status = self._lib.poo_flow_temporal_observe_selection_v1(self._handle, subject.encode(), scope.encode(),
                buffer, len(buffer), ctypes.byref(length), ctypes.byref(result))
            if status != 0:
                return PointerObservation(_STATUSES[status])
            payload = buffer.raw[:length.value]
            return PointerObservation("committed", result.version, unframe(payload)[4], payload, bytes(result.effect_signature))

    def close(self) -> None:
        with self._lock:
            if self._handle.value:
                self._lib.poo_flow_temporal_close_v1(self._handle)
                self._handle = ctypes.c_void_p()
