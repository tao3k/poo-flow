# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
import json
from pathlib import Path
import shutil
import sys
import pytest
REPO=Path(__file__).resolve().parents[4]
sys.path.insert(0,str(REPO/'scripts/temporal'))
from model_study_receipt import audit
RECEIPT=REPO/'t/qualification/temporal-model-study/receipts/2026-10-03-gpt-6-sol'


def test_real_failed_study_remains_failed():
    result=audit(RECEIPT)
    assert result['total']==40 and result['accepted'] is False
    assert result['counts']['transport-failure']==28


def test_omitting_failed_call_cannot_shrink_denominator(tmp_path):
    shutil.copytree(RECEIPT,tmp_path/'receipt')
    path=tmp_path/'receipt/results.json'
    records=json.loads(path.read_text())
    records.pop(next(i for i,r in enumerate(records) if r['status']=='transport-failure'))
    path.write_text(json.dumps(records))
    with pytest.raises(AssertionError,match='missing or duplicate'):
        audit(path.parent)


def test_false_green_summary_is_rejected(tmp_path):
    shutil.copytree(RECEIPT,tmp_path/'receipt')
    path=tmp_path/'receipt/summary.json';summary=json.loads(path.read_text())
    summary['accepted']=True;path.write_text(json.dumps(summary))
    with pytest.raises(AssertionError,match='summary mismatch'):
        audit(path.parent)


def test_native_reference_reuse_binds_source_and_context_but_not_task_wording(monkeypatch):
    import model_study as study
    cases=study.definitions()
    references=study.load_native_references(RECEIPT,cases)
    assert set(references)=={c['id'] for c in cases}
    cases[0]['task']='A new independently frozen explanation of the same native input.'
    study.load_native_references(RECEIPT,cases)
    cases[0]['source']+='\nchanged native input'
    with pytest.raises(ValueError,match='semantic inputs differ'):
        study.load_native_references(RECEIPT,cases)
    monkeypatch.setattr(study,'CONTEXT',{**study.CONTEXT,'cut':'another-cut'})
    with pytest.raises(ValueError,match='context differs'):
        study.load_native_references(RECEIPT,study.definitions())


def test_response_cannot_be_rebound_to_another_task(tmp_path):
    shutil.copytree(REPO/'t/qualification/temporal-model-study/receipts/2026-10-03-deepseek-v2',tmp_path/'receipt')
    path=tmp_path/'receipt/results.json';records=json.loads(path.read_text())
    record=next(r for r in records if r['status']=='passed')
    record['response']['prompt_digest']='sha256:'+'0'*64
    call=path.parent/(str(record['repeat'])+'-'+record['case'])
    (call/'response.json').write_text(json.dumps(record['response']))
    (call/'result.json').write_text(json.dumps(record))
    path.write_text(json.dumps(records))
    with pytest.raises(AssertionError,match='prompt binding mismatch'):
        audit(path.parent)
