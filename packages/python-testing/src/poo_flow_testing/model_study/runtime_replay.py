# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Offline analysis and native final-answer replay; never creates a provider client."""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import random
import statistics
import sys

from .runtime_accuracy import score


def analyze(plan, records):
    cases = {case['id']: case for case in plan['corpus']}
    assert len(records) == plan['maxCalls'] == 48
    assert len({record['responseId'] for record in records}) == 48
    assert [{key: row[key] for key in ('case', 'repeat', 'arm')}
            for row in records] == plan['order']
    result = {'schema': 'poo-flow.runtime-accuracy-analysis.v1',
              'calls': len(records), 'retries': 0, 'scope': plan['scope']}
    for arm in ('plain', 'native'):
        rows = [row for row in records if row['arm'] == arm]
        tp = fp = fn = statuses = 0
        errors = []
        for row in rows:
            gold = cases[row['case']]['gold']
            assert row['responseStatus'] == 'completed'
            assert score(row['raw'], gold) == row['correct']
            answer = json.loads(row['raw'])
            statuses += answer.get('status') == gold['status']
            actual = {tuple(pair) for pair in answer.get('rows', [])}
            expected = {tuple(pair) for pair in gold['rows']}
            tp += len(actual & expected); fp += len(actual - expected); fn += len(expected - actual)
            if not row['correct']:
                errors.append({key: row[key] for key in ('case', 'repeat', 'raw')})
        times = sorted(row['seconds'] for row in rows)
        inputs = sum(row['inputTokens'] for row in rows)
        outputs = sum(row['outputTokens'] for row in rows)
        result[arm] = dict(correct=sum(row['correct'] for row in rows), attempts=len(rows),
                           accuracy=sum(row['correct'] for row in rows) / len(rows),
                           statusCorrect=statuses, rowTruePositive=tp, rowFalsePositive=fp,
                           rowFalseNegative=fn, rowPrecision=tp / (tp + fp) if tp + fp else None,
                           rowRecall=tp / (tp + fn) if tp + fn else None,
                           medianSeconds=statistics.median(times), p95Seconds=times[int(.95*len(times))],
                           meanSeconds=statistics.mean(times), inputTokens=inputs, outputTokens=outputs,
                           estimatedUsdAtPeakCeiling=(inputs*.3 + outputs*1.2)/1_000_000,
                           errors=errors)
    result['accuracyDelta'] = result['native']['accuracy'] - result['plain']['accuracy']
    deltas = [sum((1 if row['arm'] == 'native' else -1) * row['correct']
                  for row in records if row['case'] == case) / plan['repetitions'] for case in cases]
    rng = random.Random(20261003)
    samples = sorted(statistics.mean(rng.choices(deltas, k=len(deltas))) for _ in range(10000))
    result['caseClusterBootstrap95'] = [samples[250], samples[9750]]
    result['estimatedTotalUsdAtPeakCeiling'] = sum(result[arm]['estimatedUsdAtPeakCeiling']
                                                  for arm in ('plain', 'native'))
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--study', type=Path, required=True)
    parser.add_argument('--library', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    plan = json.loads((args.study / 'plan.json').read_text())
    records = [json.loads(line) for line in (args.study / 'calls.jsonl').read_text().splitlines()]
    analysis = analyze(plan, records)
    from poo_flow_runtime.semantic_runtime import SemanticRuntime
    digest = hashlib.sha256(args.library.read_bytes()).hexdigest()
    cases = {case['id']: case for case in plan['corpus']}
    replay = []
    with SemanticRuntime(args.library, expected_digest=digest) as runtime:
        for index, row in enumerate(records):
            task = cases[row['case']]['request']
            result = runtime.validate_model_answer(task, row['raw'])
            accepted = result['verdict'] == 'consistent'
            assert accepted == row['correct'], row
            replay.append(dict(case=row['case'], repeat=row['repeat'], arm=row['arm'],
                               responseId=row['responseId'], correct=row['correct'], **result))
            sys.stdout.write(f'REPLAY {index+1}/48 {row["arm"]} {result["verdict"]}\n'); sys.stdout.flush()
    gate = {'schema': 'poo-flow.runtime-final-answer-gate.v1', 'artifactSha256': digest,
            'paidCalls': 0, 'pipeline': 'validate_model_answer (historical response replay only)', 'records': replay}
    for arm in ('plain', 'native'):
        rows = [row for row in replay if row['arm'] == arm]
        accepted = [row for row in rows if row['verdict'] == 'consistent']
        gate[arm] = {'accepted': len(accepted), 'rejected': len(rows)-len(accepted),
                     'coverage': len(accepted)/len(rows),
                     'acceptedAccuracy': sum(row['correct'] for row in accepted)/len(accepted),
                     'falseAccepts': sum(not row['correct'] for row in accepted),
                     'falseRejects': sum(row['correct'] for row in rows if row not in accepted)}
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / 'analysis.json').write_text(json.dumps(analysis, indent=2)+'\n')
    (args.output / 'final-gate.json').write_text(json.dumps(gate, indent=2)+'\n')
    sys.stdout.write('REPLAY-OK no new paid calls\n'); sys.stdout.flush()


if __name__ == '__main__':
    main()
