# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
from __future__ import annotations
import concurrent.futures
from dataclasses import replace
import hmac
from pathlib import Path
import shutil
import sqlite3
import subprocess
import time

import pytest
from poo_flow_runtime.temporal_selection import (
    Publication, SignedPublication,
    TemporalSelectionStore, receipt_payload,
)

from poo_flow_runtime.native_temporal_selection import NativeTemporalSelectionStore

KEYS = (b"authorizer-" + b"a" * 32, b"evaluator-" + b"b" * 32, b"runtime-" + b"c" * 32)


def publication(**changes):
    root = Publication("subject", "scope", "", "root", "checked-proof", "policy", "generation",
                       "cut", "projection", "journal", "model", "nonce-root", "assert", 0,
                       int(time.time()) + 120)
    return replace(root, **changes)


def signed(p):
    payload = p.payload()
    return SignedPublication(p, hmac.digest(KEYS[0], payload, "sha256"),
                             hmac.digest(KEYS[1], payload, "sha256"))


def correction(**changes):
    return replace(publication(predecessor="root", revision="next", nonce="nonce-next", operation="correct",
                               expected_version=1), **changes)


@pytest.fixture(scope="module")
def native_library(tmp_path_factory):
    repo = Path(__file__).resolve().parents[4]
    output = tmp_path_factory.mktemp("temporal-native") / "selection.so"
    compiler = "/usr/bin/clang" if Path("/usr/bin/clang").exists() else shutil.which("cc")
    assert compiler, "a C11 compiler is required for the cross-runtime gate"
    subprocess.run([compiler, "-std=c11", "-Wall", "-Wextra", "-Werror", "-pedantic", "-shared", "-fPIC",
                    "-I", str(repo / "bindings/runtime-c/include"),
                    str(repo / "bindings/runtime-c/src/temporal_selection_v1.c"), "-lsqlite3", "-lpthread",
                    "-o", str(output)], check=True, timeout=30)
    return output


def store(kind, path, lib):
    if kind == "native":
        return NativeTemporalSelectionStore(path, native_library=lib, authorizer_key=KEYS[0],
                                            evaluator_key=KEYS[1], runtime_key=KEYS[2])
    return TemporalSelectionStore(path, authorizer_key=KEYS[0], evaluator_key=KEYS[1], runtime_key=KEYS[2])


@pytest.mark.parametrize("kind", ["python", "native"])
def test_authentication_scope_expiry_and_replay(kind, tmp_path, native_library):
    runtime = store(kind, tmp_path / "state.sqlite", native_library)
    request = signed(publication(subject="领域/subject:with,delimiters"))
    if kind == "native":
        assert runtime.payload(request) == request.publication.payload()
    for field in ("subject", "scope", "proof", "model", "cut", "projection", "policy", "generation", "journal"):
        forged = replace(request, publication=replace(request.publication, **{field: "other"}))
        assert runtime.publish(forged).status == "denied"
    assert runtime.publish(replace(request, authorization_signature=b"x" * 32)).status == "denied"
    assert runtime.publish(replace(request, evaluation_signature=b"x" * 32)).status == "denied"
    assert runtime.publish(signed(publication(expires_unix=1))).status == "expired"
    effect = runtime.publish(request)
    assert effect.status == "committed" and effect.version == 1
    assert effect.signature == hmac.digest(KEYS[2], receipt_payload("effect", 1, request.publication.payload()), "sha256")
    assert runtime.publish(request) == replace(effect, status="replayed")
    runtime.close()


@pytest.mark.parametrize("first,second", [("python", "native"), ("native", "python")])
def test_cross_runtime_recovery_competition_and_retraction(first, second, tmp_path, native_library):
    path = tmp_path / "shared.sqlite"
    a = store(first, path, native_library)
    assert a.publish(signed(publication())).status == "committed"
    a.close()
    a, b = store(first, path, native_library), store(second, path, native_library)
    one, two = signed(correction()), signed(correction(revision="rival", nonce="nonce-rival"))
    with concurrent.futures.ThreadPoolExecutor(2) as workers:
        effects = list(workers.map(lambda pair: pair[0].publish(pair[1]), [(a, one), (b, two)]))
    assert sorted(e.status for e in effects) == ["committed", "conflict"]
    winner = one if effects[0].status == "committed" else two
    a.close(); b.close()
    recovered = store(second, path, native_library)
    assert recovered.publish(winner).status == "replayed"
    tombstone = replace(winner.publication, predecessor=winner.publication.revision, revision="withdrawn",
                        nonce="nonce-retract", operation="retract", expected_version=2)
    assert recovered.publish(signed(tombstone)).status == "committed"
    assert recovered.publish(signed(correction(revision="stale", nonce="nonce-stale"))).status == "conflict"
    recovered.close()
    with sqlite3.connect(path) as db:
        assert db.execute("SELECT version,revision FROM temporal_selection_v1").fetchone() == (3, "withdrawn")
        assert db.execute("SELECT count(*) FROM temporal_effect_v1").fetchone() == (3,)


