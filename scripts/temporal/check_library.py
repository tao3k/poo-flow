# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Fresh Temporal Library acceptance on Python, native semantics and DeepSeek.

The receipt covers library contracts. Application delivery is outside this gate.
No skipped tests, partial model corpus, or changed sources can pass the gate.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import selectors
import signal
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

from model_study_receipt import audit

REPO = Path(__file__).resolve().parents[2]
TESTS = tuple(str(p.relative_to(REPO)) for p in sorted(
    (REPO / 'packages/python-runtime/tests/unit').glob('test_*.py')))


def source_manifest():
    files = set()
    for directory in ('packages/python-runtime/src/poo_flow_runtime',
                      'modules/temporal-causality', 'modules/tla-plus', 'scripts/temporal',
                      'bindings/runtime-c/src', 'bindings/runtime-c/include',
                      'packages/python-runtime/tests/fixtures', 'packages/python-runtime/tests/unit',
                      'core', 'src', 'modules/funflow', 'modules/workflow',
                      'modules/memory-core', 'modules/sandbox-core', 'modules/agent-sandbox',
                      'bindings/runtime-c/bundle-v1', 't/fixtures'):
        files.update(p for p in (REPO / directory).rglob('*')
                     if p.is_file() and p.suffix in ('.py', '.ss', '.c', '.h', '.json', '.tla', '.netstring'))
    files.update(REPO / p for p in TESTS)
    files.update(REPO / 'packages/python-runtime' / name
                 for name in ('pyproject.toml', 'uv.lock'))
    return {str(p.relative_to(REPO)): 'sha256:' + hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted(files)}


def native_manifest(progress=lambda count: None):
    """Bind configured native Library/parser artifacts, including loader versions."""
    roots = [Path(p) for p in os.environ.get('GERBIL_LOADPATH', '').split(os.pathsep) if p]
    if os.environ.get('GERBIL_PATH'):
        roots.append(Path(os.environ['GERBIL_PATH']) / 'lib')
    files = set()
    for root in roots:
        for namespace in ('poo-flow', 'gerbil-parser', 'clan/poo'):
            directory = root / namespace
            if directory.is_dir() and not (directory / '.git').exists():
                files.update(p.resolve() for p in directory.rglob('*') if p.is_file()
                             and (p.suffix in ('.ssi', '.scm') or re.fullmatch(r'\.o[0-9]+', p.suffix)))
    for name in ('POO_FLOW_RUNTIME_V0_LIBRARY', 'POO_FLOW_BUNDLE_V1_LIBRARY'):
        configured = os.environ.get(name)
        if configured:
            files.add(Path(configured).expanduser().resolve())
    files.update((REPO / 'packages/python-runtime/src/poo_flow_runtime/_native').glob('*.so'))
    artifacts = {}
    for count, p in enumerate(sorted(files), 1):
        artifacts[str(p)] = 'sha256:' + hashlib.sha256(p.read_bytes()).hexdigest()
        if count % 128 == 0:
            progress(count)
    progress(len(artifacts))
    return dict(load_path=os.environ.get('GERBIL_LOADPATH', ''),
                gerbil_path=os.environ.get('GERBIL_PATH', ''), artifacts=artifacts)


def test_receipt(path):
    suites = ET.parse(path).getroot()
    cases = list(suites.iter('testcase'))
    if not cases or any(list(case) and any(c.tag in ('failure', 'error', 'skipped')
                                         for c in case) for case in cases):
        raise ValueError('Library tests failed, errored, skipped or were empty')
    modules = {case.attrib.get('classname', '').split('.')[-1] for case in cases}
    if modules != {Path(p).stem for p in TESTS}:
        raise ValueError('Library test inventory differs from required modules')
    return dict(passed=len(cases), failed=0, skipped=0,
                modules=sorted(modules))


