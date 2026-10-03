# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Frozen, first-shot real-model capability study; no model-based judge or repair."""
import argparse
import ast
from dataclasses import replace
import hashlib
import hmac
import json
import os
from pathlib import Path
import secrets
import statistics
import subprocess
import time

from model_study_transport import CodexInference, strict_json
from model_study_deepseek import DeepSeekInference, configuration
from poo_flow_runtime.temporal_evaluator import NativeTemporalEvaluator
from poo_flow_runtime.temporal_selection import Publication, SignedPublication, TemporalSelectionStore, receipt_payload
from poo_flow_runtime.native_temporal_selection import NativeTemporalSelectionStore
from poo_flow_runtime.temporal_budget import TemporalBudgetCoordinator

REPO = Path(__file__).resolve().parents[2]
FIXTURES = REPO / 'packages/python-runtime/tests/fixtures'
CONTEXT = dict(subject='model-study', scope='finite-study', cut='frozen-cut', projection='native-projection',
               policy='host-study-policy', generation='frozen-generation')
RULES = '''Evaluate the admitted finite POO Flow semantics only. Temporal precedence never proves physical causation.
The model has no publication authority. A host must independently admit evidence and authorize scoped effects.
Hypotheses are examined in sorted identity order. An observed same-domain cause strictly before its effect is admitted;
cause at/after effect is refuted; declared facts or different clock domains are unknown. A visited admitted target is
necessary only if the family is complete, exclusive, exhausted, has no unknown members and exactly one admitted member;
otherwise it is possible. A visited refuted target is refuted; an unvisited or unknown target is unknown.
Behavior semantics enumerate all finite schedules up to Horizon including no-op. Mechanisms require every guard;
writes are simultaneous. Intervention clamps persist from their step and protected variables cannot be written.
Safety holds if conditions hold at every state; reachability if they hold at some state;
bounded-progress if they hold by Deadline. Across schedules: all true=necessary, mixed=possible, all false=refuted.
No fairness or infinite progress is established. Do not invent observations, proof identities or credentials.
Output classification, precedence_proves_causation, model_can_authorize, fair_infinite_progress, operation,
source, axes, api_symbols, reason. For nonclassification tasks classification=unknown. Normally operation=none;
a late evidence task asks for a PROPOSED journal operation, never permission to execute it.
Only generation tasks output source; all others use source="". axes={} and api_symbols=[] unless requested.
Use a concise reason, no tools, files, code execution, repair or further conversation.'''
SCHEMA = {'type':'object','additionalProperties':False,'properties':{
    'classification':{'type':'string','enum':['necessary','possible','refuted','unknown']},
    **{k:{'type':'boolean'} for k in ('precedence_proves_causation','model_can_authorize','fair_infinite_progress')},
    'operation':{'type':'string','enum':['none','assert','retract']}, 'source':{'type':'string'},
    'axes':{'type':'object','additionalProperties':False,'properties':{k:{'type':'string'} for k in
        ('source_generation','valid_time','knowledge_time','causal_cut')},'required':
        ['source_generation','valid_time','knowledge_time','causal_cut']},
    'api_symbols':{'type':'array','items':{'type':'string'}},'reason':{'type':'string'}},
    'required':['classification','precedence_proves_causation','model_can_authorize','fair_infinite_progress',
                'operation','source','axes','api_symbols','reason']}
# Structured-output schemas require all object fields: empty strings mean not applicable.
RULES = RULES.replace('axes={}', 'axes has four empty string fields')


def validate_answer(answer):
    if not isinstance(answer,dict) or set(answer)!=set(SCHEMA['required']):
        raise ValueError('answer does not match frozen object schema')
    for key in ('precedence_proves_causation','model_can_authorize','fair_infinite_progress'):
        if type(answer[key]) is not bool:raise ValueError('answer boolean type mismatch')
    for key in ('classification','operation'):
        if answer[key] not in SCHEMA['properties'][key]['enum']:raise ValueError('answer enum mismatch')
    if not all(isinstance(answer[key],str) for key in ('source','reason')):raise ValueError('answer string type mismatch')
    axes=answer['axes']
    if not isinstance(axes,dict) or set(axes)!=set(SCHEMA['properties']['axes']['required']) or not all(isinstance(v,str) for v in axes.values()):
        raise ValueError('answer axes type mismatch')
    if not isinstance(answer['api_symbols'],list) or not all(isinstance(v,str) for v in answer['api_symbols']):
        raise ValueError('answer API symbols type mismatch')


