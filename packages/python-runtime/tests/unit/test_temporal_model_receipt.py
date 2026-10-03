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
