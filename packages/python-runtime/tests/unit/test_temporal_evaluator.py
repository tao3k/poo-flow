# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
import hashlib
import hmac
import os
from pathlib import Path
import sys
from dataclasses import replace
import pytest
from poo_flow_runtime.temporal_evaluator import NativeTemporalEvaluator
from poo_flow_runtime.temporal_selection import SignedPublication, receipt_payload
from test_temporal_selection import KEYS, publication, store, native_library

pytestmark = pytest.mark.skipif(os.environ.get('POO_FLOW_TEST_NATIVE_EVALUATOR') != '1',
    reason='dedicated native evaluator gate requires compiled POO/parser modules')


def emit(data):
    sys.stdout.buffer.write(data); sys.stdout.buffer.flush()


def test_fixed_native_admission_issues_signature_for_both_runtimes(tmp_path, native_library):
    repo = Path(__file__).resolve().parents[4]
    source = (repo / 'packages/python-runtime/tests/fixtures/temporal-host-model.tla').read_bytes()
    digest = 'sha256:' + hashlib.sha256(source).hexdigest()
    issuer = NativeTemporalEvaluator(repo, source, digest, evaluator_key=KEYS[1], gerbil_environment=dict(os.environ))
    context = dict(subject='subject', scope='scope', cut='cut', projection='projection', policy='policy', generation='generation')
    result = issuer.evaluate(**context, query='query', target='via-a', output=emit)
    assert result['classification'] == 'possible'
    p = publication(proof=result['proof'], model=result['model'])
    evaluation_signature = issuer.attest(p, query='query', target='via-a', output=emit)
    request = SignedPublication(p, hmac.digest(KEYS[0], p.payload(), 'sha256'), evaluation_signature)
    for kind in ('python', 'native'):
        r = store(kind, tmp_path / (kind + '.sqlite'), native_library)
        assert r.publish(request).status == 'committed'
        assert r.observe(p.subject, p.scope).payload == p.payload()
        r.close()
    with pytest.raises(ValueError, match='differs from admitted'):
        issuer.attest(replace(p, proof='caller-proof'), query='query', target='via-a', output=emit)
    with pytest.raises(ValueError, match='source differs'):
        NativeTemporalEvaluator(repo, source + b'\n', digest, evaluator_key=KEYS[1], gerbil_environment=dict(os.environ))


def test_authenticated_late_retraction_commits_and_recovers_in_both_runtimes(tmp_path, native_library):
    import json
    from poo_flow_runtime.temporal_selection import Publication
    from poo_flow_runtime.temporal_budget import TemporalBudgetCoordinator
    from test_temporal_budget import runtime
    repo = Path(__file__).resolve().parents[4]
    fixture = json.loads((repo / 'packages/python-runtime/tests/fixtures/temporal-late-publication.json').read_text())
    requests = []
    for phase in ('root', 'late'):
        source = fixture[phase + '_source'].encode()
        issuer = NativeTemporalEvaluator(repo, source, 'sha256:' + hashlib.sha256(source).hexdigest(),
            evaluator_key=KEYS[1], gerbil_environment=dict(os.environ))
        p = Publication.from_payload(fixture[phase + '_payload'].encode())
        requests.append(SignedPublication(p, hmac.digest(KEYS[0], p.payload(), 'sha256'),
            issuer.attest(p, query='q', target='target', output=emit)))
    for writer, reader in (('python', 'native'), ('native', 'python')):
        path = tmp_path / (writer + '.sqlite')
        c = TemporalBudgetCoordinator(path, runtime_key=KEYS[2])
        c.create('worker', 2000)
        root, late = requests
        c.reserve('worker', root.publication, 500)
        r = runtime(writer, path, native_library)
        assert r.publish(root).status == 'committed'
        observed = r.observe('subject', 'scope')
        assert (observed.status, observed.version, observed.revision) == ('committed', late.publication.expected_version, late.publication.predecessor)
        assert observed.signature == hmac.digest(KEYS[2], receipt_payload('pointer', observed.version, observed.payload), 'sha256')
        c.reserve('worker', late.publication, 500)
        assert r.publish(late).status == 'committed'
        assert r.observe('subject', 'scope').revision == 'withdrawn'
        r.close()
        recovered = runtime(reader, path, native_library)
        assert recovered.publish(late).status == 'replayed'
        assert recovered.observe('subject', 'scope').version == 2
        assert c.remaining('worker') == 1000
        recovered.close(); c.close()


def test_read_only_unknown_assessment_cannot_issue_handoff_or_signature():
    repo = Path(__file__).resolve().parents[4]
    source = (repo / 'packages/python-runtime/tests/fixtures/temporal-host-model.tla').read_text().replace(
        '"care/cause", "local"', '"care/cause", "remote"').encode()
    issuer = NativeTemporalEvaluator(repo, source, 'sha256:' + hashlib.sha256(source).hexdigest(),
        evaluator_key=KEYS[1], gerbil_environment=dict(os.environ))
    context = dict(subject='subject', scope='scope', cut='cut', projection='projection', policy='policy', generation='generation')
    result = issuer.assess(**context, query='query', target='via-a', output=emit,
        publication=dict(revision='root', journal='journal', nonce='nonce', expires=2000000000))
    assert result['classification'] == 'unknown' and result['admitted'] is False
    assert result['publication'] is False
    p = publication(proof=result['proof'], model=result['model'])
    with pytest.raises(ValueError, match='not admitted'):
        issuer.attest(p, query='query', target='via-a', output=emit)
