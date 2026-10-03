# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Qualify the actual ASCENT handoff through both durable publication runtimes."""
import argparse
from dataclasses import replace
import hashlib
import hmac
import json
import os
from pathlib import Path
import subprocess
import sys

from poo_flow_runtime.temporal_evaluator import NativeTemporalEvaluator
from poo_flow_runtime.temporal_selection import Publication, SignedPublication, TemporalSelectionStore, receipt_payload
from poo_flow_runtime.native_temporal_selection import NativeTemporalSelectionStore
from poo_flow_runtime.temporal_budget import TemporalBudgetCoordinator

REPO = Path(__file__).resolve().parents[2]


def qualify(directory):
    directory = Path(directory)
    preload = '(port-settings-set! (current-output-port) (list buffering: #f)) (load "scripts/temporal/preload.ss") ' + ' '.join(
        '(temporal-preload-module ' + json.dumps(module) + ')' for module in (
            'poo-flow/modules/temporal-causality/candidates/ascent/runtime',
            'poo-flow/modules/temporal-causality/interface',
            'poo-flow/scripts/temporal/exit-child-process',
            'gerbil/tools/gxtest', 'core/observability/testing-case'))
    code = '''(begin (import :gerbil/tools/gxtest :poo-flow/scripts/temporal/exit-child-process
      (rename-in "t/temporal-ascent-provider-test.ss" (main provider-handoff)))
      (let (status (main "-v" "6" "t/temporal-ascent-provider-test.ss" "t/temporal-candidate-exchange-test.ss" "t/temporal-model-test.ss"))
       (unless (zero? status) (temporal-child-process-exit! status)))
      (provider-handoff) (temporal-child-process-exit! 0))'''
    handoff = None
    with (directory / 'native-gate.log').open('w') as log:
        child = subprocess.Popen([sys.executable, 'scripts/temporal/run_with_progress.py', '--timeout', '180', '--',
            'gxi', '-e', preload, '-e', code], cwd=REPO, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        for line in child.stdout:
            log.write(line); log.flush()
            print(line, end='', flush=True)
            if line.startswith('ASCENT-HANDOFF '): handoff = json.loads(line[len('ASCENT-HANDOFF '):])
        child.stdout.close()
        if child.wait() != 0: raise RuntimeError('native ASCENT qualification failed')
    gate = (directory / 'native-gate.log').read_text()
    required = ('t/temporal-ascent-provider-test.ss', 't/temporal-candidate-exchange-test.ss', 't/temporal-model-test.ss')
    if not all('MODULE-OK '+name in gate for name in required) or '\nOK\n' not in gate or 'HARNESS-OK ' not in gate:
        raise RuntimeError('native gate lacks complete module/harness receipts')
    if handoff is None: raise RuntimeError('no native admitted handoff')
    p = Publication.from_payload(handoff['publication'].encode())
    keys = tuple(bytes([n]) * 32 for n in (17, 23, 31))
    source = (REPO / 'packages/python-runtime/tests/fixtures/temporal-ascent-model.tla').read_bytes()
    issuer = NativeTemporalEvaluator(REPO, source, 'sha256:' + hashlib.sha256(source).hexdigest(),
        evaluator_key=keys[1], gerbil_environment=dict(os.environ))
    def progress(data):
        sys.stdout.buffer.write(data); sys.stdout.buffer.flush()
    signature = issuer.attest(p, query='query', target='target', output=progress)
    request = SignedPublication(p, hmac.digest(keys[0], p.payload(), 'sha256'), signature)
    library = directory / 'selection.so'
    print('COMPILE runtime-c selection', flush=True)
    subprocess.run(['/usr/bin/clang', '-std=c11', '-Wall', '-Wextra', '-Werror', '-pedantic', '-shared', '-fPIC',
        '-I', str(REPO / 'bindings/runtime-c/include'), str(REPO / 'bindings/runtime-c/src/temporal_selection_v1.c'),
        '-lsqlite3', '-lpthread', '-o', str(library)], check=True, timeout=30)
    receipts = []
    for writer, reader in (('python', 'c'), ('c', 'python')):
        path = directory / (writer + '.sqlite')
        args = dict(authorizer_key=keys[0], evaluator_key=keys[1], runtime_key=keys[2], budget='worker')
        def runtime(kind):
            return NativeTemporalSelectionStore(path, native_library=library, **args) if kind == 'c' else TemporalSelectionStore(path, **args)
        c = TemporalBudgetCoordinator(path, runtime_key=keys[2]); c.create('worker', 2000)
        r = runtime(writer)
        for field in ('authorization_signature', 'evaluation_signature'):
            assert r.publish(replace(request, **{field: b'\0' * 32})).status == 'denied'
        assert r.publish(request).status == 'budget-exhausted'
        c.reserve('worker', p, 500)
        assert r.publish(request).status == 'committed'
        observed = r.observe(p.subject, p.scope)
        assert observed.payload == p.payload() and observed.version == 1
        assert observed.signature == hmac.digest(keys[2], receipt_payload('pointer', 1, p.payload()), 'sha256')
        r.close(); recovered = runtime(reader)
        assert recovered.publish(request).status == 'replayed'
        assert recovered.observe(p.subject, p.scope).payload == p.payload()
        assert c.remaining('worker') == 1500
        recovered.close(); c.close()
        receipts.append(dict(writer=writer, reader=reader, committed=True, recovered=True, budget_remaining=1500))
        print('ASCENT-RUNTIME-OK', writer, reader, flush=True)
    (directory / 'qualification.json').write_text(json.dumps(dict(handoff=handoff, native_cases=sum(line.startswith('CASE-OK ') for line in gate.splitlines()), native_modules=list(required), runtimes=receipts), indent=2) + '\n')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(); parser.add_argument('directory')
    qualify(parser.parse_args().directory)
