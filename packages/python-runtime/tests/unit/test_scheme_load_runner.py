# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
#
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

from __future__ import annotations

import os
import subprocess
from pathlib import Path
import pytest

from poo_flow_runtime._scheme_load_runner import (
    _direct_scheme_loader_env,
    _scheme_loader_commands,
    _run_scheme_loader,
)


def test_direct_loader_consumes_declared_bazel_environment(
    tmp_path: Path,
    monkeypatch,
) -> None:
    gerbil_path = tmp_path / "compiled-project" / ".gerbil"
    (gerbil_path / "lib" / "poo-flow").mkdir(parents=True)
    loadpath = os.pathsep.join(
        (
            str(gerbil_path / "lib"),
            str(tmp_path / "dependency" / ".gerbil" / "lib"),
            str(tmp_path / "toolchain-libraries"),
        )
    )
    inherited_path = os.environ.get("PATH", "")
    monkeypatch.setenv("GERBIL_PATH", str(gerbil_path))
    monkeypatch.setenv("GERBIL_LOADPATH", loadpath)
    monkeypatch.setenv("PATH", inherited_path)

    environment = _direct_scheme_loader_env(tmp_path / "source-workspace")

    assert environment is not None
    assert environment["GERBIL_PATH"] == str(gerbil_path)
    assert environment["GERBIL_LOADPATH"] == loadpath
    assert environment["PATH"] == inherited_path


def test_declared_bazel_environment_selects_direct_gxi_first(
    tmp_path: Path,
    monkeypatch,
) -> None:
    gerbil_path = tmp_path / "compiled-project" / ".gerbil"
    (gerbil_path / "lib" / "poo-flow").mkdir(parents=True)
    monkeypatch.setenv("GERBIL_PATH", str(gerbil_path))
    monkeypatch.setenv("GERBIL_LOADPATH", str(gerbil_path / "lib"))
    monkeypatch.delenv("POO_FLOW_SCHEME_LOAD_PROGRESS", raising=False)
    runner = tmp_path / "runner.ss"

    commands = _scheme_loader_commands(tmp_path / "source-workspace", runner)

    assert commands[0].argv == ("gxi", str(runner))
    assert commands[0].env is not None
    assert commands[0].env["GERBIL_PATH"] == str(gerbil_path)
    assert commands[1].argv == ("gxpkg", "env", "gxi", str(runner))
    assert commands[1].env is None


def test_progress_keeps_projection_stdout_separate_and_bounds_execution(tmp_path, monkeypatch):
    monkeypatch.setenv('POO_FLOW_SCHEME_LOAD_PROGRESS', '1')
    calls = []
    def execute(argv, **options):
        calls.append((argv, options))
        return subprocess.CompletedProcess(argv, 0, stdout='((schema "projection"))', stderr=None)
    monkeypatch.setattr(subprocess, 'run', execute)
    result = _run_scheme_loader(tmp_path / 'module.ss', tmp_path, tmp_path / 'runner.ss')
    argv, options = calls[0]
    assert '-e' in argv and 'runtime-preload-module!' in argv[argv.index('-e') + 1]
    assert '(current-error-port)' in argv[argv.index('-e') + 1]
    assert options['stdout'] == subprocess.PIPE and options['stderr'] is None
    assert options['timeout'] == 90
    assert result.stdout == '((schema "projection"))'


def test_expired_loader_does_not_retry_package_fallback(tmp_path, monkeypatch):
    calls = []
    def execute(argv, **options):
        calls.append(argv)
        raise subprocess.TimeoutExpired(argv, options['timeout'])
    monkeypatch.setattr(subprocess, 'run', execute)
    with pytest.raises(subprocess.TimeoutExpired):
        _run_scheme_loader(tmp_path / 'module.ss', tmp_path, tmp_path / 'runner.ss')
    assert len(calls) == 1
