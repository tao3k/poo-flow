# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Freeze tasks, public source, producer and artifact identities before model IO.

Model IO sees task data, actual Scheme source and an output schema. It never
sees a solved answer, semantic tutorial or a retry/repair instruction.
"""
import hashlib
import json
from pathlib import Path
import shlex
import subprocess

from .semantic_cases import corpus
from .semantic_sources import project_sources


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
                  'status': {'type': 'string', 'enum': ['complete', 'partial', 'rejected', 'unknown']},
                  'rows': {'type': 'array', 'items': {
                      'type': 'array', 'items': {'type': 'string'},
                      'minItems': 2, 'maxItems': 2}}}}
    content = '\n\n'.join(';;; SOURCE ' + name + '\n' + source
                            for name, source in sources.items())
    content += ('\n\n;;; TASK JSON\n' + json.dumps(task, ensure_ascii=False, indent=2)
                + '\n\n;;; EVALUATION\n'
                'Treat TASK JSON as the task hash table passed to this expression:\n'
                '(semantic-call "temporal.solve" (json->string task))\n'
                'Evaluate using the supplied implementation, following guards, loops,\n'
                'filters and strict/inclusive comparisons literally. Return only the\n'
                'status and rows fields of the resulting JSON object. Keep rows as\n'
                'arrays of two event IDs, without an execution-status wrapper, prose\n'
                'or stringifying nested arrays.\n')
    return {'model': model, 'input': [{'role': 'user', 'content': content}],
            'reasoning': {'effort': 'none'}, 'temperature': 0.0, 'max_output_tokens': 1024,
            'text': {'format': {'type': 'json_schema', 'name': 'temporal_candidate',
                                'strict': True, 'schema': schema}}, 'stream': True}


def prepare(root, library, ascent, output, model):
    output.mkdir(parents=True, exist_ok=False)
    manifest = json.loads(Path(str(library)+'.json').read_text())
    sources = project_sources(root, ascent, manifest)
    source_paths = [Path(__file__), Path(__file__).with_name('semantic_abi.py'),
                    Path(__file__).with_name('semantic_execution.py'), Path(__file__).with_name('semantic_cases.py'),
                    Path(__file__).with_name('semantic_provider.py'),
                    Path(__file__).with_name('semantic_reporting.py'),
                    Path(__file__).with_name('semantic_sources.py'),
                    ascent/'program/scheme-language.ss',
                    root/'packages/python-runtime/src/poo_flow_runtime/semantic_runtime.py',
                    root/'packages/python-runtime/src/poo_flow_runtime/_native/_semantic_build.py',
                    root/'src/ffi/semantic.ss', root/'bindings/runtime-c/src/semantic_host.c',
                    root/'bindings/runtime-c/include/poo_flow/semantic.h', ascent/'temporal/lens.ss']
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
            'artifactSha256': digest, 'model': model, 'reasoningEffort': 'none', 'temperature': 0.0,
            'inputRepresentation': 'compiler-enumerated project runtime source closure and plain JSON task',
            'modelSourceSha256': {name: sha(value.encode()) for name, value in sources.items()},
            'platformModules': [m['module'] for m in manifest['modules']
                                if m['module'].startswith(('gerbil/', 'std/', 'clan/'))],
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


