# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
import hashlib
import json
import pytest
from poo_flow_testing.model_study.runtime_accuracy import score, study_manifest


def test_historical_plan_remains_the_exact_approved_frozen_batch():
    plan = study_manifest()
    digest = hashlib.sha256(json.dumps(plan, sort_keys=True, separators=(',', ':')).encode()).hexdigest()
    assert digest == '13f15dcd538103f617f6f5f563dae30e0f4dc35230adc1d1975cf7b0b9a9f589'
    assert len({(row['case'], row['repeat'], row['arm']) for row in plan['order']}) == 48
    assert plan['maximumEstimatedUsd'] < 1


def test_retired_prompted_producer_cannot_make_provider_calls(monkeypatch, tmp_path):
    from poo_flow_testing.model_study.runtime_accuracy import main
    output = tmp_path / 'unused'
    monkeypatch.setattr('sys.argv', ['runtime_accuracy', '--live',
        '--library', str(tmp_path / 'absent-library'), '--output', str(output)])
    with pytest.raises(ValueError, match='retired'):
        main()
    assert not output.exists()


def test_score_does_not_credit_missing_rows_or_duplicate_facts():
    empty = {'status': 'complete', 'rows': []}
    assert not score('{"status":"complete"}', empty)
    assert not score('(system "unsafe")', empty)
    assert not score('{"status":"complete","rows":[["a","b"],["a","b"]]}',
                     {'status': 'complete', 'rows': [['a', 'b']]})
    assert score('{"status":"complete","rows":[["a","c"],["a","b"]]}',
                 {'status': 'complete', 'rows': [['a', 'b'], ['a', 'c']]})
