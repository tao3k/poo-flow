# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
#
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

"""Subprocess runner ownership for Scheme runtime projection loading."""

from __future__ import annotations

import os
import subprocess
import tempfile
from pathlib import Path
from typing import NamedTuple

from ._scheme_datum import SchemeRows, parse_scheme_datum


def run_scheme_projection(
    module_path: Path,
    workdir: Path,
    projection_path: Path,
) -> SchemeRows:
    with tempfile.NamedTemporaryFile(
        "w", encoding="utf-8", suffix=".ss", delete=False
    ) as runner:
        runner.write(runner_source(module_path, projection_path))
        runner_path = Path(runner.name)
    try:
        result = _run_scheme_loader(module_path, workdir, runner_path)
    finally:
        runner_path.unlink(missing_ok=True)
    return parse_scheme_datum(result.stdout)


def runner_source(module_path: Path, projection_path: Path) -> str:
    source_path = scheme_string(str(module_path))
    projection_source_path = scheme_string(str(projection_path))
    return (
        "(import :core/profile-composition/selection-syntax\n"
        "        :poo-flow/src/scenario/composition-syntax\n"
        "        :core/profile-composition/profile-bundle\n"
        "        :poo-flow/src/scenario/profile-root\n"
        "        :poo-flow/modules/funflow/profile-library)\n"
        f"(include {projection_source_path})\n"
        "(poo-flow-runtime-load-write!\n"
        f" (let () (include {source_path})))\n"
    )


def aot_runner_source(module_path: Path, projection_path: Path) -> str:
    source_path = scheme_string(str(module_path))
    projection_source_path = scheme_string(str(projection_path))
    return (
        "(import :core/profile-composition/selection-syntax\n"
        "        :poo-flow/src/scenario/composition-syntax\n"
        "        :core/profile-composition/profile-bundle\n"
        "        :poo-flow/src/scenario/profile-root\n"
        "        :poo-flow/modules/funflow/profile-library)\n"
        f"(include {projection_source_path})\n"
        "(export main)\n"
        "(def (main . args)\n"
        "  (poo-flow-runtime-load-write!\n"
        f"   (let () (include {source_path}))))\n"
    )


def runtime_projection_source(workdir: Path) -> Path:
    candidate = find_runtime_projection_source(workdir)
    if candidate is not None:
        return candidate
    relative_path = Path("modules/funflow/runtime-load-projection.ss")
    raise FileNotFoundError(f"cannot find Scheme runtime load projection: {relative_path}")


def find_runtime_projection_source(workdir: Path) -> Path | None:
    relative_path = Path("modules/funflow/runtime-load-projection.ss")
    candidates = (
        workdir / relative_path,
        Path(__file__).resolve().parents[4] / relative_path,
    )
    for candidate in candidates:
        if candidate.exists():
            return candidate
    return None


def scheme_string(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


class _SchemeLoaderCommand(NamedTuple):
    argv: tuple[str, ...]
    env: dict[str, str] | None


def _run_scheme_loader(
    module_path: Path,
    workdir: Path,
    runner_path: Path,
) -> subprocess.CompletedProcess[str]:
    failures: list[str] = []
    for command in _scheme_loader_commands(workdir, runner_path):
        try:
            return subprocess.run(
                command.argv,
                cwd=workdir,
                env=command.env,
                check=True,
                timeout=90,
                text=True,
                stdout=subprocess.PIPE,
                stderr=None if _scheme_loader_progress_enabled() else subprocess.PIPE,
            )
        except subprocess.CalledProcessError as exc:
            detail = (exc.stderr or exc.stdout or "").strip()
            failures.append(f"{' '.join(command.argv[:3])}: {detail}")
    raise RuntimeError(
        f"Scheme load failed for {module_path}: {'; '.join(failures)}"
    )


def _scheme_loader_commands(
    workdir: Path,
    runner_path: Path,
) -> tuple[_SchemeLoaderCommand, ...]:
    direct_env = _direct_scheme_loader_env(workdir)
    arguments = (str(runner_path),)
    if _scheme_loader_progress_enabled():
        preload_path = Path(__file__).with_name('projections') / 'runtime-preload.ss'
        modules = ('core/profile-composition/selection-syntax',
                   'poo-flow/src/scenario/composition-syntax',
                   'core/profile-composition/profile-bundle',
                   'poo-flow/src/scenario/profile-root',
                   'poo-flow/modules/funflow/profile-library',
                   'poo-flow/modules/funflow/runtime-load-projection',
                   'poo-flow/scripts/temporal/exit-child-process')
        preload = '(load ' + scheme_string(str(preload_path)) + ') (parameterize ((current-output-port (current-error-port))) ' + ' '.join(
            '(runtime-preload-module! ' + scheme_string(module) + ')' for module in modules) + ')'
        evaluate = '(begin (import :poo-flow/scripts/temporal/exit-child-process) (load ' + scheme_string(str(runner_path)) + ') (temporal-child-process-exit! 0))'
        arguments = ('-e', preload, '-e', evaluate)
    fallback = _SchemeLoaderCommand(
        ("gxpkg", "env", "gxi", *arguments),
        None,
    )
    if direct_env is None:
        return (fallback,)
    direct = _SchemeLoaderCommand(("gxi", *arguments), direct_env)
    return (direct, fallback)


def _scheme_loader_progress_enabled() -> bool:
    return os.environ.get('POO_FLOW_SCHEME_LOAD_PROGRESS', '') == '1'


def _direct_scheme_loader_env(workdir: Path) -> dict[str, str] | None:
    inherited_gerbil_path = os.environ.get("GERBIL_PATH")
    inherited_candidate = (
        Path(inherited_gerbil_path) if inherited_gerbil_path else None
    )
    workspace_candidate = workdir / ".gerbil"
    gerbil_path = next(
        (
            candidate
            for candidate in (inherited_candidate, workspace_candidate)
            if candidate is not None
            and (candidate / "lib" / "poo-flow").exists()
        ),
        None,
    )
    if gerbil_path is None:
        return None
    env = dict(os.environ)
    env["GERBIL_PATH"] = str(gerbil_path)
    if gerbil_path == workspace_candidate:
        env["PATH"] = os.pathsep.join(
            (str(gerbil_path / "bin"), env.get("PATH", ""))
        )
    return env


__all__ = [
    "aot_runner_source",
    "find_runtime_projection_source",
    "run_scheme_projection",
    "runtime_projection_source",
    "runner_source",
    "scheme_string",
]
