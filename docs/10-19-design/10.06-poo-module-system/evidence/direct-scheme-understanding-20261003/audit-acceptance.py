"""Audit saved provider receipts; no provider calls or oracle-based extraction."""
from pathlib import Path
import json, hashlib, collections
root=Path('/private/tmp/poo-plan-audit-20261002')
live=Path('/private/tmp/poo-direct-understanding-live-20261003')
replay=Path('/private/tmp/poo-direct-understanding-transport-replay-20261003')
out=root/'docs/10-19-design/10.06-poo-module-system/evidence/direct-scheme-understanding-20261003'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
rows=[json.loads(x) for x in (live/'calls.jsonl').read_text().splitlines()]
analyses={x['index']:x for x in map(json.loads,(replay/'replay.jsonl').read_text().splitlines())}
assert len(rows)==24 and len({r['responseId'] for r in rows})==24
cases=[]
for row in rows:
    i=row['index']; extra=analyses[i]
    assert hashlib.sha256(row['raw'].encode()).hexdigest()==extra['rawSha256']
    request=live/f'{i:02}.request.json'
    assert sha(request)==row['requestSha256']
    response=json.loads((live/f'{i:02}.response.json').read_text())
    assert response['id']==row['responseId']
    if row['responseStatus']=='incomplete': category='provider-incomplete'
    elif extra['observation'].get('correct'): category='correct-prediction-rejected-by-transport'
    elif i in (5,8): category='placeholder-echo'
    elif extra['extracted'] is not None: category='wrong-semantic-prediction'
    else: category='completed-no-unique-prediction'
    cases.append({'index':i,'case':row['case'],'arm':row['arm'],'category':category,
                  'responseStatus':row['responseStatus'],'incompleteDetails':response['incomplete_details'],
                  'rawSha256':extra['rawSha256'],'requestSha256':row['requestSha256'],
                  'originalObservation':row['observation'],'supplementaryObservation':extra['observation']})
report={'version':1,'scope':'audit of immutable 24-call receipts; no new provider calls; original scores unchanged',
        'paidCalls':0,'planSha256':rows[0]['planSha256'],
        'originalAcceptedAndCorrect':sum(bool(r['observation']['correct']) for r in rows),
        'originalTransportRejected':sum(bool(r['observation'].get('transportRejected')) for r in rows),
        'emptyRawOutputs':sum(not r['raw'].strip() for r in rows),
        'categories':dict(collections.Counter(r['category'] for r in cases)),
        'inputSourceClosure':'Only scheme-language, scheme-checked, scheme-admission; evaluate/planning implementation not supplied',
        'manualReviewUnscored':{
            '16':'Diagnostic text recognizes unsafe head, repeatedly guesses several paths including native-correct head 0, ends with head 1. No unique inert prediction; no additional semantic credit.',
            '21':'Withdrawal explanation and repeated quoted datum agree with native expected; also contains executable list/canonical expression. Existing extractor reports ambiguity. Qualitative evidence only; frozen and supplementary scores unchanged.'},
        'evidenceHashes':{'calls.jsonl':sha(live/'calls.jsonl'),'replay.jsonl':sha(replay/'replay.jsonl'),'auditScript':sha(Path(__file__))},
        'cases':cases}
(out/'acceptance-root-cause.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({k:report[k] for k in ('originalAcceptedAndCorrect','originalTransportRejected','emptyRawOutputs','categories')},indent=2))
