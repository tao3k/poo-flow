# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Audit retained first-shot receipts; this does not re-attest runtime HMACs."""
import argparse
import hashlib
import json
from pathlib import Path
from model_study_transport import strict_json


def audit(directory):
    directory=Path(directory)
    def read(name): return strict_json((directory/name).read_text())
    freeze=read('freeze.json'); cases=read('cases.json'); references=read('references.json')
    for key,name in [('cases','cases.json'),('schema','schema.json'),('references','references.json'),
                     ('driver','model_study.py.txt'),('transport','model_study_transport.py.txt')]:
        assert freeze[key]=='sha256:'+hashlib.sha256((directory/name).read_bytes()).hexdigest(), 'frozen input mismatch: '+key
    planned={(c['id'],r) for c in cases for r in range(1,freeze['repeats']+1)}
    records=read('results.json')
    identities=[(r['case'],r['repeat']) for r in records]
    assert planned and len(identities)==len(set(identities)) and set(identities)==planned, 'missing or duplicate planned calls'
    counts={k:0 for k in ('passed','semantic-failure','transport-failure','pipeline-failure')}
    for record in records:
        counts[record['status']]+=1
        if record['status']!='passed': continue
        answer=strict_json(record['response']['text'])
        assert set(answer)==set(read('schema.json')['required']), 'answer schema mismatch'
        assert all(type(answer[k]) is bool for k in ('precedence_proves_causation','model_can_authorize','fair_infinite_progress')), 'answer boolean mismatch'
        assert isinstance(answer['source'],str) and isinstance(answer['reason'],str), 'answer string mismatch'
        ref=references[record['case']]
        for key,value in ref['expected'].items(): assert answer[key]==value, 'semantic mismatch: '+key
        assert record['response']['resolved']['model']==freeze['model'], 'model mismatch'
        if record['capability']=='generation':
            generated=record['generated_native']
            assert generated['model']==ref['native']['model'] and generated['classification']==answer['classification'], 'generated model mismatch'
        else:
            assert answer['source']=='', 'unexpected source'
        native=ref['native']
        if native and native['admitted'] and native['exhausted']:
            runtime=record['runtime']
            assert {r['writer'] for r in runtime}=={'python','native'} and len(runtime)==2, 'missing runtime path'
            assert all(r['committed'] and r['recovered'] and r['forged_authority_denied'] for r in runtime), 'runtime failed'
        elif native:
            assert record['admission_rejected'] is True, 'frontier admission accepted'
        elif record['capability']=='late':
            assert len(record['runtime'])==2 and all(r['retraction_committed'] and r['recovered'] for r in record['runtime'])
    summary=read('summary.json')
    accepted=counts['passed']==len(planned)
    assert summary['total']==len(planned) and summary['counts']==counts and summary['accepted']==accepted, 'summary mismatch'
    return dict(total=len(planned),counts=counts,accepted=accepted)


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('directory');args=p.parse_args()
    try: result=audit(args.directory)
    except (AssertionError,ValueError,KeyError,TypeError,OSError) as error:
        print('RECEIPT-REJECTED',str(error));raise SystemExit(1)
    print('RECEIPT-AUDIT',json.dumps(result));raise SystemExit(0 if result['accepted'] else 1)
