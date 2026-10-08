#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Check the immutable Temporal consumer graph; this is not semantic admission."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys
import tomllib

ROOT = Path(__file__).resolve().parents[2]
MRR = 'https://github.com/tao3k/meta-relational-reasoning.git'
DATA = 'https://github.com/tao3k/mrr-data.git'


def read(path: Path) -> dict:
    return tomllib.loads(path.read_text())


def check(root: Path = ROOT, resolved: dict | None = None) -> tuple[str, str]:
    parent = root / 'bindings/rust-runtime'
    physical = parent / 'qualification/physical-roundtrip'
    deps = read(parent / 'Cargo.toml')['dependencies']
    owner = deps['meta-relational-reasoning']
    mrr = owner['rev']
    physical_deps = read(physical / 'Cargo.toml')['dependencies']
    data = physical_deps['mrr-data-core']['rev']
    for name, dep in (*deps.items(), *physical_deps.items()):
        if isinstance(dep, dict) and dep.get('git') in (MRR, DATA):
            expected = mrr if dep['git'] == MRR else data
            if dep.get('rev') != expected:
                raise ValueError(f'{name}: divergent immutable revision')
    if owner['git'] != MRR:
        raise ValueError('wrong MRR producer')
    expected_sources = {url: f'git+{url}?rev={rev}#{rev}'
                        for url, rev in ((MRR, mrr), (DATA, data))}
    for directory in (parent, physical):
        found = set()
        for package in read(directory / 'Cargo.lock')['package']:
            source = package.get('source', '')
            for url, expected in expected_sources.items():
                if source.split('?', 1)[0].split('#', 1)[0] == f'git+{url}':
                    if source != expected:
                        raise ValueError(f'{directory.name}/{package["name"]}: stale or duplicate owner')
                    found.add(url)
        required = {MRR, DATA}
        if not required <= found:
            raise ValueError(f'{directory.name}: producer missing from actual lock')
    if resolved is not None:
        sources = {p.get('source') for p in resolved['packages']}
        if not set(expected_sources.values()) <= sources:
            raise ValueError('resolved graph does not contain both locked producers')
        for package in resolved['packages']:
            source = package.get('source') or ''
            for url, expected in expected_sources.items():
                if source.split('?', 1)[0].split('#', 1)[0] == f'git+{url}' and source != expected:
                    raise ValueError('resolved graph contains a second producer')
        core = next(p for p in resolved['packages'] if p['name'] == 'mrr-data-core')
        data_root = Path(core['manifest_path']).resolve().parents[2]
        commit = subprocess.run(['git', '-C', str(data_root), 'rev-parse', 'HEAD'],
                                capture_output=True, text=True, check=True).stdout.strip()
        if commit != data:
            raise ValueError('resolved Data checkout does not match its immutable source')
        for name in ('meta-relational-reasoning', 'mrr-property-source'):
            dep = read(data_root / 'Cargo.toml')['workspace']['dependencies'][name]
            if dep.get('git') != MRR or dep.get('rev') != mrr:
                raise ValueError(f'Data producer declares a different {name} owner')
    return mrr, data


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--resolved', action='store_true',
                        help='read actual locked Cargo metadata from stdin, without storing it')
    args = parser.parse_args()
    mrr, data = check(resolved=json.load(sys.stdin) if args.resolved else None)
    print(f'MRR-GRAPH-OK mrr={mrr} data={data} resolved={args.resolved}', flush=True)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