@pytest.mark.parametrize("kind", ["python", "native"])
def test_atomic_rollback_and_authenticated_recovery(kind, tmp_path, native_library):
    path = tmp_path / "state.sqlite"
    runtime = store(kind, path, native_library)
    assert runtime.publish(signed(publication())).status == "committed"
    with sqlite3.connect(path) as db:
        db.execute("CREATE TRIGGER fail_effect BEFORE INSERT ON temporal_effect_v1 BEGIN SELECT RAISE(FAIL,'injected storage failure'); END")
    assert runtime.publish(signed(correction())).status == "storage-error"
    runtime.close()
    with sqlite3.connect(path) as db:
        assert db.execute("SELECT version,revision FROM temporal_selection_v1").fetchone() == (1, "root")
        assert db.execute("SELECT count(*) FROM temporal_effect_v1").fetchone() == (1,)
        db.execute("DROP TRIGGER fail_effect")
        db.execute("UPDATE temporal_selection_v1 SET revision='tampered'")
    runtime = store(kind, path, native_library)
    assert runtime.publish(signed(correction())).status == "corrupt"
    runtime.close()


@pytest.mark.parametrize("kind", ["python", "native"])
def test_nonce_cannot_authorize_two_distinct_publications(kind, tmp_path, native_library):
    runtime = store(kind, tmp_path / "state.sqlite", native_library)
    assert runtime.publish(signed(publication())).status == "committed"
    replacement = signed(correction(nonce="nonce-root"))
    assert runtime.publish(replacement).status == "denied"
    runtime.close()


@pytest.mark.parametrize("kind", ["python", "native"])
def test_pointer_observation_binds_scope_and_signed_payload(kind, tmp_path, native_library):
    path = tmp_path / "state.sqlite"
    runtime = store(kind, path, native_library)
    assert runtime.observe("subject", "scope").status == "absent"
    request = signed(publication())
    assert runtime.publish(request).status == "committed"
    observed = runtime.observe("subject", "scope")
    assert (observed.status, observed.version, observed.revision) == ("committed", 1, "root")
    assert observed.payload == request.publication.payload()
    assert observed.signature == hmac.digest(KEYS[2], receipt_payload("pointer", 1, observed.payload), "sha256")
    assert runtime.observe("subject", "other-scope").status == "absent"
    with sqlite3.connect(path) as db:
        db.execute("UPDATE temporal_selection_v1 SET version=9")
    assert runtime.observe("subject", "scope").status == "corrupt"
    runtime.close()


@pytest.mark.parametrize("writer,reader", [("python", "native"), ("native", "python")])
@pytest.mark.parametrize("phase", ["between-writes", "after-commit"])
def test_process_crash_at_transaction_boundary(writer, reader, phase, tmp_path, native_library):
    import sys
    path = tmp_path / "crash.sqlite"
    runtime = store(reader, path, native_library)
    assert runtime.publish(signed(publication())).status == "committed"
    runtime.close()
    # Exit inside the trusted runtime signer after the pointer SQL write and
    # before the effect write. os._exit bypasses close, rollback and destructors.
    program = r"""
import os, runpy, sys
ns=runpy.run_path(sys.argv[1])
kind, path, library, phase=sys.argv[2:]
runtime=ns['store'](kind,path,library)
request=ns['signed'](ns['correction']())
if phase == 'between-writes':
    original=runtime._runtime_signature
    if kind == 'python':
        def crash(role,version,payload):
            if role == 'effect': os._exit(73)
            return original(role,version,payload)
    else:
        def crash(payload):
            if b'poo-flow.temporal.effect.v1' in payload[:40]: os._exit(73)
            return original(payload)
    runtime._runtime_signature=crash
result=runtime.publish(request)
assert result.status == 'committed', result
os._exit(74)
"""
    result = subprocess.run([sys.executable, "-c", program, str(Path(__file__).resolve()), writer,
                             str(path), str(native_library), phase], timeout=10)
    assert result.returncode == (73 if phase == "between-writes" else 74)
    recovered = store(reader, path, native_library)
    observed = recovered.observe("subject", "scope")
    assert observed.status == "committed"
    expected = 1 if phase == "between-writes" else 2
    assert observed.version == expected
    with sqlite3.connect(path) as db:
        assert db.execute("SELECT count(*) FROM temporal_effect_v1").fetchone() == (expected,)
    effect = recovered.publish(signed(correction()))
    assert effect.status == ("committed" if phase == "between-writes" else "replayed")
    recovered.close()


@pytest.mark.parametrize("kind", ["python", "native"])
def test_scheme_publication_projection_executes_in_both_runtimes(kind, tmp_path, native_library):
    fixture = Path(__file__).resolve().parents[1] / "fixtures/temporal-publication-v1.netstring"
    payload = fixture.read_bytes()
    p = Publication.from_payload(payload)
    assert p.subject == "领域/subject:with,delimiters"
    runtime = store(kind, tmp_path / "scheme.sqlite", native_library)
    request = signed(p)
    if kind == "native":
        assert runtime.payload(request) == payload
    result = runtime.publish(request)
    assert result.status == "committed" and result.version == 1
    assert runtime.observe(p.subject, p.scope).payload == payload
    assert runtime.publish(request).status == "replayed"
    runtime.close()
    with pytest.raises(ValueError):
        Publication.from_payload(payload.replace(b"1:0,", b"2:00,"))
