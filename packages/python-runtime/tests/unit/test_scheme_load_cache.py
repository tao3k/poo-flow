from __future__ import annotations

import subprocess
from collections.abc import Sequence
from pathlib import Path
from typing import Any

from poo_flow_runtime import _scheme_load as scheme_load
from poo_flow_runtime import _scheme_load_aot as scheme_aot
from poo_flow_runtime import _scheme_load_cache as scheme_cache
from poo_flow_runtime import _scheme_load_runner as scheme_runner


def _runtime_projection_fixture(root: Path) -> None:
    projection = root / "src" / "module-system" / "runtime-load-projection.ss"
    projection.parent.mkdir(parents=True)
    projection.write_text(";; projection fixture\n", encoding="utf-8")


def _source_fixture(root: Path) -> Path:
    source = root / "flow.ss"
    source.write_text("(use-composition cached-flow)\n", encoding="utf-8")
    return source


def _fake_scheme_run(calls: list[tuple[str, ...]]):
    def fake_run(args: Sequence[str], **_kwargs: Any) -> subprocess.CompletedProcess[str]:
        calls.append(tuple(args))
        return subprocess.CompletedProcess(
            args,
            0,
            stdout='((schema "poo-flow.funflow-plan-projection.v1"))\n',
            stderr="",
        )

    return fake_run


def _cache_key(root: Path, source: Path) -> tuple[object, ...]:
    projection = root / "src" / "module-system" / "runtime-load-projection.ss"
    return scheme_cache.scheme_load_cache_key(
        source.resolve(),
        root.resolve(),
        projection.resolve(),
    )


def test_scheme_projection_rows_reuse_warm_cache(tmp_path, monkeypatch) -> None:
    scheme_load.clear_load_cache()
    _runtime_projection_fixture(tmp_path)
    source = _source_fixture(tmp_path)
    calls: list[tuple[str, ...]] = []
    monkeypatch.setattr(scheme_runner.subprocess, "run", _fake_scheme_run(calls))

    first = scheme_load.load_projection_rows(source, cwd=tmp_path)
    second = scheme_load.load_projection_rows(source, cwd=tmp_path)

    assert first is second
    assert len(calls) == 1


def test_scheme_projection_cache_invalidates_when_source_changes(
    tmp_path, monkeypatch
) -> None:
    scheme_load.clear_load_cache()
    _runtime_projection_fixture(tmp_path)
    source = _source_fixture(tmp_path)
    calls: list[tuple[str, ...]] = []
    monkeypatch.setattr(scheme_runner.subprocess, "run", _fake_scheme_run(calls))

    scheme_load.load_projection_rows(source, cwd=tmp_path)
    source.write_text("(use-composition changed-flow)\n;; changed\n", encoding="utf-8")
    scheme_load.load_projection_rows(source, cwd=tmp_path)

    assert len(calls) == 2


def test_scheme_projection_cache_can_be_disabled(tmp_path, monkeypatch) -> None:
    scheme_load.clear_load_cache()
    _runtime_projection_fixture(tmp_path)
    source = _source_fixture(tmp_path)
    calls: list[tuple[str, ...]] = []
    monkeypatch.setattr(scheme_runner.subprocess, "run", _fake_scheme_run(calls))
    monkeypatch.setenv("POO_FLOW_SCHEME_LOAD_CACHE", "0")

    scheme_load.load_projection_rows(source, cwd=tmp_path)
    scheme_load.load_projection_rows(source, cwd=tmp_path)

    assert len(calls) == 2


def test_scheme_projection_prefers_direct_gerbil_runner(tmp_path, monkeypatch) -> None:
    scheme_load.clear_load_cache()
    _runtime_projection_fixture(tmp_path)
    (tmp_path / ".gerbil" / "lib" / "poo-flow").mkdir(parents=True)
    source = _source_fixture(tmp_path)
    calls: list[tuple[str, ...]] = []
    monkeypatch.setattr(scheme_runner.subprocess, "run", _fake_scheme_run(calls))

    scheme_load.load_projection_rows(source, cwd=tmp_path, cache=False)

    assert calls[0][0] == "gxi"


def test_scheme_projection_uses_existing_aot_runner(tmp_path, monkeypatch) -> None:
    scheme_load.clear_load_cache()
    _runtime_projection_fixture(tmp_path)
    source = _source_fixture(tmp_path)
    artifact = scheme_aot.scheme_aot_artifact(tmp_path, _cache_key(tmp_path, source))
    artifact.binary.parent.mkdir(parents=True)
    artifact.binary.write_text("#!/bin/sh\n", encoding="utf-8")
    aot_calls: list[tuple[str, ...]] = []

    def fake_aot_run(
        args: Sequence[str],
        **_kwargs: Any,
    ) -> subprocess.CompletedProcess[str]:
        aot_calls.append(tuple(args))
        return subprocess.CompletedProcess(
            args,
            0,
            stdout='((schema "poo-flow.funflow-plan-projection.v1"))\n',
            stderr="",
        )

    monkeypatch.setattr(scheme_aot.subprocess, "run", fake_aot_run)

    rows = scheme_load.load_projection_rows(source, cwd=tmp_path)

    assert rows == (("schema", "poo-flow.funflow-plan-projection.v1"),)
    assert aot_calls == [(str(artifact.binary),)]


def test_scheme_projection_precompile_builds_aot_runner(tmp_path, monkeypatch) -> None:
    scheme_load.clear_load_cache()
    _runtime_projection_fixture(tmp_path)
    source = _source_fixture(tmp_path)
    compile_calls: list[tuple[str, ...]] = []

    def fake_compile_run(
        args: Sequence[str],
        **_kwargs: Any,
    ) -> subprocess.CompletedProcess[str]:
        compile_calls.append(tuple(args))
        binary = Path(args[args.index("-o") + 1])
        binary.parent.mkdir(parents=True, exist_ok=True)
        binary.write_text("#!/bin/sh\n", encoding="utf-8")
        return subprocess.CompletedProcess(args, 0, stdout="", stderr="")

    monkeypatch.setattr(scheme_aot.subprocess, "run", fake_compile_run)

    binary = scheme_load.precompile_load(source, cwd=tmp_path)

    assert binary.exists()
    assert compile_calls
    assert "-exe" in compile_calls[0]
