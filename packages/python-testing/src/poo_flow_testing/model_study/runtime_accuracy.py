# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Historical prompted-study analysis; paid execution is retired by design."""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import sys

def study_manifest():
    """Read the immutable historical plan; it is not a future execution recipe."""
    archive = Path(__file__).resolve().parents[5] / (
        'docs/10-19-design/10.06-poo-module-system/evidence/'
        'python-scheme-runtime-20261003/plan.json')
    return json.loads(archive.read_text())


def corpus():
    return study_manifest()['corpus']


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
    args = parser.parse_args()
    if args.live:
        raise ValueError('prompted answer-supply experiment retired: not valid for no-Prompt architecture')
    from poo_flow_runtime.semantic_runtime import SemanticRuntime
    plan = study_manifest()
    encoded = json.dumps(plan, sort_keys=True, separators=(',', ':')).encode()
    digest = hashlib.sha256(encoded).hexdigest()
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / 'plan.json').write_bytes(encoded)
    sys.stdout.write(f'HISTORICAL-PLAN {digest}; native preflight only; provider calls disabled\n')
    sys.stdout.flush()
    library_digest = hashlib.sha256(args.library.read_bytes()).hexdigest()
    native = {}
    with SemanticRuntime(args.library, expected_digest=library_digest) as runtime:
        for case in plan['corpus']:
            native[case['id']] = runtime.call('temporal.solve', case['request'])
            assert {key: native[case['id']][key] for key in ['status', 'rows']} == case['gold'], case['id']
            sys.stdout.write(f'GOLD-OK {case["id"]}\n'); sys.stdout.flush()
        (args.output / 'native-gold.json').write_text(json.dumps(native, indent=2) + '\n')
        (args.output / 'artifact.json').write_text(json.dumps({'sha256': library_digest, 'descriptor': runtime.descriptor}) + '\n')


if __name__ == '__main__':
    main()
