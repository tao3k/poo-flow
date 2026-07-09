"""Warm-cache ownership for Scheme runtime projection rows."""

from __future__ import annotations

import os
import threading
from pathlib import Path
from typing import Any

from ._scheme_datum import SchemeRows

_SCHEME_LOAD_CACHE_RUNNER_VERSION = 1
_SCHEME_LOAD_CACHE_LOCK = threading.RLock()
_SCHEME_LOAD_CACHE: dict[tuple[Any, ...], SchemeRows] = {}
_SCHEME_LOAD_DEPENDENCIES = (
    Path("src/module-system/init-syntax.ss"),
    Path("src/module-system/runtime-load-projection.ss"),
    Path("src/module-system/profile-composition.ss"),
    Path("src/module-system/profile-composition-accessors.ss"),
    Path("src/module-system/profile-composition-builders.ss"),
    Path("src/module-system/profile-composition-clause-syntax.ss"),
    Path("src/module-system/profile-composition-core.ss"),
    Path("src/module-system/profile-composition-inline-runtime.ss"),
    Path("src/module-system/profile-composition-main-syntax.ss"),
    Path("src/module-system/profile-composition-profile-syntax.ss"),
    Path("src/module-system/profile-composition-use-syntax.ss"),
    Path("src/modules/funflow/config.ss"),
    Path("src/modules/funflow/config-prototypes.ss"),
)


def scheme_load_cache_enabled() -> bool:
    value = os.environ.get("POO_FLOW_SCHEME_LOAD_CACHE", "1").strip().lower()
    return value not in {"0", "false", "no", "off"}


def scheme_load_cache_key(
    module_path: Path,
    workdir: Path,
    projection_path: Path,
) -> tuple[Any, ...]:
    project_root = _project_root_from_projection(projection_path)
    return (
        _SCHEME_LOAD_CACHE_RUNNER_VERSION,
        str(workdir),
        _file_fingerprint(module_path),
        _file_fingerprint(projection_path),
        tuple(
            _file_fingerprint(project_root / dependency)
            for dependency in _SCHEME_LOAD_DEPENDENCIES
        ),
    )


def get_cached_projection_rows(cache_key: tuple[Any, ...]) -> SchemeRows | None:
    with _SCHEME_LOAD_CACHE_LOCK:
        return _SCHEME_LOAD_CACHE.get(cache_key)


def store_cached_projection_rows(
    cache_key: tuple[Any, ...],
    rows: SchemeRows,
) -> None:
    with _SCHEME_LOAD_CACHE_LOCK:
        _SCHEME_LOAD_CACHE[cache_key] = rows


def clear_load_cache() -> None:
    """Clear cached Scheme projection rows for long-lived runtime processes."""

    with _SCHEME_LOAD_CACHE_LOCK:
        _SCHEME_LOAD_CACHE.clear()


def _project_root_from_projection(projection_path: Path) -> Path:
    return projection_path.parents[2]


def _file_fingerprint(path: Path) -> tuple[str, int, int]:
    try:
        stat = path.stat()
    except FileNotFoundError:
        return (str(path), -1, -1)
    return (str(path), stat.st_mtime_ns, stat.st_size)


__all__ = [
    "clear_load_cache",
    "get_cached_projection_rows",
    "scheme_load_cache_enabled",
    "scheme_load_cache_key",
    "store_cached_projection_rows",
]
