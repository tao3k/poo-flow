# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Check the exact Quint source identity retained by the separate Lean contract.

This checks metadata freshness, not semantic refinement or governance authority.
"""
import hashlib
from pathlib import Path
import re


def check_binding(source: Path, lean: Path) -> str:
    digest = 'sha256:' + hashlib.sha256(source.read_bytes()).hexdigest()
    text = lean.read_text()
    bound = re.search(r'def quintSourceDigest : String :=\s*"([^"]+)"', text)
    if bound is None or bound[1] != digest:
        raise AssertionError('Lean contract retains a stale Quint source digest')
    predicates = re.search(r'def quintInvariantNames : List String :=\s*\[(.*?)\]', text, re.S)
    if predicates is None:
        raise AssertionError('Lean contract omitted its Quint invariant inventory')
    names = re.findall(r'"([^"]+)"', predicates[1])
    qnt = source.read_text()
    if not names or any(not re.search(r'\bval ' + re.escape(n) + r'\s*=', qnt) for n in names):
        raise AssertionError('Lean contract names an absent Quint invariant')
    return digest


if __name__ == '__main__':
    root = Path(__file__).resolve().parents[3]
    digest = check_binding(
        root / 'packages/proofs/quint/HealthcareStandardMigration.qnt',
        root / 'packages/proofs/lean/PooFlowProof/Vertical/Healthcare/StandardMigrationRefinement.lean')
    print('QUINT-LEAN-SOURCE-BINDING-OK ' + digest, flush=True)

    delta_digest = check_binding(
        root / 'packages/proofs/quint/ContextDelta.qnt',
        root / 'packages/proofs/lean-poo/ContextDelta.lean')
    print('CONTEXT-DELTA-SOURCE-BINDING-OK ' + delta_digest, flush=True)
