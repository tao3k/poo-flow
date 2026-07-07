from __future__ import annotations

from pathlib import Path
import time

import poo_flow_runtime._bindings_build as bindings_build
from poo_flow_runtime.bindings import (
    compile_probe,
)


def _probe_workspace(tmp_path: Path) -> Path:
    workspace_root = tmp_path / "workspace"
    include_dir = workspace_root / "bindings" / "runtime-c" / "include"
    probe_dir = workspace_root / "bindings" / "runtime-c" / "probe"
    include_dir.mkdir(parents=True)
    probe_dir.mkdir(parents=True)
    (include_dir / "poo_flow_runtime_abi.h").write_text(
        "int poo_flow_runtime_probe(void);",
        encoding="utf-8",
    )
    (probe_dir / "poo_flow_runtime_abi_probe.c").write_text(
        "int poo_flow_runtime_probe(void) { return 0; }",
        encoding="utf-8",
    )
    return workspace_root


def _fake_probe_compiler(run_calls):
    def fake_run(argv, check):
        run_calls.append((tuple(argv), check))
        output = Path(argv[-1])
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_bytes(f"probe-build-{len(run_calls)}".encode("utf-8"))

    return fake_run


def test_compile_probe_reuses_fresh_shared_library(tmp_path, monkeypatch) -> None:
    package_root = tmp_path / "package"
    workspace_root = _probe_workspace(tmp_path)
    monkeypatch.setenv("POO_FLOW_RUNTIME_C_ABI_BUILD_DIR", str(tmp_path / "build"))
    run_calls = []
    monkeypatch.setattr(
        bindings_build.subprocess,
        "run",
        _fake_probe_compiler(run_calls),
    )

    output = compile_probe(package_root, workspace_root, force_rebuild=True)
    first_mtime = output.stat().st_mtime_ns

    reused = compile_probe(package_root, workspace_root)
    second_mtime = reused.stat().st_mtime_ns

    assert reused == output
    assert second_mtime == first_mtime
    assert len(run_calls) == 1


def test_compile_probe_force_rebuild_keeps_output_current(tmp_path, monkeypatch) -> None:
    package_root = tmp_path / "package"
    workspace_root = _probe_workspace(tmp_path)
    monkeypatch.setenv("POO_FLOW_RUNTIME_C_ABI_BUILD_DIR", str(tmp_path / "build"))
    run_calls = []
    monkeypatch.setattr(
        bindings_build.subprocess,
        "run",
        _fake_probe_compiler(run_calls),
    )

    output = compile_probe(package_root, workspace_root, force_rebuild=True)
    first_mtime = output.stat().st_mtime_ns
    time.sleep(0.01)

    rebuilt = compile_probe(package_root, workspace_root, force_rebuild=True)
    second_mtime = rebuilt.stat().st_mtime_ns

    assert rebuilt == output
    assert second_mtime >= first_mtime
    assert len(run_calls) == 2
