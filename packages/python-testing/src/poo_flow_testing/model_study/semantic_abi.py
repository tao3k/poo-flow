# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Frozen live Library acceptance through the current semantic ABI.

Model IO sees task data, actual Scheme source and an output schema. It never
sees a solved answer, semantic tutorial or a retry/repair instruction.
"""
import argparse
import asyncio
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import shlex
import subprocess
import sys
import time

from .semantic_cases import corpus
from .semantic_provider import predict


def sha(data):
    return hashlib.sha256(data).hexdigest()


def write(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


def configuration(path):
    values = {}
    for line in path.read_text().splitlines():
        name, separator, value = line.strip().removeprefix('export ').partition('=')
        name = name.strip()
        if separator and name in ('DEEPSEEK_API_KEY', 'DEEPSEEK_MODEL', 'ANTHROPIC_MODEL'):
            words = shlex.split(value, comments=True)
            if len(words) != 1:
                raise ValueError('configuration requires a single literal value: ' + name)
            values[name] = words[0]
    return values


def request_for(task, sources, model):
    schema = {'type': 'object', 'additionalProperties': False,
              'required': ['status', 'rows'], 'properties': {
                  'status': {'type': 'string', 'enum': ['complete', 'partial', 'rejected']},
                  'rows': {'type': 'array', 'items': {
                      'type': 'array', 'items': {'type': 'string'},
                      'minItems': 2, 'maxItems': 2}}}}
    content = json.dumps({'operation': 'temporal.solve', 'task': task,
                          'implementation': sources, 'JSON_output_schema': schema},
                         ensure_ascii=False, separators=(',', ':'))
    return {'model': model, 'input': [{'role': 'user', 'content': content}],
            'reasoning': {'effort': 'none'}, 'max_output_tokens': 1024,
            'text': {'format': {'type': 'json_schema', 'name': 'temporal_candidate',
                                'strict': True, 'schema': schema}}, 'stream': True}


def prepare(root, library, ascent, output, model):
    output.mkdir(parents=True, exist_ok=False)
    sources = {'src/ffi/semantic.ss': (root/'src/ffi/semantic.ss').read_text(),
               'gerbil-ascent/temporal/lens.ss': (ascent/'temporal/lens.ss').read_text()}
    source_paths = [Path(__file__), Path(__file__).with_name('semantic_cases.py'),
                    Path(__file__).with_name('semantic_provider.py'),
                    root/'packages/python-runtime/src/poo_flow_runtime/semantic_runtime.py',
                    root/'packages/python-runtime/src/poo_flow_runtime/_native/_semantic_build.py',
                    root/'src/ffi/semantic.ss', root/'bindings/runtime-c/src/semantic_host.c',
                    root/'bindings/runtime-c/include/poo_flow/semantic.h', ascent/'temporal/lens.ss']
    manifest = json.loads(Path(str(library)+'.json').read_text())
    for module in manifest['modules']:
        name = module['module']
        if name.startswith('gerbil-ascent/'):
            source_paths.append(ascent/(name.removeprefix('gerbil-ascent/')+'.ss'))
        elif name.startswith('poo-flow/'):
            source_paths.append(root/(name.removeprefix('poo-flow/')+'.ss'))
        elif name.startswith('core/'):
            source_paths.append(root/(name+'.ss'))
    digest = sha(library.read_bytes())
    assert manifest['schema'] == 'poo-flow.semantic-aot-artifact' and manifest['version'] == 1
    assert digest == manifest['artifactSha256']
    for key, path in [('sourceSha256', root/'src/ffi/semantic.ss'),
                      ('hostSha256', root/'bindings/runtime-c/src/semantic_host.c'),
                      ('headerSha256', root/'bindings/runtime-c/include/poo_flow/semantic.h')]:
        assert sha(path.read_bytes()) == manifest[key], key
    tasks = corpus()
    requests = {case['id']: request_for(case['request'], sources, model) for case in tasks}
    plan = {'schema': 'poo-flow.semantic-abi-live-plan', 'version': 1,
            'head': subprocess.check_output(['git', '-C', str(root), 'rev-parse', 'HEAD'], text=True).strip(),
            'artifactSha256': digest, 'model': model, 'reasoningEffort': 'none',
            'contentIdleSeconds': 5, 'totalCallSeconds': 90,
            'maximumCalls': 24, 'retries': 0, 'cases': tasks,
            'order': [{'case': c['id'], 'api': api} for c in tasks for api in ('sync', 'async')],
            'sources': {str(p): sha(p.read_bytes()) for p in source_paths},
            'requestSha256': {name: sha(json.dumps(value, ensure_ascii=False, sort_keys=True).encode())
                              for name, value in requests.items()},
            'scope': 'finite Temporal prediction through current Python/CFFI/Scheme ABI; not full Scheme understanding, real-time teaching, effect authorization or a control ABI freeze'}
    write(output/'plan.json', plan)
    write(output/'artifact.json', manifest)
    write(output/'requests.json', requests)
    return plan


def execute(root, library, output, key):
    from poo_flow_runtime.semantic_runtime import SemanticRuntime
    plan_bytes = (output/'plan.json').read_bytes()
    plan = json.loads(plan_bytes)
    requests = json.loads((output/'requests.json').read_text())
    assert sha(library.read_bytes()) == plan['artifactSha256']
    for path, digest in plan['sources'].items():
        assert sha(Path(path).read_bytes()) == digest, path
    for name, request in requests.items():
        assert sha(json.dumps(request, ensure_ascii=False, sort_keys=True).encode()) == plan['requestSha256'][name]
    with (output/'paid-batch-claim.json').open('x') as file:
        file.write(json.dumps({'planSha256': sha(plan_bytes), 'maximumCalls': plan['maximumCalls']})+'\n')
    tasks = {case['id']: case['request'] for case in plan['cases']}
    started = time.monotonic()
    records = []
    with SemanticRuntime(library, expected_digest=plan['artifactSha256']) as runtime:
        cold = time.monotonic() - started
        if cold > 5 or runtime.descriptor['abiVersion'] != 1:
            raise RuntimeError('native startup failed the current ABI/five-second gate')
        private = {name: runtime.call('temporal.solve', task) for name, task in tasks.items()}
        write(output/'native-private.json', private)
        controls = []
        for name, task in tasks.items():
            bad = runtime.observe_model_answer(task, '{"status":"invented","rows":[]}')
            assert bad['verdict'] == 'contradicted', name
            controls.append({'case': name, 'observation': bad})
        chain = tasks['chain']
        candidate = json.dumps({k: private['chain'][k] for k in ('status', 'rows')})
        changed = deepcopy(chain)
        changed['source']['parents'].clear()
        stale = runtime.observe_model_answer(changed, candidate)
        assert stale['verdict'] == 'contradicted'
        assert stale['bindingDigest'] != private['chain']['bindingDigest']
        write(output/'negative-controls.json', {'invalidCandidate': controls, 'staleSource': stale})
        for index, item in enumerate(plan['order']):
            task = tasks[item['case']]
            record = dict(item, index=index, planSha256=sha(plan_bytes),
                          artifactSha256=plan['artifactSha256'], passed=False)
            attempt_path = output/f'{index:02d}.json'
            write(attempt_path, record)
            print(f'MODEL START {index+1}/24 {item["case"]} {item["api"]}', flush=True)
            def emit(delta):
                print('.', end='', flush=True)
            async def predictor(supplied):
                assert supplied == task and supplied is not task
                return await predict(requests[item['case']], key, record, emit=emit)
            def sink(event):
                record['deliveredObservation'] = event
                write(output/f'{index:02d}.observation.json', event)
            async def asink(event):
                sink(event)
            call_started = time.monotonic()
            native_started = [None]
            async def timed_predictor(supplied):
                result = await predictor(supplied)
                native_started[0] = time.monotonic()
                return result
            try:
                if item['api'] == 'sync':
                    result = runtime.predict_temporal_answer(task, lambda supplied: asyncio.run(timed_predictor(supplied)),
                                                             observation_sink=sink)
                else:
                    result = asyncio.run(runtime.apredict_temporal_answer(task, timed_predictor, observation_sink=asink))
                record['nativeObservationSeconds'] = time.monotonic() - native_started[0]
                assert record['nativeObservationSeconds'] <= 5, 'native observation exceeded five seconds'
                record['result'] = result
                assert record['deliveredObservation'] == result
                expected = {key: private[item['case']][key] for key in ('status', 'rows')}
                assert (result['receipt']['verdict'] == 'consistent') == (result['candidate'] == expected)
                rebound = deepcopy(task)
                rebound['source']['generation'] += 10
                rebound['lens']['generation'] += 10
                observation = runtime.observe_model_answer(rebound, record['raw'])
                assert observation['bindingDigest'] != result['receipt']['bindingDigest']
                record['sourceRebinding'] = observation
                record['passed'] = result['receipt']['verdict'] == 'consistent'
                if not record['passed']:
                    record['failure'] = 'native semantic contradiction'
            except Exception as error:
                record['failure'] = type(error).__name__ + ': ' + str(error)
                response = getattr(error, 'response', None)
                if response is not None and response.status_code in (400, 401, 403, 404):
                    record['globalProviderFailure'] = response.status_code
            record['callSeconds'] = time.monotonic() - call_started
            write(attempt_path, record)
            records.append(record)
            print(f' RESULT passed={record["passed"]} failure={record.get("failure", "none")}', flush=True)
            if record.get('globalProviderFailure'):
                break
        ids = [r['responseId'] for r in records if r.get('responseId')]
        assert len(ids) == len(set(ids)), 'duplicate provider response IDs'
        report = {'schema': 'poo-flow.semantic-abi-live-receipt', 'version': 1,
                  'planSha256': sha(plan_bytes), 'artifactSha256': plan['artifactSha256'],
                  'descriptor': runtime.descriptor, 'nativeColdSeconds': cold,
                  'attempts': len(records), 'plannedCalls': plan['maximumCalls'],
                  'unattempted': plan['maximumCalls'] - len(records),
                  'passed': sum(r['passed'] for r in records),
                  'failed': sum(not r['passed'] for r in records), 'retries': 0,
                  'transportCompleted': sum(r.get('responseStatus') == 'completed' for r in records),
                  'abiObserved': sum('result' in r for r in records),
                  'sourceReboundCases': sum('sourceRebinding' in r for r in records),
                  'negativeControls': 13, 'scope': plan['scope'],
                  'sourceFreezeIntact': all(sha(Path(p).read_bytes()) == h for p, h in plan['sources'].items())}
        if not report['sourceFreezeIntact']:
            raise RuntimeError('source changed during real-model acceptance')
        write(output/'report.json', report)
    print(json.dumps(report), flush=True)
    return 0 if report['failed'] == 0 and report['unattempted'] == 0 else 1


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--poo-root', type=Path, required=True)
    parser.add_argument('--ascent-root', type=Path, required=True)
    parser.add_argument('--library', type=Path, required=True)
    parser.add_argument('--env-file', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--live', action='store_true')
    args = parser.parse_args()
    config = configuration(args.env_file)
    model = config.get('DEEPSEEK_MODEL') or config.get('ANTHROPIC_MODEL')
    if not model:
        raise ValueError('the provided configuration must declare its DeepSeek model')
    prepare(args.poo_root.resolve(), args.library.resolve(), args.ascent_root.resolve(), args.output, model)
    if args.live:
        return execute(args.poo_root.resolve(), args.library.resolve(), args.output, config['DEEPSEEK_API_KEY'])
    return 0


if __name__ == '__main__':
    sys.exit(main())
