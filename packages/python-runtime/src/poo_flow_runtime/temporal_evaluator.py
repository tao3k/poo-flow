# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Trusted host attests only results replayed by the fixed native evaluator.

The host owns the interpreter, compiled modules, source approval and key. This
is native semantic admission, not a generic theorem or interpreter attestation.
A caller cannot replace the evaluator with a script or supply an admission flag.
"""
import hashlib
import hmac
import json
import os
import re
from pathlib import Path
import selectors
import signal
import subprocess
import tempfile
import time
from .temporal_selection import Publication


class NativeTemporalEvaluator:
    def __init__(self, repo: Path, source: bytes, source_digest: str, *, evaluator_key: bytes,
                 gerbil_environment: dict[str, str], gxi: str = 'gxi'):
        if not isinstance(evaluator_key, bytes) or len(evaluator_key) < 32:
            raise ValueError('trusted evaluator key is required')
        if 'sha256:' + hashlib.sha256(source).hexdigest() != source_digest:
            raise ValueError('source differs from host approval')
        self._source = source.decode('utf-8')
        self._key = evaluator_key
        self._repo = Path(repo).resolve()
        self._env = dict(gerbil_environment)
        self._gxi = gxi

    def assess(self, *, subject, scope, cut, projection, policy, generation,
                 query, profile='finite-hypothesis-v2', target=None, limit=False, node_limit=10000,
                 publication=None, output=lambda data: None):
        """Read-only native assessment, including unknown/incomplete results.

        An optional host publication descriptor prepares an inert native root
        handoff only for admitted results; this method never signs or publishes.
        """
        required = {
            'finite-hypothesis-v2': {'ModelIdentity','ClockDomains','Observations','Hypotheses','Constraints','FamilyComplete','FamilySemantics'},
            'finite-behavior-v1': {'ModelIdentity','StateVariables','Mechanisms','Interventions','Horizon','PropertyIdentity','PropertyKind','Conditions','Deadline','ExpectedOutcomes'},
        }.get(profile)
        if required is None:
            raise ValueError('unsupported evaluator profile')
        # Negative preflight only; native parsing/projection/admission remain authoritative.
        bindings=set(re.findall(r'(?m)^\s*([A-Za-z][A-Za-z0-9_]*)\s*==', self._source))
        missing=required-bindings
        if missing:
            raise ValueError('literal profile missing bindings: '+','.join(sorted(missing)))
        request = dict(source=self._source, subject=subject, scope=scope, cut=cut, projection=projection,
                       policy=policy, generation=generation, query=query, profile=profile,
                       target=target, limit=limit, node_limit=node_limit,
                       publication=False if publication is None else publication)
        with tempfile.TemporaryDirectory(prefix='poo-native-evaluation-') as directory:
            path = Path(directory) / 'request.json'
            path.write_text(json.dumps(request, ensure_ascii=False), encoding='utf-8')
            # Fixed owned modules, literal request path, no shell and no caller code.
            preload = self._repo / 'scripts/temporal/preload.ss'
            command = [self._gxi, '-e', '(load ' + json.dumps(str(preload)) + ') (temporal-preload-module "poo-flow/scripts/temporal/evaluate-source") (temporal-preload-module "poo-flow/scripts/temporal/exit-child-process")',
                       '-e', '(begin (import :poo-flow/scripts/temporal/evaluate-source :poo-flow/scripts/temporal/exit-child-process) (main ' + json.dumps(str(path)) + ') (temporal-child-process-exit! 0))']
            child = subprocess.Popen(command, cwd=self._repo, env=self._env, stdout=subprocess.PIPE,
                                     stderr=subprocess.STDOUT, start_new_session=True)
            chunks = []
            selector = selectors.DefaultSelector()
            selector.register(child.stdout, selectors.EVENT_READ)
            started = last = time.monotonic()
            try:
                while selector.get_map():
                    now = time.monotonic()
                    if now - started >= 90 or now - last >= 5:
                        raise TimeoutError('native evaluator exceeded execution/progress deadline')
                    for key, _ in selector.select(min(90 - (now-started), 5 - (now-last))):
                        data = os.read(key.fileobj.fileno(), 65536)
                        if not data:
                            selector.unregister(key.fileobj)
                        else:
                            chunks.append(data); output(data); last = time.monotonic()
                if child.wait(timeout=5) != 0:
                    raise ValueError('native evaluator rejected input')
            finally:
                selector.close()
                child.stdout.close()
                if child.poll() is None:
                    os.killpg(child.pid, signal.SIGKILL); child.wait(timeout=5)
            results = [line[len(b'POO-EVALUATION '):] for line in b''.join(chunks).splitlines() if line.startswith(b'POO-EVALUATION ')]
            if len(results) != 1:
                raise ValueError('native evaluator receipt missing or duplicated')
            result = json.loads(results[0])
            return result

    def evaluate(self, **request):
        result = self.assess(**request)
        if result.get('admitted') is not True or result.get('exhausted') is not True:
            raise ValueError('unfinished or unknown evaluation is not admitted')
        return result

    def attest(self, publication: Publication, *, query, profile='finite-hypothesis-v2',
               target=None, limit=False, node_limit=10000, output=lambda data: None):
        payload = publication.payload()
        result = self.evaluate(**{key: getattr(publication, key) for key in ('subject','scope','cut','projection','policy','generation')},
                               query=query, profile=profile, target=target, limit=limit,
                               node_limit=node_limit, output=output)
        if (result['proof'], result['model']) != (publication.proof, publication.model):
            raise ValueError('publication differs from admitted native evaluation')
        return hmac.digest(self._key, payload, 'sha256')
