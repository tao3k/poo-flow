from __future__ import annotations

import os
from pathlib import Path

from poo_flow_runtime._scheme_load_runner import (
    _direct_scheme_loader_env,
    _scheme_loader_commands,
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
    runner = tmp_path / "runner.ss"

    commands = _scheme_loader_commands(tmp_path / "source-workspace", runner)

    assert commands[0].argv == ("gxi", str(runner))
    assert commands[0].env is not None
    assert commands[0].env["GERBIL_PATH"] == str(gerbil_path)
    assert commands[1].argv == ("gxpkg", "env", "gxi", str(runner))
    assert commands[1].env is None
