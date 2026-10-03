# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Typed out-of-line CFFI consumer of the native Temporal publication ABI."""
from __future__ import annotations
import hmac
import os
from threading import Lock
from pathlib import Path
from .temporal_selection import FIELDS, SignedPublication, PublicationEffect, PointerObservation, unframe

_STATUSES = ("committed", "conflict", "denied", "expired", "corrupt", "invalid", "storage-error", "replayed", "absent", "budget-exhausted")


class NativeTemporalSelectionStore:
    def __init__(self, path: Path | str, *, native_library: Path | str,
                 authorizer_key: bytes, evaluator_key: bytes, runtime_key: bytes, budget: str | None = None) -> None:
        if budget is not None and (not isinstance(budget, str) or not budget or "\0" in budget or len(budget.encode()) > 512):
            raise ValueError("invalid required budget")
        keys = (authorizer_key, evaluator_key, runtime_key)
        if any(not isinstance(key, bytes) or len(key) < 32 for key in keys) or len(set(keys)) != 3:
            raise ValueError("three distinct host keys of at least 32 bytes are required")
        from ._native._runtime_v0_cffi import ffi, lib
        self._ffi, self._lib = ffi, lib
        self._runtime_key = keys[2]
        self._lock = Lock()
        self._handle = ffi.NULL
        self._api = ffi.new('poo_flow_python_temporal_api_v1 *')
        if not lib.poo_flow_python_temporal_bind_v1(os.fsencode(native_library), self._api):
            raise OSError("cannot bind native Temporal publication ABI")

        @ffi.callback('int(void *, uint32_t, const uint8_t *, size_t, const uint8_t *)', error=0)
        def verify(_host, role, data, length, signature):
            if role not in (1, 2, 3): return 0
            expected = hmac.digest(keys[role - 1], bytes(ffi.buffer(data, length)), 'sha256')
            return int(hmac.compare_digest(expected, bytes(ffi.buffer(signature, 32))))

        @ffi.callback('int(void *, const uint8_t *, size_t, uint8_t *)', error=0)
        def sign(_host, data, length, signature):
            value = self._runtime_signature(bytes(ffi.buffer(data, length)))
            if len(value) != 32: return 0
            ffi.buffer(signature, 32)[:] = value
            return 1

        self._verify, self._sign = verify, sign
        handle = ffi.new('poo_flow_temporal_store_v1 **')
        if not self._api.open(os.fsencode(path), verify, sign, ffi.NULL, handle):
            lib.poo_flow_python_temporal_unbind_v1(self._api)
            raise OSError("cannot open native Temporal selection store")
        self._handle = handle[0]
        if budget is not None and not self._api.require_budget(self._handle, budget.encode()):
            self.close()
            raise ValueError("native budget configuration rejected")

    def _runtime_signature(self, payload: bytes) -> bytes:
        return hmac.digest(self._runtime_key, payload, 'sha256')

    def _request(self, request: SignedPublication):
        ffi = self._ffi
        native = ffi.new('poo_flow_temporal_publish_v1 *')
        strings = [ffi.new('char[]', getattr(request.publication, field).encode('utf-8')) for field in FIELDS]
        for field, value in zip(FIELDS, strings): setattr(native, field, value)
        native.expected_version = request.publication.expected_version
        native.expires_unix = request.publication.expires_unix
        for field in ('authorization_signature', 'evaluation_signature'):
            signature = getattr(request, field)
            if not isinstance(signature, bytes) or len(signature) != 32:
                raise ValueError('invalid signature size')
            self._ffi.buffer(getattr(native, field), 32)[:] = signature
        # Struct pointer fields do not retain pointed-to Python allocations.
        return native, strings

    def payload(self, request: SignedPublication) -> bytes:
        request.publication.payload()
        with self._lock:
            if self._handle == self._ffi.NULL: raise ValueError('native store is closed')
            native, keepalive = self._request(request)
            length = self._ffi.new('size_t *')
            if not self._api.payload(native, self._ffi.NULL, 0, length):
                raise ValueError('native projection rejected publication')
            buffer = self._ffi.new('uint8_t[]', length[0])
            if not self._api.payload(native, buffer, length[0], length):
                raise ValueError('native projection failed')
            return bytes(self._ffi.buffer(buffer, length[0]))

    def publish(self, request: SignedPublication) -> PublicationEffect:
        with self._lock: return self._publish(request)

    def _publish(self, request: SignedPublication) -> PublicationEffect:
        if self._handle == self._ffi.NULL: return PublicationEffect('storage-error')
        try: request.publication.payload()
        except (ValueError, AttributeError, UnicodeError): return PublicationEffect('invalid')
        signatures = (request.authorization_signature, request.evaluation_signature)
        if any(not isinstance(s, bytes) or len(s) != 32 for s in signatures): return PublicationEffect('denied')
        native, keepalive = self._request(request)
        result = self._ffi.new('poo_flow_temporal_effect_v1 *')
        status = self._api.publish(self._handle, native, result)
        if status >= len(_STATUSES): raise RuntimeError('unsupported native Temporal publication status')
        signature = bytes(self._ffi.buffer(result.effect_signature, 32)) if status in (0, 7) else b''
        return PublicationEffect(_STATUSES[status], result.version, signature)

    def observe(self, subject: str, scope: str) -> PointerObservation:
        if any(not isinstance(v, str) or not v or '\0' in v for v in (subject, scope)): return PointerObservation('invalid')
        with self._lock:
            if self._handle == self._ffi.NULL: return PointerObservation('storage-error')
            buffer = self._ffi.new('uint8_t[8192]')
            length = self._ffi.new('size_t *')
            result = self._ffi.new('poo_flow_temporal_effect_v1 *')
            status = self._api.observe(self._handle, subject.encode(), scope.encode(), buffer, 8192, length, result)
            if status >= len(_STATUSES): raise RuntimeError('unsupported native Temporal observation status')
            if status != 0: return PointerObservation(_STATUSES[status])
            payload = bytes(self._ffi.buffer(buffer, length[0]))
            return PointerObservation('committed', result.version, unframe(payload)[4], payload,
                                      bytes(self._ffi.buffer(result.effect_signature, 32)))

    def close(self) -> None:
        with self._lock:
            if self._handle != self._ffi.NULL:
                self._api.close(self._handle)
                self._handle = self._ffi.NULL
                self._lib.poo_flow_python_temporal_unbind_v1(self._api)