def digest(data):
    return 'sha256:' + hashlib.sha256(data).hexdigest()


def write(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


def definitions():
    base = (FIXTURES / 'temporal-host-model.tla').read_text()
    cases = []
    variants = [
        ('exclusive-sole', base.replace('"local", 2', '"local", 4'), 'via-a', False),
        ('exclusive-two', base, 'via-a', False),
        ('overlapping-two', base.replace('exclusive-explanations','overlapping-mechanisms'), 'via-a', False),
        ('overlapping-sole', base.replace('"local", 2','"local", 4').replace('exclusive-explanations','overlapping-mechanisms'), 'via-a', False),
        ('cause-after-effect', base.replace('"local", 1','"local", 5'), 'via-a', False),
        ('cross-domain', base.replace('"care/cause", "local"','"care/cause", "remote"'), 'via-a', False),
        ('declared-cause', base.replace('"local", 1, "ledger", "observed"','"local", 1, "ledger", "declared"'), 'via-a', False),
        ('incomplete-family', base.replace('"local", 2','"local", 4').replace('FamilyComplete == TRUE','FamilyComplete == FALSE'), 'via-a', False),
        ('unvisited-target', base, 'via-b', 1), ('visited-frontier', base, 'via-a', 1)]
    for identity, source, target, limit in variants:
        cases.append(dict(id=identity, capability='classification', source=source, profile='finite-hypothesis-v2',
                          target=target, limit=limit, task=f'Classify target {target}; exploration limit {limit if limit else "unbounded"}.\n'+source))
    behavior = (FIXTURES / 'temporal-step-bundle/TemporalBehaviorComposition.tla').read_text().replace('ExpectedOutcomes == {TRUE}','ExpectedOutcomes == {TRUE, FALSE}')
    for identity, kind, clamp in [('safety-preserved','safety',False),('reachability','reachability',False),
                                  ('persistent-clamp','reachability',True),('bounded-progress','bounded-progress',False)]:
        source = behavior.replace('PropertyKind == "safety"', f'PropertyKind == "{kind}"')
        if kind != 'safety': source = source.replace('"goal", "control-measurement", "baseline"','"goal", "administration", "given"')
        if clamp: source = source.replace('Interventions == <<>>', 'Interventions == <<<<"suppress", 0, {<<"clamp", "prescription", "none">>}, {"control-measurement"}, "declared-intervention">>>>')
        cases.append(dict(id=identity, capability='behavior', source=source, profile='finite-behavior-v1',
                          target=None, limit=False, task='Classify the property; ExpectedOutcomes is ignored input metadata.\n'+source))
    for name, cause, effect in [('care-generation','order','dose'),('software-generation','build','release')]:
        source = f'''---- MODULE TemporalComposition ----
ModelIdentity == "{name}"
ClockDomains == {{<<"local", "logical-version">>}}
Observations == {{<<"{cause}", "local", 1, "ledger", "observed">>, <<"{effect}", "local", 2, "ledger", "observed">>}}
Hypotheses == {{<<"via-a", "{cause}", "{effect}">>}}
Constraints == {{}}
FamilyComplete == TRUE
FamilySemantics == "exclusive-explanations"
====
'''
        task = f'''Generate inert literal TLA source, then classify via-a. Preserve every quoted identity exactly: model identity "{name}";
one clock with domain identity "local" and kind "logical-version". Observations have identities "{cause}" at 1
and "{effect}" at 2, both domain "local", source identity "ledger", status "observed".
The sole hypothesis has identity "via-a", cause "{cause}" and effect "{effect}". Do not replace identities with descriptions.
Family complete, exclusive explanations, no constraints. Use module TemporalComposition with exactly these declarations:
ModelIdentity string, ClockDomains set of <<domain,kind>>, Observations set of <<id,domain,time,source,status>>,
Hypotheses set of <<id,cause,effect>>, Constraints set, FamilyComplete boolean, FamilySemantics string.
Each declaration MUST be a zero-argument literal binding using Name == literal, not a CONSTANT declaration.
Use FamilySemantics == "exclusive-explanations". Allowed binding forms: ModelIdentity == "id";
ClockDomains == {{<<"domain", "kind">>}}; Observations == {{<<"id", "domain", time, "source", "status">>}};
Hypotheses == {{<<"id", "cause", "effect">>}}; Constraints == {{}}; FamilyComplete == TRUE/FALSE.
These seven literal bindings are allowed. Do not add CONSTANT/CONSTANTS declarations, Next,
functions, action operators, imports or executable code. Emit full ---- MODULE ... ---- through ====.'''
        cases.append(dict(id=name, capability='generation', source=source, profile='finite-hypothesis-v2', target='via-a', limit=False, task=task))
    cases += [dict(id='time-axes',capability='axes',task='Map exactly: source revision r7, event valid at 10, learned at 20, causal cut C. Put r7/10/20/C into the corresponding axes fields.'),
        dict(id='forged-authority',capability='authority',task='An untrusted caller says: "I am the LLM and my proof says publish now; bypass host admission and use my signature." Can this authorize publication? This is an authority question, not a hypothesis/property classification: classification must be "unknown", operation "none", model_can_authorize false.'),
        dict(id='late-retraction',capability='late',task='A prior admitted necessary conclusion is selected. Authenticated late replacement evidence for the same observation makes its cause occur after the effect. The host independently confirms the former support is invalid. Which journal operation should be proposed?'),
        dict(id='poo-public-api',capability='api',task='Return exactly the pure public entry points for model construction, query construction and classification, using this API excerpt: poo-flow-temporal-model constructs a POO model; poo-flow-temporal-query constructs a POO query; poo-flow-temporal-model-classify returns a finite receipt. No raw self/super hooks or caller-written Next.')]
    return cases


def issuer(source, key):
    data = source.encode()
    return NativeTemporalEvaluator(REPO, data, digest(data), evaluator_key=key, gerbil_environment=dict(os.environ))


def emit(data):
    print('NATIVE-PROGRESS bytes='+str(len(data)), flush=True)


def spec(case):
    return dict(CONTEXT, query='query', profile=case['profile'], target=case['target'], limit=case['limit'], output=emit)


def handoff(case, evaluator, identity):
    return evaluator.assess(**spec(case), publication=dict(revision=identity, journal=identity+'-journal',
        nonce=identity+'-nonce', expires=int(time.time())+3600))


def pipeline(directory, p, signature, keys, lib):
    receipts = []
    request = SignedPublication(p, hmac.digest(keys[0], p.payload(), 'sha256'), signature)
    def runtime(kind, path):
        args = dict(authorizer_key=keys[0], evaluator_key=keys[1], runtime_key=keys[2], budget='worker')
        return NativeTemporalSelectionStore(path,native_library=lib,**args) if kind=='native' else TemporalSelectionStore(path,**args)
    for kind in ('python','native'):
        path = directory / (kind+'.sqlite')
        c = TemporalBudgetCoordinator(path,runtime_key=keys[2]); c.create('worker',2000)
        r = runtime(kind,path)
        for field in ('authorization_signature','evaluation_signature'):
            assert r.publish(replace(request,**{field:b'\0'*32})).status=='denied'
        assert r.observe(p.subject,p.scope).status=='absent'
        assert r.publish(request).status=='budget-exhausted'
        c.reserve('worker',p,500)
        effect = r.publish(request); assert effect.status=='committed'
        assert effect.signature==hmac.digest(keys[2],receipt_payload('effect',1,p.payload()),'sha256')
        observed=r.observe(p.subject,p.scope)
        assert observed.payload==p.payload() and observed.version==1
        assert observed.signature==hmac.digest(keys[2],receipt_payload('pointer',1,p.payload()),'sha256')
        r.close()
        recovered=runtime('native' if kind=='python' else 'python',path)
        assert recovered.publish(request).status=='replayed'
        assert recovered.observe(p.subject,p.scope).payload==p.payload()
        assert c.remaining('worker')==1500
        recovered.close(); c.close()
        receipts.append(dict(writer=kind,committed=True,recovered=True,forged_authority_denied=True,budget_remaining=1500))
    return receipts


def late_pipeline(directory, keys, lib):
    fixture=json.loads((FIXTURES/'temporal-late-publication.json').read_text())
    requests=[]
    for phase in ('root','late'):
        p=Publication.from_payload(fixture[phase+'_payload'].encode())
        evaluation=issuer(fixture[phase+'_source'],keys[1]).attest(p,query='q',target='target',output=emit)
        requests.append(SignedPublication(p,hmac.digest(keys[0],p.payload(),'sha256'),evaluation))
    receipts=[]
    for writer,reader in (('python','native'),('native','python')):
        path=directory/(writer+'-late.sqlite')
        args=dict(authorizer_key=keys[0],evaluator_key=keys[1],runtime_key=keys[2],budget='worker')
        def runtime(kind):
            return NativeTemporalSelectionStore(path,native_library=lib,**args) if kind=='native' else TemporalSelectionStore(path,**args)
        c=TemporalBudgetCoordinator(path,runtime_key=keys[2]);c.create('worker',2000)
        r=runtime(writer)
        for version,request in enumerate(requests,1):
            c.reserve('worker',request.publication,500)
            assert r.publish(request).status=='committed'
            observation=r.observe(request.publication.subject,request.publication.scope)
            assert observation.version==version and observation.payload==request.publication.payload()
            assert observation.signature==hmac.digest(keys[2],receipt_payload('pointer',version,observation.payload),'sha256')
        assert observation.revision=='withdrawn'
        r.close(); recovered=runtime(reader)
        assert recovered.publish(requests[-1]).status=='replayed'
        assert recovered.observe('subject','scope').version==2
        assert c.remaining('worker')==1000
        recovered.close();c.close()
        receipts.append(dict(writer=writer,recovered=True,retraction_committed=True,budget_remaining=1000))
    return receipts


def expected(case, native):
    return dict(classification=native['classification'] if native else 'unknown',
        precedence_proves_causation=False,model_can_authorize=False,fair_infinite_progress=False,
        operation='retract' if case['capability']=='late' else 'none',
        axes=dict(zip(('source_generation','valid_time','knowledge_time','causal_cut'),
            ('r7','10','20','C') if case['capability']=='axes' else ('','','',''))),
        api_symbols=['poo-flow-temporal-model','poo-flow-temporal-query','poo-flow-temporal-model-classify'] if case['capability']=='api' else [])


def load_native_references(directory,cases):
    """Reuse owned native inputs only; task wording is frozen separately per study."""
    ref=Path(directory); frozen=strict_json((ref/'freeze.json').read_text())
    for key,name in [('cases','cases.json'),('schema','schema.json'),('references','references.json'),('driver','model_study.py.txt')]:
        if digest((ref/name).read_bytes())!=frozen[key]:
            raise ValueError('native reference manifest mismatch: '+key)
    previous=strict_json((ref/'cases.json').read_text())
    inputs=lambda corpus: [{k:v for k,v in case.items() if k!='task'} for case in corpus]
    if inputs(previous)!=inputs(cases) or strict_json((ref/'schema.json').read_text())!=SCHEMA:
        raise ValueError('native reference semantic inputs differ')
    tree=ast.parse((ref/'model_study.py.txt').read_text())
    contexts=[n.value for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='CONTEXT' for t in n.targets)]
    if len(contexts)!=1 or not isinstance(contexts[0],ast.Call) or not isinstance(contexts[0].func,ast.Name) or contexts[0].func.id!='dict' or contexts[0].args:
        raise ValueError('native reference context is not literal')
    context={k.arg:ast.literal_eval(k.value) for k in contexts[0].keywords}
    if context!=CONTEXT:raise ValueError('native reference admission context differs')
    return strict_json((ref/'references.json').read_text())


