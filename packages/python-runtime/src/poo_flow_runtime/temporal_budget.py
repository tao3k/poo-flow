# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Trusted host budget coordinator shared by Runtime C and Python.

Grants reserve their entire duration quantum, conservatively and durably.
Failed attempts do not refund it. No clock subtraction occurs between hosts.
This limits admitted publication duration; it does not preempt arbitrary CPU
work or establish clock accuracy beyond the host's monotonic timer.
"""
import hmac
import sqlite3
import threading
from pathlib import Path
from .temporal_selection import Publication, frame, MAX_VERSION


def root_payload(identity, parent, capacity, remaining, version):
    return b"".join(frame(str(value)) for value in (
        "poo-flow.temporal.budget-root.v1", identity, parent, capacity, remaining, version))


def lease_payload(budget, subject, scope, nonce, amount, state, publication):
    return b"".join(frame(str(value)) for value in (
        "poo-flow.temporal.budget-lease.v1", budget, subject, scope, nonce, amount, state)) + publication


class TemporalBudgetCoordinator:
    """Configured by the trusted host. Workers receive grants, never this key."""
    def __init__(self, path: Path | str, *, runtime_key: bytes):
        if not isinstance(runtime_key, bytes) or len(runtime_key) < 32 or str(path) in ("", ":memory:"):
            raise ValueError("persistent coordinator and host key are required")
        self._key = runtime_key
        self._lock = threading.Lock()
        self._db = sqlite3.connect(str(path), timeout=5, isolation_level=None, check_same_thread=False)
        self._db.execute("PRAGMA journal_mode=WAL")
        self._db.execute("PRAGMA synchronous=FULL")
        self._db.executescript("""
          CREATE TABLE IF NOT EXISTS temporal_budget_root_v1(
            id TEXT PRIMARY KEY,parent TEXT NOT NULL,capacity INTEGER NOT NULL,
            remaining INTEGER NOT NULL,version INTEGER NOT NULL,signature BLOB NOT NULL);
          CREATE TABLE IF NOT EXISTS temporal_budget_lease_v1(
            subject TEXT NOT NULL,scope TEXT NOT NULL,nonce TEXT NOT NULL,
            budget TEXT NOT NULL,amount INTEGER NOT NULL,state TEXT NOT NULL,
            payload BLOB NOT NULL,signature BLOB NOT NULL,PRIMARY KEY(subject,scope,nonce));
        """)

    def close(self):
        with self._lock:
            self._db.close()

    def _sign(self, payload):
        return hmac.digest(self._key, payload, "sha256")

    def _root(self, identity):
        row = self._db.execute("SELECT parent,capacity,remaining,version,signature FROM temporal_budget_root_v1 WHERE id=?", (identity,)).fetchone()
        if not row:
            raise ValueError("unknown budget")
        parent, capacity, remaining, version, signature = row
        if not (isinstance(parent, str) and all(type(v) is int for v in (capacity, remaining, version))
                and isinstance(signature, bytes) and len(signature) == 32
                and 0 <= remaining <= capacity <= MAX_VERSION and 0 <= version < MAX_VERSION) or not hmac.compare_digest(
                self._sign(root_payload(identity, parent, capacity, remaining, version)), signature):
            raise ValueError("corrupt budget root")
        return parent, capacity, remaining, version

    @staticmethod
    def _amount(amount):
        if type(amount) is not int or not 0 < amount <= MAX_VERSION:
            raise ValueError("duration quantum must be positive integer milliseconds")

    def _write_root(self, identity, parent, capacity, remaining, version):
        if not 0 <= version < MAX_VERSION:
            raise ValueError("budget version exhausted")
        self._db.execute("INSERT INTO temporal_budget_root_v1 VALUES(?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET remaining=excluded.remaining,version=excluded.version,signature=excluded.signature",
            (identity, parent, capacity, remaining, version, self._sign(root_payload(identity, parent, capacity, remaining, version))))

    def create(self, identity: str, capacity_ms: int):
        self._amount(capacity_ms)
        if not isinstance(identity, str) or not identity or "\0" in identity or len(identity.encode()) > 512:
            raise ValueError("invalid budget identity")
        with self._lock:
            self._db.execute("BEGIN IMMEDIATE")
            try:
                if self._db.execute("SELECT 1 FROM temporal_budget_root_v1 WHERE id=?", (identity,)).fetchone():
                    raise ValueError("budget identity cannot be recreated")
                self._write_root(identity, "", capacity_ms, capacity_ms, 0)
                self._db.execute("COMMIT")
            finally:
                if self._db.in_transaction: self._db.execute("ROLLBACK")

    def delegate(self, parent: str, child: str, amount_ms: int):
        self._amount(amount_ms)
        if not isinstance(child, str) or not child or "\0" in child or len(child.encode()) > 512:
            raise ValueError("invalid child budget")
        with self._lock:
            self._db.execute("BEGIN IMMEDIATE")
            try:
                ancestor, capacity, remaining, version = self._root(parent)
                if amount_ms > remaining: raise ValueError("parent budget exhausted")
                if self._db.execute("SELECT 1 FROM temporal_budget_root_v1 WHERE id=?", (child,)).fetchone():
                    raise ValueError("child identity cannot be reused")
                self._write_root(parent, ancestor, capacity, remaining - amount_ms, version + 1)
                self._write_root(child, parent, amount_ms, amount_ms, 0)
                self._db.execute("COMMIT")
            finally:
                if self._db.in_transaction: self._db.execute("ROLLBACK")

    def reserve(self, identity: str, publication: Publication, amount_ms: int):
        self._amount(amount_ms)
        payload = publication.payload()
        p = publication
        with self._lock:
            self._db.execute("BEGIN IMMEDIATE")
            try:
                parent, capacity, remaining, version = self._root(identity)
                existing = self._db.execute("SELECT budget,amount,state,payload,signature FROM temporal_budget_lease_v1 WHERE subject=? AND scope=? AND nonce=?",
                                           (p.subject, p.scope, p.nonce)).fetchone()
                if existing:
                    budget, amount, state, stored, signature = existing
                    if (budget, amount, stored) != (identity, amount_ms, payload) or state not in ("ready", "spent") or not isinstance(signature, bytes) or len(signature) != 32 or not hmac.compare_digest(
                            self._sign(lease_payload(budget, p.subject, p.scope, p.nonce, amount, state, stored)), signature):
                        raise ValueError("lease nonce collision or corruption")
                    return state
                if amount_ms > remaining: raise ValueError("duration budget exhausted")
                self._write_root(identity, parent, capacity, remaining - amount_ms, version + 1)
                signature = self._sign(lease_payload(identity, p.subject, p.scope, p.nonce, amount_ms, "ready", payload))
                self._db.execute("INSERT INTO temporal_budget_lease_v1 VALUES(?,?,?,?,?,?,?,?)",
                                (p.subject, p.scope, p.nonce, identity, amount_ms, "ready", payload, signature))
                self._db.execute("COMMIT")
                return "ready"
            finally:
                if self._db.in_transaction: self._db.execute("ROLLBACK")

    def remaining(self, identity):
        with self._lock:
            return self._root(identity)[2]


def activate_budget(db, key, budget, p, payload):
    """Spend once in a separate durable transaction before executing an attempt.

    A crash/conflict/deadline failure cannot restore an attempt grant. Exact
    durable effect replays go to the usual authenticated receipt lookup.
    """
    db.execute("BEGIN IMMEDIATE")
    try:
        effect = db.execute("SELECT payload FROM temporal_effect_v1 WHERE subject=? AND scope=? AND nonce=?", (p.subject, p.scope, p.nonce)).fetchone()
        if effect and effect[0] == payload:
            return "replay", 0
        row = db.execute("SELECT budget,amount,state,payload,signature FROM temporal_budget_lease_v1 WHERE subject=? AND scope=? AND nonce=?", (p.subject, p.scope, p.nonce)).fetchone()
        if not row: return "budget-exhausted", 0
        root, amount, state, stored, signature = row
        if not (isinstance(root, str) and type(amount) is int and isinstance(stored, bytes)
                and isinstance(signature, bytes) and len(signature) == 32):
            return "corrupt", 0
        expected = hmac.digest(key, lease_payload(root, p.subject, p.scope, p.nonce, amount, state, stored), "sha256")
        if amount <= 0 or state not in ("ready", "spent") or not hmac.compare_digest(expected, signature):
            return "corrupt", 0
        if root != budget or stored != payload or state != "ready": return "budget-exhausted", 0
        signature = hmac.digest(key, lease_payload(root, p.subject, p.scope, p.nonce, amount, "spent", payload), "sha256")
        db.execute("UPDATE temporal_budget_lease_v1 SET state='spent',signature=? WHERE subject=? AND scope=? AND nonce=?",
                   (signature, p.subject, p.scope, p.nonce))
        db.execute("COMMIT")
        return "ready", amount
    finally:
        if db.in_transaction: db.execute("ROLLBACK")
