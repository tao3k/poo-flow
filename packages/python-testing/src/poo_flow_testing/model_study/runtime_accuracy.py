# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Frozen paired Runtime accuracy study. Dry run makes no provider calls."""
from __future__ import annotations
import argparse
from copy import deepcopy
import hashlib
import json
import os
from pathlib import Path
import random
import sys
import time

RULES = '''Return only JSON {"status": ..., "rows": [[root, descendant], ...]}.
Compute positive-length directed reachability from root in the finite source.
Window is half-open [start,end); valid time is an exact point or closed bounds
about ONE point, not a duration. An unknown endpoint is unbounded (lower=0).
Every declared cut member must exist and have knowledge position <= asOf.
Any open cut, unavailable knowledge, uncertain inclusion or uncertain parent
order yields partial and NO rows. A declared clock/generation mismatch or
definite reversed parent order yields rejected and NO rows. A bounded horizon
that leaves a reachable descendant outside it yields partial. Otherwise return
complete and sorted unique root-descendant pairs through admitted cut/window
events. Parent order is guaranteed only when parent upper <= child lower.
No source is authenticated merely because it has a clock or identity label.
'''


def corpus():
    base = {'lens': {'generation': 1, 'clock': 'clock', 'start': 0, 'end': 10,
                     'asOf': 10, 'cut': 'cut', 'members': ['a', 'b', 'c'],
                     'horizon': 8, 'closed': True},
            'source': {'identity': 'source', 'generation': 1, 'clock': 'clock',
                       'events': [['a', 1, 1], ['b', 2, 2], ['c', 3, 3]],
                       'parents': [['a', 'b'], ['b', 'c']]}, 'root': 'a'}
    cases = []
    variants = [
        ('chain', 'complete', [['a', 'b'], ['a', 'c']]),
        ('withdrawal', 'complete', [['a', 'b']]),
        ('empty-edges', 'complete', []),
        ('window', 'complete', [['a', 'b']]),
        ('bounded-points', 'complete', [['a', 'b'], ['a', 'c']]),
        ('generation', 'complete', [['a', 'b'], ['a', 'c']]),
        ('open-cut', 'partial', []), ('late-knowledge', 'partial', []),
        ('uncertain-window', 'partial', []), ('horizon', 'partial', []),
        ('clock-mismatch', 'rejected', []), ('reversed-order', 'rejected', []),
    ]
    for name, status, rows in variants:
        request = deepcopy(base)
        if name == 'withdrawal': request['source']['parents'] = [['a', 'b']]
        elif name == 'empty-edges': request['source']['parents'] = []
        elif name == 'window': request['lens']['end'] = 3
        elif name == 'bounded-points':
            request['source']['events'] = [['a', ['between', 0, 1], 1], ['b', ['between', 2, 2], 2], ['c', ['between', 3, 4], 3]]
        elif name == 'generation': request['lens']['generation'] = request['source']['generation'] = 2
        elif name == 'open-cut': request['lens']['closed'] = False
        elif name == 'late-knowledge': request['lens']['asOf'] = 1
        elif name == 'uncertain-window': request['source']['events'][1][1] = ['between', 0, 20]
        elif name == 'horizon': request['lens']['horizon'] = 0
        elif name == 'clock-mismatch': request['source']['clock'] = 'other'
        elif name == 'reversed-order': request['source']['events'][0][1] = 5
        cases.append({'id': name, 'request': request, 'gold': {'status': status, 'rows': rows}})
    return cases


def study_manifest():
    tasks = [(case, repeat, arm) for case in corpus() for repeat in range(2)
             for arm in ['plain', 'native']]
    random.Random(20261003).shuffle(tasks)
    return {'schema': 'poo-flow.runtime-accuracy-plan.v1', 'model': 'deepseek-flash',
            'maxCalls': 48, 'retries': 0, 'maxInputBytes': 8000,
            'maxOutputTokens': 384, 'temperature': 0.3, 'repetitions': 2,
            'inputUsdPerMillion': 0.3, 'outputUsdPerMillion': 1.2,
            'maximumEstimatedUsd': 48 * (8000 * 0.3 + 384 * 1.2) / 1_000_000,
            'corpus': corpus(),
            'order': [{'case': c['id'], 'repeat': r, 'arm': a} for c, r, a in tasks],
            'rules': RULES, 'scope': 'finite temporal answer rendering with native assistance; no autonomous tool-selection claim'}


def score(text, gold):
    try:
        answer = json.loads(text)
        return (isinstance(answer, dict) and 'rows' in answer
                and answer.get('status') == gold['status']
                and sorted(answer.get('rows', [])) == sorted(gold['rows']))
    except (ValueError, TypeError, AttributeError):
        return False