def run(args):
    out = Path(args.output).resolve()
    out.mkdir(parents=True, exist_ok=False)
    manifest = source_manifest()
    (out / 'sources.json').write_text(json.dumps(manifest, indent=2) + '\n')
    progress = lambda count: print('NATIVE-ARTIFACTS-HASHED', count, flush=True)
    native = native_manifest(progress)
    (out / 'native-artifacts.json').write_text(json.dumps(native, indent=2) + '\n')
    env = dict(os.environ, POO_FLOW_TEST_NATIVE_EVALUATOR='1',
               POO_FLOW_SCHEME_LOAD_PROGRESS='1')
    env['PYTHONPATH'] = str(REPO / 'packages/python-runtime/src') + os.pathsep + env.get('PYTHONPATH', '')
    summary = dict(accepted=False, scope='temporal-library-basic-v1',
                   model_provider='deepseek', external_business_required=False)

    def execute(command, log):
        with log.open('w') as stream:
            child = subprocess.Popen(command, cwd=REPO, env=env, stdout=subprocess.PIPE,
                                     stderr=subprocess.STDOUT, start_new_session=True)
            selector = selectors.DefaultSelector()
            selector.register(child.stdout, selectors.EVENT_READ)
            deadline = time.monotonic() + (900 if log.name == 'tests.log' else args.repeats * 20 * 600)
            try:
                while selector.get_map():
                    remaining = deadline - time.monotonic()
                    if remaining <= 0:
                        raise TimeoutError('Library stage exceeded total deadline: ' + log.name)
                    for key, _ in selector.select(min(1, remaining)):
                        data = os.read(key.fd, 65536)
                        if not data:
                            selector.unregister(key.fileobj)
                        else:
                            stream.write(data.decode('utf-8', errors='replace')); stream.flush()
                            sys.stdout.buffer.write(data); sys.stdout.buffer.flush()
                if child.wait(timeout=max(.01, deadline - time.monotonic())) != 0:
                    raise ValueError('Library gate stage failed: ' + log.name)
            finally:
                selector.close()
                child.stdout.close()
                if child.poll() is None:
                    os.killpg(child.pid, signal.SIGKILL); child.wait()

    try:
        # Transport negative controls intentionally wait for the complete five
        # second content deadline. An identical outer timer would kill pytest
        # before it can assert that the inner supervisor rejected the call.
        execute([sys.executable, '-m', 'pytest', '-o', 'addopts=', '-vv', '-s',
                 '--junitxml=' + str(out / 'tests.xml'), *TESTS], out / 'tests.log')
        summary['tests'] = test_receipt(out / 'tests.xml')
        command = [sys.executable, '-u', 'scripts/temporal/model_study.py',
                   '--output', str(out / 'model'), '--provider', 'deepseek',
                   '--env-file', str(Path(args.env_file).expanduser()), '--repeats', str(args.repeats)]
        if args.reference_receipt:
            command += ['--reference-receipt', args.reference_receipt]
        # The transport supervises actual model content; a generic output
        # watchdog must not allow native/logging progress to mask a stalled LLM.
        execute(command, out / 'model.log')
        summary['model_audit'] = audit(out / 'model')
        if not summary['model_audit']['accepted']:
            raise ValueError('real model acceptance failed')
        if source_manifest() != manifest:
            raise ValueError('Library sources changed during acceptance')
        if native_manifest(progress) != native:
            raise ValueError('Native artifacts changed during acceptance')
        summary['accepted'] = True
    except Exception as error:
        summary['error'] = str(error)
    (out / 'receipt.json').write_text(json.dumps(summary, indent=2) + '\n')
    print('LIBRARY-ACCEPTANCE', json.dumps(summary), flush=True)
    return summary['accepted']


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True)
    parser.add_argument('--env-file', required=True)
    parser.add_argument('--reference-receipt')
    parser.add_argument('--repeats', type=int, default=2)
    options = parser.parse_args()
    if options.repeats < 2:
        parser.error('Library acceptance requires at least two complete corpus passes')
    raise SystemExit(0 if run(options) else 1)
