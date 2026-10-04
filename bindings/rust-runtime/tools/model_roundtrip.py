# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Frozen forced read-only family tool -> Rust -> native -> model acceptance."""
import argparse
import asyncio
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time

root = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(root / 'packages/python-testing/src'))
from poo_flow_testing.model_study.semantic_plan import configuration, write
from poo_flow_testing.model_study.semantic_provider import predict

sha = lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()
parser = argparse.ArgumentParser()
parser.add_argument('--binary', type=Path, required=True)
parser.add_argument('--library', type=Path, required=True)
parser.add_argument('--oracle', type=Path, required=True)
parser.add_argument('--env-file', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
a = parser.parse_args()
config = configuration(a.env_file)
a.output.mkdir(parents=True, exist_ok=False)
cases = [v for v in json.loads(a.oracle.read_text()) if v['name'] in
         ['release-necessary', 'medication-necessary', 'release-budget', 'medication-unknown']]
assert len(cases) == 4
sources = [root/'bindings/rust-runtime/src/lib.rs', root/'bindings/rust-runtime/src/bin/semantic_call.rs',
           Path(__file__), root/'packages/python-testing/src/poo_flow_testing/model_study/semantic_provider.py']
plan = dict(schema='poo-flow.rust-family-tool-plan.v1',
    head=subprocess.check_output(['git','-C',str(root),'rev-parse','HEAD'],text=True).strip(),
    binarySha256=sha(a.binary), artifactSha256=sha(a.library), oracleSha256=sha(a.oracle),
    sources={str(p.relative_to(root)):sha(p) for p in sources},
    model=config.get('DEEPSEEK_MODEL', config.get('ANTHROPIC_MODEL','deepseek-v4-pro')),
    tasks=[dict(name=c['name'],task=c['payload']) for c in cases],
    maximumCalls=8,retries=0,contentIdleSeconds=5,
    scope='forced read-only finite-family tool fidelity and consumption through Rust/C/POO; no unaided prediction, source authenticity, admission, publication or IFC permit')
write(a.output/'plan.json',plan)
write(a.output/'paid-batch-claim.json',dict(planSha256=sha(a.output/'plan.json'),maximumCalls=8))

async def run():
    records=[]
    for i,case in enumerate(cases):
        print('REAL-MODEL RUST FAMILY',case['name'],flush=True)
        r=dict(case=case['name'],passed=False,tool={},final={})
        task=case['payload']
        request=dict(model=plan['model'],reasoning={'effort':'none'},temperature=0.0,max_output_tokens=4096,stream=True,
            input=[dict(role='user',content='Invoke the read-only tool once with this exact task JSON:\n'+json.dumps(task))],
            tools=[dict(type='function',name='poo_flow_temporal_family_classify',description='Read-only finite hypothesis family classification.',
                        parameters=dict(type='object',properties={'task':dict(type='object')},required=['task'],additionalProperties=False))],
            tool_choice=dict(type='function',name='poo_flow_temporal_family_classify'))
        r['toolRequest']=request
        try:
            await predict(request,config['DEEPSEEK_API_KEY'],r['tool'],emit=lambda _:print('.',end='',flush=True),content_event='response.function_call_arguments.delta')
            calls=r['tool'].get('toolCalls',[])
            if len(calls)!=1 or calls[0].get('name')!='poo_flow_temporal_family_classify':raise ValueError('wrong tool call')
            call=calls[0]
            # Duplicate keys rejected before equality checking.
            def unique(pairs):
                d={}
                for k,v in pairs:
                    if k in d:raise ValueError('duplicate JSON key')
                    d[k]=v
                return d
            arguments=json.loads(call['arguments'],object_pairs_hook=unique)
            if json.dumps(arguments,sort_keys=True)!=json.dumps({'task':task},sort_keys=True):raise ValueError('tool changed bound task')
            env=dict(os.environ,POO_FLOW_SEMANTIC_LIBRARY=str(a.library),POO_FLOW_SEMANTIC_SHA256=plan['artifactSha256'])
            start=time.monotonic()
            child=await asyncio.create_subprocess_exec(str(a.binary),stdin=asyncio.subprocess.PIPE,stdout=asyncio.subprocess.PIPE,stderr=asyncio.subprocess.PIPE,env=env)
            try:
                stdout,stderr=await asyncio.wait_for(child.communicate(json.dumps(dict(operation='temporal.family.classify',payload=task)).encode()),5)
            except BaseException:
                child.kill();await child.wait();raise
            if child.returncode:raise ValueError('Rust consumer failed: '+stderr.decode())
            result=json.loads(stdout);r['nativeSeconds']=time.monotonic()-start;r['nativeResult']=result
            if result!=case['expected']:raise ValueError('Rust native result differs from frozen installed-Python oracle')
            fields=['classification','bindingDigest','modelDigest','exhausted','sourceAuthenticated','actionAuthorized']
            expected={k:result[k] for k in fields}
            schema=dict(type='object',additionalProperties=False,required=fields,
                        properties={k:dict(type='boolean' if k in fields[3:] else 'string') for k in fields})
            final=dict(model=plan['model'],reasoning={'effort':'none'},temperature=0.0,max_output_tokens=2048,stream=True,
                input=request['input']+[call,dict(type='function_call_output',call_id=call['call_id'],output=json.dumps(result)),
                                       dict(role='user',content='Return only classification, bindingDigest, modelDigest, exhausted, sourceAuthenticated and actionAuthorized exactly from the actual Library output as JSON.')],
                text=dict(format=dict(type='json_schema',name='family_result',strict=True,schema=schema)))
            r['finalRequest']=final
            raw=await predict(final,config['DEEPSEEK_API_KEY'],r['final'],emit=lambda _:print('.',end='',flush=True))
            if json.loads(raw,object_pairs_hook=unique)!=expected:raise ValueError('final differs from actual native result')
            r['passed']=True
        except Exception as e:r['failure']=type(e).__name__+': '+str(e)
        write(a.output/f'{i:02d}.json',r);records.append(r)
        print(' RESULT',r['passed'],r.get('failure',''),flush=True)
    freeze=all(sha(root/p)==v for p,v in plan['sources'].items()) and sha(a.binary)==plan['binarySha256'] and sha(a.library)==plan['artifactSha256'] and sha(a.oracle)==plan['oracleSha256']
    report=dict(schema='poo-flow.rust-family-tool-acceptance.v1',planSha256=sha(a.output/'plan.json'),roundtrips=len(records),
        passed=sum(r['passed'] for r in records),failed=sum(not r['passed'] for r in records),retries=0,
        nativeCalls=sum('nativeResult' in r for r in records),providerResponses=sum(p.get('responseStatus')=='completed' for r in records for p in (r['tool'],r['final'])),
        sourceFreezeIntact=freeze,scope=plan['scope'])
    write(a.output/'report.json',report)
    print(json.dumps(report),flush=True)
    return 0 if freeze and report['passed']==len(cases) else 1
sys.exit(asyncio.run(run()))
