# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Frozen real-provider to Library to provider roundtrips, distinct from prediction scores."""
import argparse
import asyncio
from copy import deepcopy
import json
from pathlib import Path
import subprocess
import time

from .semantic_cases import corpus
from .semantic_plan import configuration, sha, write
from .semantic_provider import predict
from .semantic_reporting import report_progress


def prepare(root, library, output, model):
    from poo_flow_runtime.semantic_tools import temporal_tool_definition
    output.mkdir(parents=True, exist_ok=False)
    cases = corpus()
    for case in cases:
        case['request']['lens']['generation'] += 100
        case['request']['source']['generation'] += 100
        case['request']['source']['identity'] = 'tool-' + case['id']
        case['request']['lens']['cut'] = 'tool-cut-' + case['id']
    paths = [Path(__file__), Path(__file__).with_name('semantic_cases.py'),
             Path(__file__).with_name('semantic_provider.py'),
             Path(__file__).with_name('semantic_reporting.py'),
             Path(__file__).with_name('semantic_plan.py'),
             root/'packages/python-runtime/src/poo_flow_runtime/semantic_runtime.py',
             root/'packages/python-runtime/src/poo_flow_runtime/semantic_tools.py']
    plan = {'schema': 'poo-flow.semantic-tool-live-plan', 'version': 1,
            'head': subprocess.check_output(['git', '-C', str(root), 'rev-parse', 'HEAD'], text=True).strip(),
            'artifactSha256': sha(library.read_bytes()), 'cases': cases, 'model': model,
            'sources': {str(p): sha(p.read_bytes()) for p in paths},
            'maximumCalls': 48, 'retries': 0, 'contentIdleSeconds': 5,
            'toolArgumentProgressKind': 'response.function_call_arguments.delta',
            'finalProgressKind': 'response.output_text.delta', 'temperature': 0.0,
            'tool': temporal_tool_definition(),
            'scope': 'forced read-only tool argument fidelity, current-task binding, sync/async native execution and model consumption of actual tool output; not unaided source comprehension, autonomous tool choice or business IO'}
    write(output/'plan.json', plan)
    return plan


def _tool_request(plan, task):
    return {'model': plan['model'], 'reasoning': {'effort': 'none'}, 'temperature': 0.0,
            'max_output_tokens': 2048, 'stream': True,
            'input': [{'role': 'user', 'content': 'Invoke the read-only Temporal Library tool once with this exact task:\n' + json.dumps(task)}],
            'tools': [plan['tool']],
            'tool_choice': {'type': 'function', 'name': 'poo_flow_temporal_solve'}}


def _output_request(plan, request, call, result):
    schema = {'type': 'object', 'additionalProperties': False,
              'required': ['status', 'rows', 'bindingDigest'], 'properties': {
                  'status': {'type': 'string'}, 'bindingDigest': {'type': 'string'},
                  'rows': {'type': 'array', 'items': {'type': 'array', 'items': {'type': 'string'}}}}}
    return {'model': plan['model'], 'reasoning': {'effort': 'none'}, 'temperature': 0.0,
            'max_output_tokens': 2048, 'stream': True,
            'input': request['input'] + [call, {'type': 'function_call_output',
                    'call_id': call['call_id'], 'output': json.dumps(result)},
                    {'role': 'user', 'content': 'Return only status, rows and bindingDigest from the Library result as JSON.'}],
            'text': {'format': {'type': 'json_schema', 'name': 'library_result',
                                'strict': True, 'schema': schema}}}


