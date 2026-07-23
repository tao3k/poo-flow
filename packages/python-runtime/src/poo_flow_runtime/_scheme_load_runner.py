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
        "(import :poo-flow/src/module-system/init-syntax\n"
        "        :poo-flow/src/module-system/profile-composition)\n"
        f"(include {projection_source_path})\n"
        "(poo-flow-runtime-load-write!\n"
        f" (begin (include {source_path})))\n"
    )


def aot_runner_source(module_path: Path, projection_path: Path) -> str:
    source_path = scheme_string(str(module_path))
    projection_source_path = scheme_string(str(projection_path))
    return (
        "(import :poo-flow/src/module-system/init-syntax\n"
        "        :poo-flow/src/module-system/profile-composition)\n"
        f"(include {projection_source_path})\n"
        "(export main)\n"
        "(def (main . args)\n"
        "  (poo-flow-runtime-load-write!\n"
        f"   (begin (include {source_path}))))\n"
    )


def runtime_projection_source(workdir: Path) -> Path:
    candidate = find_runtime_projection_source(workdir)
    if candidate is not None:
        return candidate
    relative_path = Path("src/module-system/runtime-load-projection.ss")
    raise FileNotFoundError(f"cannot find Scheme runtime load projection: {relative_path}")


def find_runtime_projection_source(workdir: Path) -> Path | None:
    relative_path = Path("src/module-system/runtime-load-projection.ss")
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
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
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
    fallback = _SchemeLoaderCommand(
        ("gxpkg", "env", "gxi", str(runner_path)),
        None,
    )
    if direct_env is None:
        return (fallback,)
    direct = _SchemeLoaderCommand(("gxi", str(runner_path)), direct_env)
    return (direct, fallback)


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
