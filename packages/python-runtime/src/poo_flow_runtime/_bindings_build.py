"""Build and locate the runtime C ABI probe library."""

from __future__ import annotations

import os
import pathlib
import platform
import subprocess
import threading
import uuid

_COMPILE_PROBE_LOCK = threading.Lock()
_COMPILE_PROBE_PATH_CACHE: dict[tuple[str, str, str | None], pathlib.Path] = {}


def default_workspace_root() -> pathlib.Path:
    return pathlib.Path(__file__).resolve().parents[4]


def default_package_root() -> pathlib.Path:
    return pathlib.Path(__file__).resolve().parents[2]


def shared_library_name() -> str:
    if platform.system() == "Darwin":
        return "libpoo_flow_runtime_abi_probe.dylib"
    if platform.system() == "Windows":
        return "poo_flow_runtime_abi_probe.dll"
    return "libpoo_flow_runtime_abi_probe.so"


def compile_probe(
    package_root: pathlib.Path,
    workspace_root: pathlib.Path,
    *,
    force_rebuild: bool = False,
) -> pathlib.Path:
    cache_key = (
        str(package_root.resolve()),
        str(workspace_root.resolve()),
        os.environ.get("POO_FLOW_RUNTIME_C_ABI_BUILD_DIR"),
    )
    if not force_rebuild:
        cached = _COMPILE_PROBE_PATH_CACHE.get(cache_key)
        if cached is not None and cached.exists():
            return cached

    include_dir = workspace_root / "bindings" / "runtime-c" / "include"
    header = include_dir / "poo_flow_runtime_abi.h"
    source = workspace_root / "bindings" / "runtime-c" / "probe" / "poo_flow_runtime_abi_probe.c"
    if not header.exists() or not source.exists():
        raise RuntimeError(f"runtime C bindings are missing under {workspace_root}")

    output = _probe_output_path(workspace_root)
    if platform.system() == "Windows":
        raise RuntimeError("Windows probe build is not implemented yet")
    with _COMPILE_PROBE_LOCK:
        if not force_rebuild and _probe_output_is_fresh(output, (header, source)):
            _COMPILE_PROBE_PATH_CACHE[cache_key] = output
            return output
        output.parent.mkdir(parents=True, exist_ok=True)
        tmp_output = output.with_name(f".{output.name}.{uuid.uuid4().hex}.tmp")
        try:
            subprocess.run(
                [
                    os.environ.get("CC", "cc"),
                    "-std=c99",
                    "-Wall",
                    "-Wextra",
                    "-Werror",
                    "-fPIC",
                    "-shared",
                    "-I",
                    str(include_dir),
                    str(source),
                    "-o",
                    str(tmp_output),
                ],
                check=True,
            )
            tmp_output.replace(output)
        finally:
            tmp_output.unlink(missing_ok=True)
    _COMPILE_PROBE_PATH_CACHE[cache_key] = output
    return output


def _probe_output_path(workspace_root: pathlib.Path) -> pathlib.Path:
    override = os.environ.get("POO_FLOW_RUNTIME_C_ABI_BUILD_DIR")
    if override:
        build_root = pathlib.Path(override).expanduser()
    else:
        cache_root = pathlib.Path(
            os.environ.get("XDG_CACHE_HOME", pathlib.Path.home() / ".cache")
        )
        workspace_key = str(workspace_root.resolve()).replace(os.sep, "_").strip("_")
        build_root = cache_root / "poo-flow-runtime" / workspace_key / "runtime-c-abi"
    return build_root / shared_library_name()


def _probe_output_is_fresh(output: pathlib.Path, inputs: tuple[pathlib.Path, ...]) -> bool:
    if not output.exists():
        return False
    output_mtime = output.stat().st_mtime
    return all(path.stat().st_mtime <= output_mtime for path in inputs)
