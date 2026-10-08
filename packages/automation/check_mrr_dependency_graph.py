#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Verify external MRR consumer ownership and its exact CI checkout pin."""
from __future__ import annotations

from pathlib import Path
import re
import tomllib

ROOT = Path(__file__).resolve().parents[2]


def check(root: Path = ROOT) -> str:
    consumer = tomllib.loads((root / 'packages/automation/mrr-runtime.toml').read_text())['consumer']
    if consumer['repository'] != 'tao3k/meta-relational-reasoning':
        raise ValueError('runtime must be owned by MRR')
    revision = consumer['rev']
    if not re.fullmatch('[0-9a-f]{40}', revision):
        raise ValueError('runtime needs a full immutable revision')
    if consumer['path'] != '.ci/mrr-runtime' or consumer['manifest'] != 'runtime/Cargo.toml':
        raise ValueError('wrong external runtime location')
    for path in ('bindings/rust-runtime/Cargo.toml', 'bindings/rust-runtime/src/lib.rs'):
        if (root / path).exists():
            raise ValueError('POO must not own a Rust runtime or compatibility crate')
    for workflow, count in (('ci.yml', 2), ('python-runtime-wheel.yml', 1)):
        text = (root / '.github/workflows' / workflow).read_text()
        owners = re.findall(r'repository: tao3k/meta-relational-reasoning\s+ref: ([^\s]+)\s+path: \.ci/mrr-runtime', text)
        if owners != [revision] * count:
            raise ValueError(f'{workflow}: runtime checkout differs from declared owner')
    return revision


def main() -> int:
    revision = check()
    print(f'MRR-RUNTIME-OWNER-OK revision={revision}', flush=True)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
