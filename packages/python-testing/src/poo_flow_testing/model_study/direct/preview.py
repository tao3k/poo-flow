# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Freeze input bytes and independently preflight native computation."""
import json
import os
from pathlib import Path
import subprocess
import sys
from .tasks import DIRECT_FAMILIES, DIRECT_MODULES, digest, task_program, expected_value, sexp
from .native import native_run

def producer_hashes():
    files = [*Path(__file__).parent.glob('*.py'), Path(__file__).parent.parent/'direct_understanding.py',
             Path(__file__).parent.parent/'prediction_transport.py']
    return {str(path.relative_to(Path(__file__).parent.parent)): digest(path.read_bytes())
            for path in sorted(files)}

def native_bindings():
    prefix = Path(os.environ['GERBIL_PATH'])/'lib/gerbil-ascent/program'
    files = [path for module in DIRECT_MODULES for path in prefix.glob(Path(module).stem+'*.o1')]
    if not files:
        raise ValueError('qualified compiled Scheme modules are missing')
    return {str(path): digest(path.read_bytes()) for path in sorted(files)}

def prepare(root, ascent, output):
    output.mkdir(parents=True, exist_ok=False)
    context = '\n'.join(f';;; file: {module}\n'+(ascent / module).read_text()
                        for module in DIRECT_MODULES)
    manifest = {'schema': 'poo-flow.direct-scheme-understanding-plan.v2',
        'model': 'deepseek-flash', 'maxCalls': 24, 'retries': 0,
        'maxInputBytes': 98304, 'maxOutputTokens': 8192, 'budgetCeilingUsd': 1,
        'conservativeMaximumUsd': 24*(98304*.3+8192*1.2)/1_000_000,
        'pooHead': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip(),
        'ascentHead': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ascent, text=True).strip(),
        'modules': {name: digest((ascent/name).read_bytes()) for name in DIRECT_MODULES},
        'templates': {name: digest((root/'t/model-study/direct-understanding'/f'{name}.ss').read_bytes())
                      for name in DIRECT_FAMILIES},
        'producerHashes': producer_hashes(),
        'nativeBindings': native_bindings(),
        'scorerSha256': digest((root/'t/model-study/direct-understanding/prediction-score.ss').read_bytes()),
        'inputContract': 'actual module source and Scheme check-equal? task with missing expected datum; no semantic instructions',
        'sourceClosure': 'three named modules only; dependencies are not all presented',
        'outputContract': 'unique inert datum or check-equal? result quoted-datum; explanations stripped without oracle selection; never evaluated',
        'transportContract': 'bounded unique prediction extraction; ambiguity and EOF reject',
        'cases': [], 'order': []}
    imports = ''
    for module in (':gerbil-ascent/program/scheme-language',):
        imports += f'(displayln "IMPORT {module}") (force-output)\n(import {module})\n(displayln "MODULE-OK {module}") (force-output)\n'
    for family in DIRECT_FAMILIES:
        for variant in ('initial', 'transfer'):
            case = f'{family}-{variant}'
            program = task_program(root, family, variant)
            task = output / f'{case}.ss'
            task.write_text(imports + program + '\n(write result) (newline)\n(displayln "HARNESS-OK direct-compute")\n(displayln "OK") (force-output)\n')
            log = output / f'{case}.native.log'
            text = native_run(root, ['just', 'model-understanding-compute', str(task)], log)
            actual = text.split('HARNESS-OK direct-compute')[0].splitlines()[-1]
            expected = sexp(expected_value(family, variant))
            if actual != expected:
                raise AssertionError(f'independent oracle mismatch {case}: {actual} != {expected}')
            private = output / 'private'; private.mkdir(exist_ok=True)
            (private / f'{case}.sexp').write_text(actual+'\n')
            payload = context + '\n(import :std/test :gerbil-ascent/program/scheme-language)\n' + program + "\n(check-equal? result '?)\n"
            if len(payload.encode()) > manifest['maxInputBytes']:
                raise ValueError('source/task input exceeds frozen byte bound')
            (output / f'{case}.input.ss').write_text(payload)
            manifest['cases'].append({'id': case, 'family': family, 'variant': variant,
                'inputSha256': digest(payload.encode()), 'inputBytes': len(payload.encode()),
                'nativeProgramSha256': digest(task.read_bytes()), 'expectedSha256': digest((actual+'\n').encode())})
            sys.stdout.write(f'COMPUTE-OK {case}\n'); sys.stdout.flush()
    for index, family in enumerate(DIRECT_FAMILIES):
        initial_arms = [('initial-none', 'none', 'initial'), ('initial-high', 'high', 'initial')]
        transfer_arms = [('transfer-fresh', 'high', 'transfer'), ('transfer-feedback', 'high', 'transfer')]
        if index % 2:
            initial_arms.reverse(); transfer_arms.reverse()
        for arm, effort, variant in initial_arms + transfer_arms:
            manifest['order'].append({'family': family, 'arm': arm, 'reasoningEffort': effort,
                                      'case': f'{family}-{variant}'})
    encoded = json.dumps(manifest, sort_keys=True, separators=(',', ':')).encode()
    (output/'plan.json').write_bytes(encoded)
    sys.stdout.write(f'PREPARED {digest(encoded)} native=12 modelCalls=0\n'); sys.stdout.flush()
    return manifest
