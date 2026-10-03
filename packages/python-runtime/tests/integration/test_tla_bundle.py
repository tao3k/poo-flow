# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Dedicated integration gate; host supplies its pinned Java/TLC installation."""
from dataclasses import replace
import os
import hashlib
from pathlib import Path
import sys
import pytest
pytestmark = pytest.mark.skipif(
    not all(os.environ.get(key) for key in ("POO_FLOW_TLC_JAVA", "POO_FLOW_TLC_JAR", "POO_FLOW_TLC_RUNTIME_ARTIFACTS")),
    reason="dedicated TLC gate requires an explicitly configured Java toolchain")

from poo_flow_runtime.tla_bundle import TlcToolchain, check_frozen_bundle, file_digest


@pytest.fixture(scope="module")
def toolchain():
    java = Path(os.environ["POO_FLOW_TLC_JAVA"])
    jar = Path(os.environ["POO_FLOW_TLC_JAR"])
    runtime = [Path(value) for value in os.environ["POO_FLOW_TLC_RUNTIME_ARTIFACTS"].split(os.pathsep)]
    paths = sorted({java.resolve(), jar.resolve(), *(path.resolve() for path in runtime),
                    *(path.resolve() for path in java.resolve().parent.parent.rglob("*") if path.is_file())})
    return TlcToolchain(java, jar, tuple((path, file_digest(path)) for path in paths))


@pytest.fixture
def sources():
    repo = Path(__file__).resolve().parents[4]
    base = repo / "packages/proofs/tla/temporal-causality"
    return {name: (base / name).read_bytes() for name in (
        "TemporalFamilyCase.tla", "TemporalFamilyExplorer.tla", "TemporalHypothesisFamily.tla", "TemporalFamilySemantics.tla", "TemporalOrder.tla", "TemporalFamilyCase.cfg")}


def emit(data):
    sys.stdout.buffer.write(data)
    sys.stdout.buffer.flush()


def test_private_complete_bundle_binds_all_sources_and_toolchain(sources, toolchain, monkeypatch, tmp_path):
    # Ambient Java/TLA settings must not inject options or fill omitted imports.
    monkeypatch.setenv("JAVA_TOOL_OPTIONS", "-this-option-would-prevent-java-starting")
    monkeypatch.setenv("TLA_LIBRARY", str(tmp_path))
    receipt = check_frozen_bundle(sources, root="TemporalFamilyCase", toolchain=toolchain, output=emit)
    assert receipt.checked and receipt.exit_code == 0
    assert dict(receipt.source_digests) == {name: "sha256:" + hashlib.sha256(data).hexdigest()
                                          for name, data in sources.items()}
    assert receipt.toolchain_digest == toolchain.verify()
    assert not receipt.semantic_refinement and not receipt.action_authorized


def test_missing_import_cannot_use_ambient_library(sources, toolchain, monkeypatch, tmp_path):
    (tmp_path / "TemporalFamilyExplorer.tla").write_bytes(sources.pop("TemporalFamilyExplorer.tla"))
    monkeypatch.setenv("TLA_LIBRARY", str(tmp_path))
    receipt = check_frozen_bundle(sources, root="TemporalFamilyCase", toolchain=toolchain, output=emit)
    assert not receipt.checked and receipt.exit_code != 0


def test_owner_toolchain_pin_and_flat_snapshot_boundaries(sources, toolchain):
    paths = list(toolchain.artifacts)
    paths[0] = (paths[0][0], "sha256:" + "0" * 64)
    with pytest.raises(ValueError, match="owner pin"):
        check_frozen_bundle(sources, root="TemporalFamilyCase", toolchain=replace(toolchain, artifacts=tuple(paths)))
    with pytest.raises(ValueError, match="flat"):
        check_frozen_bundle({**sources, "../Injected.tla": b"invalid"}, root="TemporalFamilyCase", toolchain=toolchain)


def test_complete_native_step_table_and_missing_edge_control(toolchain):
    repo = Path(__file__).resolve().parents[4]
    fixture = repo / 'packages/python-runtime/tests/fixtures/temporal-step-bundle'
    bundle = {path.name: path.read_bytes() for path in fixture.iterdir()}
    bundle['TemporalBehaviorSemantics.tla'] = (repo / 'packages/proofs/tla/temporal-causality/TemporalBehaviorSemantics.tla').read_bytes()
    receipt = check_frozen_bundle(bundle, root='TemporalBehaviorCompositionCheck', toolchain=toolchain, output=emit)
    assert receipt.checked
    # Delete one complete tuple from the generated native table. Other rows,
    # classifications and native witness traces stay byte-for-byte identical.
    name = 'TemporalBehaviorCompositionCheck.tla'
    source = bundle[name].decode()
    start = source.index('NativeSteps == {') + len('NativeSteps == {')
    depth, quoted, end, i = 0, False, None, start
    while i < len(source):
        if source[i] == '"': quoted = not quoted
        if not quoted and source[i:i+2] == '<<':
            depth += 1; i += 2; continue
        if not quoted and source[i:i+2] == '>>':
            depth -= 1; i += 2
            if depth == 0:
                end = i; break
            continue
        i += 1
    assert end and source[end] == ','
    bundle[name] = (source[:start] + source[end+1:]).encode()
    failed = check_frozen_bundle(bundle, root='TemporalBehaviorCompositionCheck', toolchain=toolchain, output=emit)
    assert not failed.checked and b'Invariant StepAgreement is violated' in failed.output