def write_report(records, output):
    report = {}
    for arm in ['plain', 'native']:
        rows = [r for r in records if r['arm'] == arm]
        report[arm] = {'attempts': len(rows), 'correct': sum(r['correct'] for r in rows),
                       'inputTokens': sum(r['inputTokens'] for r in rows),
                       'outputTokens': sum(r['outputTokens'] for r in rows),
                       'seconds': sum(r['seconds'] for r in rows)}
    report['accuracyDelta'] = (report['native']['correct'] - report['plain']['correct']) / 24
    report['estimatedUsd'] = sum(r['inputTokens'] * 0.3 + r['outputTokens'] * 1.2 for r in records) / 1_000_000
    report['scope'] = study_manifest()['scope']
    output.write_text(json.dumps(report, indent=2) + '\n')
    return report


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--library', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--live', action='store_true')
    parser.add_argument('--approved-plan-sha256')
    args = parser.parse_args()
    from poo_flow_runtime.semantic_runtime import SemanticRuntime
    plan = study_manifest()
    encoded = json.dumps(plan, sort_keys=True, separators=(',', ':')).encode()
    digest = hashlib.sha256(encoded).hexdigest()
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / 'plan.json').write_bytes(encoded)
    sys.stdout.write(f'PLAN {digest} calls=48 conservative-cost<=$0.138\n')
    sys.stdout.flush()
    if args.live and args.approved_plan_sha256 != digest:
        raise ValueError('live execution requires the approved exact plan digest')
    if args.live and (args.output / 'attempts.jsonl').exists():
        raise ValueError('paid study already started; automatic reruns/retries are forbidden')
    library_digest = hashlib.sha256(args.library.read_bytes()).hexdigest()
    cases = {case['id']: case for case in plan['corpus']}
    native = {}
    with SemanticRuntime(args.library, expected_digest=library_digest) as runtime:
        for case in plan['corpus']:
            native[case['id']] = runtime.call('temporal.solve', case['request'])
            assert {key: native[case['id']][key] for key in ['status', 'rows']} == case['gold'], case['id']
            sys.stdout.write(f'GOLD-OK {case["id"]}\n'); sys.stdout.flush()
        (args.output / 'native-gold.json').write_text(json.dumps(native, indent=2) + '\n')
        (args.output / 'artifact.json').write_text(json.dumps({'sha256': library_digest, 'descriptor': runtime.descriptor}) + '\n')
    if not args.live:
        return
    from openai import OpenAI
    client = OpenAI(api_key=os.environ['DEEPSEEK_API_KEY'], base_url='https://api.deepseek.com', max_retries=0, timeout=45)
    records = []
    for index, item in enumerate(plan['order']):
        case = cases[item['case']]
        prompt = RULES + '\nSource task:\n' + json.dumps(case['request'], sort_keys=True)
        if item['arm'] == 'native':
            prompt += '\nPOO Scheme native result:\n' + json.dumps(native[case['id']], sort_keys=True)
        if len(prompt.encode()) > plan['maxInputBytes']:
            raise ValueError('input budget exceeded')
        sys.stdout.write(f'MODEL START {index+1}/48 {item["case"]} {item["arm"]}\n'); sys.stdout.flush()
        with (args.output / 'attempts.jsonl').open('a') as file:
            file.write(json.dumps(dict(item, attempt=index+1, planDigest=digest)) + '\n')
            file.flush()
            os.fsync(file.fileno())
        started = time.perf_counter()
        stream = client.responses.create(model=plan['model'], input=prompt,
                    max_output_tokens=plan['maxOutputTokens'], temperature=plan['temperature'],
                    reasoning={'effort': 'none'}, stream=True)
        response = None
        text = ''
        for event in stream:
            if event.type == 'response.output_text.delta':
                text += event.delta
                sys.stdout.write('.'); sys.stdout.flush()
            elif event.type in {'response.completed', 'response.failed', 'response.incomplete'}:
                response = event.response
            else:
                sys.stdout.write(f'[{event.type}]'); sys.stdout.flush()
        if response is None:
            raise RuntimeError('provider omitted terminal response')
        record = dict(item, responseId=response.id, raw=text, correct=score(text, case['gold']),
                      seconds=time.perf_counter()-started, inputTokens=response.usage.input_tokens,
                      outputTokens=response.usage.output_tokens, responseStatus=response.status)
        records.append(record)
        with (args.output / 'calls.jsonl').open('a') as file:
            file.write(json.dumps(record) + '\n')
        sys.stdout.write(f' DONE correct={record["correct"]}\n'); sys.stdout.flush()
    write_report(records, args.output / 'report.json')


if __name__ == '__main__':
    main()
