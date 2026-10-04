# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Execute a frozen paid batch through the installed Library and record native observations.

Model IO sees task data, actual Scheme source and an output schema. It never
sees a solved answer, semantic tutorial or a retry/repair instruction.
"""
import asyncio
from copy import deepcopy
import json
from pathlib import Path
import statistics
import time

from .semantic_plan import sha, write
from .semantic_provider import predict
from .semantic_reporting import report_progress


def execute(root, library, output, key):
    from poo_flow_runtime.semantic_runtime import SemanticRuntime
    import poo_flow_runtime.semantic_runtime as implementation
    runtime_source = Path(implementation.__file__).resolve()
    if sha(runtime_source.read_bytes()) != sha((root/'packages/python-runtime/src/poo_flow_runtime/semantic_runtime.py').read_bytes()):
        raise ValueError('loaded Runtime does not match the frozen current interface source')
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
        report_progress('NATIVE-READY semantic ABI 1')
        private = {}
        for name, task in tasks.items():
            solving = time.monotonic()
            private[name] = runtime.call('temporal.solve', task)
            if time.monotonic() - solving > 5:
                raise RuntimeError('native solve exceeded five seconds')
            report_progress(f'NATIVE-SOLVE {name} {private[name]["status"]}')
        write(output/'native-private.json', private)
        controls = []
        for name, task in tasks.items():
            bad = runtime.observe_model_answer(task, '{"status":"invented","rows":[]}')
            assert bad['verdict'] == 'contradicted', name
            controls.append({'case': name, 'observation': bad})
            report_progress(f'NEGATIVE-CONTROL {name} {bad["verdict"]}')
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
            report_progress(f'MODEL START {index+1}/24 {item["case"]} {item["api"]}')
            def emit(delta):
                report_progress('.', end='')
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
            report_progress(f' RESULT passed={record["passed"]} failure={record.get("failure", "none")}')
            if record.get('globalProviderFailure'):
                break
        ids = [r['responseId'] for r in records if r.get('responseId')]
        assert len(ids) == len(set(ids)), 'duplicate provider response IDs'
        report = {'schema': 'poo-flow.semantic-abi-live-receipt', 'version': 1,
                  'planSha256': sha(plan_bytes), 'artifactSha256': plan['artifactSha256'],
                  'descriptor': runtime.descriptor, 'nativeColdSeconds': cold,
                  'runtimeModule': str(runtime_source),
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
        for api in ('sync', 'async'):
            group = [r for r in records if r['api'] == api]
            report[api] = {'attempts': len(group), 'passed': sum(r['passed'] for r in group),
                           'medianCallSeconds': statistics.median(r['callSeconds'] for r in group) if group else None}
        first = [r['contentGapsSeconds'][0] for r in records if r.get('contentGapsSeconds')]
        gaps = [gap for r in records for gap in r.get('contentGapsSeconds', [])[1:]]
        report['firstContentMaxSeconds'] = max(first, default=None)
        report['contentGapMaxSeconds'] = max(gaps, default=None)
        write(output/'report.json', report)
    report_progress(json.dumps(report))
    return 0 if report['failed'] == 0 and report['unattempted'] == 0 else 1