async def _roundtrip(runtime, plan, case, api, key, path):
    from poo_flow_runtime.semantic_tools import invoke_temporal_tool, ainvoke_temporal_tool
    from poo_flow_runtime.semantic_runtime import _unique_json_pairs
    record = {'case': case['id'], 'api': api, 'passed': False, 'tool': {}, 'final': {}}
    task = deepcopy(case['request'])
    request = _tool_request(plan, task)
    record['toolRequest'] = request
    try:
        await predict(request, key, record['tool'], emit=lambda _: report_progress('.', end=''),
                      content_event='response.function_call_arguments.delta')
        calls = record['tool'].get('toolCalls', [])
        if len(calls) != 1 or calls[0].get('arguments') != record['tool']['raw']:
            raise ValueError('exactly one completed streamed tool call is required')
        call = calls[0]
        record['call'] = call
        started = time.monotonic()
        if api == 'sync':
            result = invoke_temporal_tool(runtime, task, call)
        else:
            result = await ainvoke_temporal_tool(runtime, task, call)
        record['nativeSeconds'] = time.monotonic() - started
        if record['nativeSeconds'] > 5:
            raise ValueError('native tool call exceeded five seconds')
        record['nativeResult'] = result
        expected = {k: result['result'][k] for k in ('status', 'rows', 'bindingDigest')}
        final_request = _output_request(plan, request, call, result)
        record['finalRequest'] = final_request
        text = await predict(final_request, key, record['final'], emit=lambda _: report_progress('.', end=''))
        if json.loads(text, object_pairs_hook=_unique_json_pairs) != expected:
            raise ValueError('model final output differs from actual Library result')
        record['passed'] = True
    except Exception as error:
        record['failure'] = type(error).__name__ + ': ' + str(error)
    write(path, record)
    return record


def execute(root, library, output, key):
    from poo_flow_runtime.semantic_runtime import SemanticRuntime
    import poo_flow_runtime.semantic_tools as installed
    plan_bytes = (output/'plan.json').read_bytes()
    plan = json.loads(plan_bytes)
    assert sha(library.read_bytes()) == plan['artifactSha256']
    assert sha(Path(installed.__file__).read_bytes()) == plan['sources'][str(root/'packages/python-runtime/src/poo_flow_runtime/semantic_tools.py')]
    for path, digest in plan['sources'].items():
        assert sha(Path(path).read_bytes()) == digest, path
    with (output/'paid-batch-claim.json').open('x') as file:
        file.write(json.dumps({'planSha256': sha(plan_bytes), 'maximumCalls': 48}) + '\n')
    records = []
    with SemanticRuntime(library, expected_digest=plan['artifactSha256']) as runtime:
        for case in plan['cases']:
            for api in ('sync', 'async'):
                report_progress(f'TOOL ROUNDTRIP {case["id"]} {api}')
                record = asyncio.run(_roundtrip(runtime, plan, case, api, key, output/f'{len(records):02d}.json'))
                records.append(record)
                report_progress(f' RESULT passed={record["passed"]} failure={record.get("failure", "none")}')
    report = {'schema': 'poo-flow.semantic-tool-live-receipt', 'planSha256': sha(plan_bytes),
              'roundtrips': len(records), 'passed': sum(r['passed'] for r in records),
              'failed': sum(not r['passed'] for r in records), 'retries': 0, 'scope': plan['scope'],
              'nativeCalls': sum('nativeResult' in r for r in records),
              'providerResponses': sum(p.get('responseStatus') == 'completed' for r in records for p in (r['tool'], r['final'])),
              'sourceFreezeIntact': all(sha(Path(p).read_bytes()) == h for p, h in plan['sources'].items())}
    ids = [p['responseId'] for r in records for p in (r['tool'], r['final']) if p.get('responseId')]
    assert len(ids) == len(set(ids)) and report['sourceFreezeIntact']
    write(output/'report.json', report)
    report_progress(json.dumps(report))
    return 0 if report['failed'] == 0 else 1


def main():
    parser = argparse.ArgumentParser()
    for flag in ('poo-root', 'library', 'env-file', 'output'):
        parser.add_argument('--' + flag, type=Path, required=True)
    parser.add_argument('--live', action='store_true')
    args = parser.parse_args()
    config = configuration(args.env_file)
    model = config.get('DEEPSEEK_MODEL') or config['ANTHROPIC_MODEL']
    root, library = args.poo_root.resolve(), args.library.resolve()
    prepare(root, library, args.output, model)
    return execute(root, library, args.output, config['DEEPSEEK_API_KEY']) if args.live else 0


if __name__ == '__main__':
    raise SystemExit(main())
