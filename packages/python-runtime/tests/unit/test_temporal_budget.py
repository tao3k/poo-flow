# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
import concurrent.futures
from dataclasses import replace
import sqlite3
import time
import pytest
from poo_flow_runtime.temporal_budget import TemporalBudgetCoordinator
from poo_flow_runtime.temporal_selection import TemporalSelectionStore
from poo_flow_runtime.native_temporal_selection import NativeTemporalSelectionStore
from test_temporal_selection import KEYS, publication, signed, native_library


def runtime(kind, path, lib):
    args = dict(authorizer_key=KEYS[0], evaluator_key=KEYS[1], runtime_key=KEYS[2], budget='worker')
    return NativeTemporalSelectionStore(path, native_library=lib, **args) if kind == 'native' else TemporalSelectionStore(path, **args)


def coordinator(path):
    c = TemporalBudgetCoordinator(path, runtime_key=KEYS[2])
    c.create('parent', 2000)
    c.delegate('parent', 'worker', 1000)
    return c


@pytest.mark.parametrize('kind', ['python', 'native'])
def test_required_grant_and_cross_runtime_replay(kind, tmp_path, native_library):
    path = tmp_path / 'budget.sqlite'
    c = coordinator(path)
    r = runtime(kind, path, native_library)
    p = publication()
    assert r.publish(signed(p)).status == 'budget-exhausted'
    assert c.reserve('worker', p, 500) == 'ready'
    assert c.reserve('worker', p, 500) == 'ready'
    assert c.remaining('parent') == 1000 and c.remaining('worker') == 500
    assert r.publish(signed(replace(p, proof='other'))).status == 'budget-exhausted'
    assert r.publish(signed(p)).status == 'committed'
    assert c.reserve('worker', p, 500) == 'spent'
    r.close()
    other = runtime('native' if kind == 'python' else 'python', path, native_library)
    assert other.publish(signed(p)).status == 'replayed'
    assert c.remaining('worker') == 500
    other.close(); c.close()


@pytest.mark.parametrize('kind', ['python', 'native'])
def test_duration_overrun_rolls_back_without_refund(kind, tmp_path, native_library):
    path = tmp_path / 'overrun.sqlite'
    c = coordinator(path)
    p = publication()
    c.reserve('worker', p, 1)
    r = runtime(kind, path, native_library)
    original = r._runtime_signature
    def slow_signature(*args):
        if (kind == 'python' and args[0] == 'effect') or (kind == 'native' and b'poo-flow.temporal.effect.v1' in args[0]):
            time.sleep(0.01)
        return original(*args)
    r._runtime_signature = slow_signature
    assert r.publish(signed(p)).status == 'budget-exhausted'
    assert r.observe(p.subject, p.scope).status == 'absent'
    assert r.publish(signed(p)).status == 'budget-exhausted'
    assert c.remaining('worker') == 999
    assert c.reserve('worker', p, 1) == 'spent'
    r.close(); c.close()


@pytest.mark.parametrize('kind', ['python', 'native'])
def test_authenticated_lease_tamper(kind, tmp_path, native_library):
    path = tmp_path / 'tamper.sqlite'
    c = coordinator(path)
    p = publication()
    c.reserve('worker', p, 500)
    with sqlite3.connect(path) as db:
        db.execute('UPDATE temporal_budget_lease_v1 SET amount=900')
    r = runtime(kind, path, native_library)
    assert r.publish(signed(p)).status == 'corrupt'
    assert r.observe(p.subject, p.scope).status == 'absent'
    r.close(); c.close()


def test_parent_conservation_and_concurrent_reservation(tmp_path):
    path = tmp_path / 'competition.sqlite'
    a = coordinator(path)
    b = TemporalBudgetCoordinator(path, runtime_key=KEYS[2])
    def reserve(pair):
        c, nonce = pair
        try:
            return c.reserve('worker', publication(nonce=nonce), 600)
        except ValueError:
            return 'exhausted'
    with concurrent.futures.ThreadPoolExecutor(2) as workers:
        assert sorted(workers.map(reserve, [(a, 'one'), (b, 'two')])) == ['exhausted', 'ready']
    assert a.remaining('parent') == 1000 and b.remaining('worker') == 400
    with pytest.raises(ValueError): a.create('parent', 3000)
    with pytest.raises(ValueError): a.delegate('parent', 'worker', 100)
    with pytest.raises(ValueError): a.reserve('worker', publication(nonce='third'), 401)
    with sqlite3.connect(path) as db:
        db.execute("UPDATE temporal_budget_root_v1 SET remaining=2000 WHERE id='parent'")
    with pytest.raises(ValueError): a.remaining('parent')
    a.close(); b.close()


@pytest.mark.parametrize('kind', ['python', 'native'])
def test_crash_consumes_grant_before_publication(kind, tmp_path, native_library):
    import subprocess
    import sys
    from pathlib import Path
    path = tmp_path / 'crash.sqlite'
    c = coordinator(path)
    p = publication(expires_unix=2000000000)
    c.reserve('worker', p, 500)
    program = r"""
import os,runpy,sys
from pathlib import Path
sys.path.insert(0,str(Path(sys.argv[1]).parent))
ns=runpy.run_path(sys.argv[1])
kind,path,lib=sys.argv[2:]
r=ns['runtime'](kind,path,lib)
p=ns['publication'](expires_unix=2000000000)
original=r._runtime_signature
def crash(*args):
    if (kind=='python' and args[0]=='effect') or (kind=='native' and b'poo-flow.temporal.effect.v1' in args[0]): os._exit(73)
    return original(*args)
r._runtime_signature=crash
r.publish(ns['signed'](p))
"""
    result = subprocess.run([sys.executable, '-c', program, str(Path(__file__)), kind, str(path), str(native_library)], timeout=10)
    assert result.returncode == 73
    r = runtime('native' if kind == 'python' else 'python', path, native_library)
    assert r.observe(p.subject, p.scope).status == 'absent'
    assert r.publish(signed(p)).status == 'budget-exhausted'
    assert c.reserve('worker', p, 500) == 'spent'
    assert c.remaining('worker') == 500
    fresh = replace(p, nonce='fresh')
    c.reserve('worker', fresh, 500)
    assert r.publish(signed(fresh)).status == 'committed'
    assert c.remaining('worker') == 0
    r.close(); c.close()