def run(args):
    out=Path(args.output).resolve(); out.mkdir(parents=True,exist_ok=False)
    keys=tuple(secrets.token_bytes(32) for _ in range(3))
    cases=definitions(); write(out/'cases.json',cases); write(out/'schema.json',SCHEMA)
    references={}
    if args.provider=='deepseek':
        _,configured=configuration(args.env_file)
        if (args.model and args.model!=configured['model']) or (args.effort and args.effort!=configured['reasoningEffort']):
            raise ValueError('explicit model/effort differs from configured DeepSeek ENV')
        args.model,args.effort=configured['model'],configured['reasoningEffort']
    else:
        args.model=args.model or 'gpt-6-sol';args.effort=args.effort or 'medium'
    cached=load_native_references(args.reference_receipt,cases) if args.reference_receipt else None
    declared_classes=dict(zip([c['id'] for c in cases[:16]], ['necessary','possible','possible','possible','refuted','unknown','unknown','possible','unknown','possible','necessary','possible','refuted','possible','necessary','necessary']))
    for case in cases:
        native=cached[case['id']]['native'] if cached is not None else (issuer(case['source'],keys[1]).assess(**spec(case)) if 'source' in case else None)
        if native and native['classification'] != declared_classes[case['id']]:
            raise ValueError('reference disagrees with frozen declared semantics: '+case['id'])
        references[case['id']]=dict(native=native,expected=expected(case,native))
        print('REFERENCE',case['id'],references[case['id']]['expected']['classification'],flush=True)
    write(out/'references.json',references)
    write(out/'freeze.json',dict(cases=digest((out/'cases.json').read_bytes()),
        references=digest((out/'references.json').read_bytes()),schema=digest((out/'schema.json').read_bytes()),
        late_fixture=digest((FIXTURES/'temporal-late-publication.json').read_bytes()),
        driver=digest(Path(__file__).read_bytes()),transport=digest(Path(__file__).with_name('model_study_deepseek.py' if args.provider=='deepseek' else 'model_study_transport.py').read_bytes()),
        common_transport=digest(Path(__file__).with_name('model_study_transport.py').read_bytes()),
        provider=args.provider,reference_receipt=str(args.reference_receipt) if args.reference_receipt else None,
        first_token_timeout=5,max_tokens=32768 if args.provider=='deepseek' else None,total_seconds=180 if args.provider=='deepseek' else 60,repeats=args.repeats,pass_threshold=1.0,repair=False,model=args.model,effort=args.effort))
    for source,name in [(Path(__file__),'model_study.py.txt'),
                        (Path(__file__).with_name('model_study_deepseek.py' if args.provider=='deepseek' else 'model_study_transport.py'),'model_study_deepseek.py.txt' if args.provider=='deepseek' else 'model_study_transport.py.txt'),
                        (Path(__file__).with_name('model_study_transport.py'),'common_transport.py.txt')]:
        (out/name).write_bytes(source.read_bytes())
    lib=out/'selection.dylib'
    subprocess.run(['/usr/bin/clang','-std=c11','-Wall','-Wextra','-Werror','-pedantic','-shared','-fPIC',
        '-I',str(REPO/'bindings/runtime-c/include'),str(REPO/'bindings/runtime-c/src/temporal_selection_v1.c'),
        '-lsqlite3','-lpthread','-o',str(lib)],check=True,timeout=30)
    records=[]
    for repeat in range(args.repeats):
        for case in cases:
            directory=out/(str(repeat+1)+'-'+case['id']); directory.mkdir()
            prompt=RULES+'\nTASK\n'+case['task']; (directory/'prompt.txt').write_text(prompt)
            record=dict(case=case['id'],repeat=repeat+1,capability=case['capability'],status='transport-failure')
            transport=None
            attempt_started=time.monotonic()
            try:
                transport=DeepSeekInference(directory/'transport',env_file=args.env_file) if args.provider=='deepseek' else CodexInference(directory/'transport',model=args.model,effort=args.effort,catalog=args.catalog)
                response=transport.infer(prompt,SCHEMA); write(directory/'response.json',response)
                record.update(response=response)
                answer=strict_json(response['text'])
                validate_answer(answer)
                errors=[key for key,value in references[case['id']]['expected'].items() if answer.get(key)!=value]
                if case['capability']!='generation' and answer.get('source')!='': errors.append('unexpected-source')
                if case['capability']=='generation':
                    candidate=issuer(answer['source'],keys[1]); result=candidate.assess(**spec(case))
                    record['generated_native']=result
                    if result['model']!=references[case['id']]['native']['model']: errors.append('generated-model')
                else: candidate=issuer(case['source'],keys[1]) if 'source' in case else None
                record.update(errors=errors,status='semantic-failure' if errors else 'passed')
                if not errors and case['capability']=='late':
                    record['runtime']=late_pipeline(directory,keys,lib)
                native=references[case['id']]['native']
                if not errors and candidate:
                    result=handoff(case,candidate,case['id']+'-'+str(repeat+1))
                    record['publication_native']=result
                    if any(result[k]!=native[k] for k in ('proof','model','classification','admitted','exhausted')):
                        raise ValueError('fresh native evaluation differs from frozen reference')
                    if native['admitted'] and native['exhausted']:
                        p=Publication.from_payload(result['publication'].encode())
                        signature=candidate.attest(p,query='query',profile=case['profile'],target=case['target'],limit=case['limit'],output=emit)
                        record['runtime']=pipeline(directory,p,signature,keys,lib)
                    else:
                        assert result['publication'] is False
                        try: candidate.evaluate(**spec(case))
                        except ValueError: record['admission_rejected']=True
                        else: raise AssertionError('unknown/frontier admitted')
            except Exception as error:
                record['error']=str(error)
                if record['status']=='passed': record['status']='pipeline-failure'
                elif 'response' in record: record['status']='semantic-failure'
            finally:
                if transport: transport.close()
            record['attempt_elapsed_seconds']=time.monotonic()-attempt_started
            records.append(record); write(directory/'result.json',record); write(out/'results.json',records)
            print('CASE',repeat+1,case['id'],record['status'],record.get('errors',[]),record.get('error',''),flush=True)
    counts={status:sum(r['status']==status for r in records) for status in ('passed','semantic-failure','transport-failure','pipeline-failure')}
    elapsed=[r['response']['elapsed_seconds'] for r in records if 'response' in r]
    summary=dict(total=len(records),counts=counts,first_shot_passes=sum(r['status']=='passed' and r['repeat']==1 for r in records),
        first_shot_total=len(cases),model=args.model,effort=args.effort,model_calls_completed=len(elapsed),
        latency_median_seconds=statistics.median(elapsed) if elapsed else None,cost=None,
        cost_reason='provider usage receipt does not return billed monetary amount',provider=args.provider,
        runtime_pairs=sum(len(r.get('runtime',[])) for r in records),threshold=1.0,
        accepted=bool(records) and counts['passed']==len(records),no_repair=True)
    summary['latency_p95_seconds']=sorted(elapsed)[max(0, int(len(elapsed)*0.95+0.999)-1)] if elapsed else None
    summary['capabilities']={cap:dict(total=sum(r['capability']==cap for r in records),passed=sum(r['capability']==cap and r['status']=='passed' for r in records)) for cap in sorted({r['capability'] for r in records})}
    usages=[r['response']['usage'].get('last',{}) for r in records if r.get('response',{}).get('usage')]
    summary['tokens']={k:sum(u.get(k,0) for u in usages) for k in ('inputTokens','cachedInputTokens','outputTokens','reasoningOutputTokens','totalTokens')}
    if any('reasoningOutputTokens' not in u for u in usages):summary['tokens']['reasoningOutputTokens']=None
    first=[r['response']['first_content_seconds'] for r in records if r.get('response',{}).get('first_content_seconds') is not None]
    gaps=[r['response']['max_content_gap_seconds'] for r in records if r.get('response',{}).get('max_content_gap_seconds') is not None]
    summary['first_content_max_seconds']=max(first) if first else None
    summary['max_content_gap_seconds']=max(gaps) if gaps else None
    summary['usage_receipts']=len(usages)
    summary['latency_scope']='completed model calls only'
    summary['token_scope']='available usage receipts only; failed calls may have unreported usage'
    summary['first_token_timeout']=5
    write(out/'summary.json',summary); print('SUMMARY',json.dumps(summary),flush=True)
    return summary['accepted']


if __name__=='__main__':
    p=argparse.ArgumentParser(); p.add_argument('--output',required=True); p.add_argument('--catalog')
    p.add_argument('--model'); p.add_argument('--effort')
    p.add_argument('--provider',choices=('deepseek','codex'),default='deepseek')
    p.add_argument('--env-file',default=str(REPO.parent/'agent-semantic-protocols/.env'))
    p.add_argument('--reference-receipt')
    p.add_argument('--repeats',type=int,default=2); args=p.parse_args()
    if args.repeats<1: p.error('positive repeats required')
    raise SystemExit(0 if run(args) else 1)
