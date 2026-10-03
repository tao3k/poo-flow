# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Durable execution of the scope-bound POO Temporal publication projection.

Authorizer, evaluator and runtime keys are configured by the host. Signatures
authenticate exact assertions by these issuers; they do not prove arbitrary
evaluator semantics. This adapter never treats a proof digest as a signature.
"""
from __future__ import annotations

from dataclasses import dataclass
import hmac
from pathlib import Path
import sqlite3
import threading
import time


FIELDS = (
    "subject", "scope", "predecessor", "revision", "proof", "policy",
    "generation", "cut", "projection", "journal", "model", "nonce", "operation",
)
SCHEMA = "poo-flow.temporal.publish.v1"
MAX_VERSION = (1 << 63) - 1


def frame(value: str) -> bytes:
    encoded = value.encode("utf-8")
    return str(len(encoded)).encode("ascii") + b":" + encoded + b","


def unframe(payload: bytes) -> tuple[str, ...]:
    values: list[str] = []
    position = 0
    while position < len(payload):
        colon = payload.find(b":", position)
        if colon < 0:
            raise ValueError("invalid netstring")
        number = payload[position:colon]
        if not number.isdigit() or (len(number) > 1 and number.startswith(b"0")):
            raise ValueError("invalid netstring length")
        length = int(number)
        end = colon + 1 + length
        if end >= len(payload) or payload[end:end + 1] != b",":
            raise ValueError("invalid netstring terminator")
        values.append(payload[colon + 1:end].decode("utf-8"))
        position = end + 1
    return tuple(values)


@dataclass(frozen=True)
class Publication:
    subject: str
    scope: str
    predecessor: str
    revision: str
    proof: str
    policy: str
    generation: str
    cut: str
    projection: str
    journal: str
    model: str
    nonce: str
    operation: str
    expected_version: int
    expires_unix: int

    @classmethod
    def from_payload(cls, payload: bytes) -> Publication:
        values = unframe(payload)
        if len(values) != 16 or values[0] != SCHEMA:
            raise ValueError("unsupported publication schema")
        if not values[14].isascii() or not values[14].isdigit() or not values[15].isascii() or not values[15].isdigit():
            raise ValueError("invalid publication integers")
        publication = cls(*values[1:14], int(values[14]), int(values[15]))
        if publication.payload() != payload:
            raise ValueError("noncanonical publication projection")
        return publication

    def payload(self) -> bytes:
        for name in FIELDS:
            value = getattr(self, name)
            if not isinstance(value, str) or "\0" in value or len(value.encode("utf-8")) > 512:
                raise ValueError(f"invalid publication field: {name}")
            if name != "predecessor" and not value:
                raise ValueError(f"empty publication field: {name}")
        if type(self.expected_version) is not int or not 0 <= self.expected_version < MAX_VERSION:
            raise ValueError("invalid expected version")
        if type(self.expires_unix) is not int or not 0 <= self.expires_unix <= MAX_VERSION:
            raise ValueError("invalid expiry")
        if self.operation == "assert":
            if self.expected_version or self.predecessor:
                raise ValueError("root assertion has a predecessor")
        elif self.operation in {"correct", "retract"}:
            if not self.expected_version or not self.predecessor:
                raise ValueError("revision has no predecessor")
        else:
            raise ValueError("unsupported revision operation")
        values = (SCHEMA, *(getattr(self, name) for name in FIELDS),
                  str(self.expected_version), str(self.expires_unix))
        return b"".join(frame(value) for value in values)


@dataclass(frozen=True)
class SignedPublication:
    publication: Publication
    authorization_signature: bytes
    evaluation_signature: bytes


@dataclass(frozen=True)
class PublicationEffect:
    status: str
    version: int = 0
    signature: bytes = b""


@dataclass(frozen=True)
class PointerObservation:
    status: str
    version: int = 0
    revision: str = ""
    payload: bytes = b""
    signature: bytes = b""


def receipt_payload(role: str, version: int, payload: bytes) -> bytes:
    return frame(f"poo-flow.temporal.{role}.v1") + frame(str(version)) + payload


class TemporalSelectionStore:
    def __init__(self, path: Path | str, *, authorizer_key: bytes,
                 evaluator_key: bytes, runtime_key: bytes, budget: str | None = None) -> None:
        keys = (authorizer_key, evaluator_key, runtime_key)
        if any(not isinstance(key, bytes) or len(key) < 32 for key in keys) or len(set(keys)) != 3:
            raise ValueError("three distinct host keys of at least 32 bytes are required")
        if not str(path) or str(path) == ":memory:":
            raise ValueError("publication requires a persistent SQLite path")
        if budget is not None and (not isinstance(budget, str) or not budget or "\0" in budget or len(budget.encode()) > 512):
            raise ValueError("invalid required budget identity")
        self._budget = budget
        self._keys = keys
        self._lock = threading.Lock()
        self._db = sqlite3.connect(str(path), timeout=5, isolation_level=None, check_same_thread=False)
        self._db.execute("PRAGMA journal_mode=WAL")
        self._db.execute("PRAGMA synchronous=FULL")
        self._db.executescript("""
            CREATE TABLE IF NOT EXISTS temporal_selection_v1(
                subject TEXT NOT NULL,scope TEXT NOT NULL,version INTEGER NOT NULL,
                revision TEXT NOT NULL,payload BLOB NOT NULL,signature BLOB NOT NULL,
                PRIMARY KEY(subject,scope));
            CREATE TABLE IF NOT EXISTS temporal_effect_v1(
                subject TEXT NOT NULL,scope TEXT NOT NULL,nonce TEXT NOT NULL,
                version INTEGER NOT NULL,payload BLOB NOT NULL,signature BLOB NOT NULL,
                PRIMARY KEY(subject,scope,nonce));
        """)

    def close(self) -> None:
        with self._lock:
            self._db.close()

    def _verify(self, key: bytes, payload: bytes, signature: bytes) -> bool:
        return isinstance(signature, bytes) and hmac.compare_digest(
            hmac.digest(key, payload, "sha256"), signature)

    def _runtime_signature(self, role: str, version: int, payload: bytes) -> bytes:
        return hmac.digest(self._keys[2], receipt_payload(role, version, payload), "sha256")

    def observe(self, subject: str, scope: str) -> PointerObservation:
        with self._lock:
            try:
                row = self._db.execute("SELECT version,revision,payload,signature FROM temporal_selection_v1 "
                                       "WHERE subject=? AND scope=?", (subject, scope)).fetchone()
                if row is None:
                    return PointerObservation("absent")
                version, revision, payload, signature = row
                values = unframe(payload)
                if version <= 0 or len(values) != 16 or values[0] != SCHEMA or (
                        values[1:3] != (subject, scope) or values[4] != revision or values[14] != str(version - 1)) or (
                        not self._verify(self._keys[2], receipt_payload("pointer", version, payload), signature)):
                    return PointerObservation("corrupt")
                return PointerObservation("committed", version, revision, payload, signature)
            except (ValueError, UnicodeError, TypeError):
                return PointerObservation("corrupt")
            except sqlite3.Error:
                return PointerObservation("storage-error")

    def publish(self, request: SignedPublication) -> PublicationEffect:
        started = time.monotonic_ns()
        p = request.publication
        try:
            payload = p.payload()
        except (ValueError, AttributeError, UnicodeError):
            return PublicationEffect("invalid")
        if not self._verify(self._keys[0], payload, request.authorization_signature) or not self._verify(
                self._keys[1], payload, request.evaluation_signature):
            return PublicationEffect("denied")
        with self._lock:
            try:
                grant = None
                if self._budget is not None:
                    from .temporal_budget import activate_budget
                    status, grant = activate_budget(self._db, self._keys[2], self._budget, p, payload)
                    if status not in ("ready", "replay"):
                        return PublicationEffect(status)
                    if status == "replay": grant = None
                self._db.execute("BEGIN IMMEDIATE")
                if int(time.time()) >= p.expires_unix:
                    return PublicationEffect("expired")
                row = self._db.execute("SELECT version,revision,payload,signature FROM temporal_selection_v1 "
                                       "WHERE subject=? AND scope=?", (p.subject, p.scope)).fetchone()
                version = 0
                selected = ""
                if row:
                    version, selected, stored, signature = row
                    try:
                        values = unframe(stored)
                        if len(values) != 16 or values[0] != SCHEMA or values[1:3] != (p.subject, p.scope) or (
                                values[4] != selected or values[14] != str(version - 1) or version <= 0):
                            return PublicationEffect("corrupt")
                    except (ValueError, UnicodeError):
                        return PublicationEffect("corrupt")
                    if not self._verify(self._keys[2], receipt_payload("pointer", version, stored), signature):
                        return PublicationEffect("corrupt")
                effect = self._db.execute("SELECT version,payload,signature FROM temporal_effect_v1 "
                                          "WHERE subject=? AND scope=? AND nonce=?",
                                          (p.subject, p.scope, p.nonce)).fetchone()
                if effect:
                    effect_version, stored, signature = effect
                    if stored != payload:
                        return PublicationEffect("denied")
                    if effect_version <= 0 or not self._verify(
                            self._keys[2], receipt_payload("effect", effect_version, stored), signature):
                        return PublicationEffect("corrupt")
                    return PublicationEffect("replayed", effect_version, signature)
                if version != p.expected_version or selected != p.predecessor:
                    return PublicationEffect("conflict", version)
                version += 1
                pointer_signature = self._runtime_signature("pointer", version, payload)
                self._db.execute("INSERT INTO temporal_selection_v1 VALUES(?,?,?,?,?,?) "
                                 "ON CONFLICT(subject,scope) DO UPDATE SET version=excluded.version,"
                                 "revision=excluded.revision,payload=excluded.payload,signature=excluded.signature",
                                 (p.subject, p.scope, version, p.revision, payload, pointer_signature))
                effect_signature = self._runtime_signature("effect", version, payload)
                self._db.execute("INSERT INTO temporal_effect_v1 VALUES(?,?,?,?,?,?)",
                                 (p.subject, p.scope, p.nonce, version, payload, effect_signature))
                if int(time.time()) >= p.expires_unix:
                    return PublicationEffect("expired")
                if grant is not None and (time.monotonic_ns() - started + 999999) // 1000000 > grant:
                    return PublicationEffect("budget-exhausted")
                self._db.execute("COMMIT")
                return PublicationEffect("committed", version, effect_signature)
            except sqlite3.Error:
                return PublicationEffect("storage-error")
            finally:
                if self._db.in_transaction:
                    self._db.execute("ROLLBACK")
